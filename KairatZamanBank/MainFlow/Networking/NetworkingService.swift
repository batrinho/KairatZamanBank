// NetworkingService.swift
import Foundation
import SwiftUI

@MainActor
final class NetworkingService: ObservableObject {
    // Cards / UI state
    @Published var cards: [CardDto] = []
    @Published var promptText: String = ""
    @Published var isSubmitting: Bool = false
    @Published var showPopup: Bool = false
    @Published var isTransferring = false
    
    // Auth UI state
    @Published var isAuthBusy = false
    @Published var authError: String? = nil
    
    private let base = "https://zamanbank-api-production.up.railway.app"
    
    // MARK: - Shared helpers
    private func addAuth(_ req: inout URLRequest) {
        if let t = AppSession.token, !t.isEmpty {
            req.addValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private static func parseDateOnly(_ s: String?) -> Date? {
        guard let s else { return nil }
        let f = ISO8601DateFormatter(); f.formatOptions = [.withFullDate]
        return f.date(from: s)
    }
    
    private static func parseISODateTime(_ s: String?) -> Date? {
        guard let s else { return nil }
        let f1 = ISO8601DateFormatter(); f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: s) { return d }
        let f2 = ISO8601DateFormatter(); f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: s)
    }
    
    // MARK: - Auth DTOs
    struct LoginReq: Encodable { let username: String; let password: String }
    struct RegisterReq: Encodable { let username: String; let password: String; let name: String; let surname: String }
    struct TokenResp: Decodable { let token: String }
    
    // MARK: - Auth API
    func login(username: String, password: String) async -> Bool {
        let normalized = normalizeUsername(username)
        return await sendForToken(path: "/auth/login", body: LoginReq(username: normalized, password: password))
    }
    
    func register(username: String, password: String, name: String, surname: String) async -> Bool {
        let normalized = normalizeUsername(username)
        return await sendForToken(path: "/auth/register", body: RegisterReq(username: normalized, password: password, name: name, surname: surname))
    }
    
    func logout() { AppSession.reset() }
    
    private func sendForToken<T: Encodable>(path: String, body: T) async -> Bool {
        guard let url = URL(string: base + path) else { return false }
        isAuthBusy = true
        authError = nil
        defer { isAuthBusy = false }
        
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.addValue("application/json", forHTTPHeaderField: "Accept")
            req.httpBody = try JSONEncoder().encode(body)
            
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                authError = "No response."
                return false
            }
            
#if DEBUG
            print("AUTH \(path) -> \(http.statusCode)")
            if let s = String(data: data, encoding: .utf8) { print("AUTH body:", s) }
#endif
            
            if (200..<300).contains(http.statusCode) {
                if let token = try? JSONDecoder().decode(TokenResp.self, from: data).token, token.isEmpty == false {
                    AppSession.token = token
                    AppSession.isAuthorized = true
                    return true
                } else if
                    let s = String(data: data, encoding: .utf8),
                    let token = s.components(separatedBy: "\"token\"").dropFirst().first?
                        .split(separator: "\"").dropFirst().first,
                    token.isEmpty == false
                {
                    AppSession.token = String(token)
                    AppSession.isAuthorized = true
                    return true
                } else {
                    authError = "Token missing in response."
                    return false
                }
            } else {
                if
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let msg = json["message"] as? String, !msg.isEmpty
                {
                    authError = msg
                } else if let s = String(data: data, encoding: .utf8), !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    authError = s.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    authError = "Invalid credentials. Code \(http.statusCode)."
                }
                return false
            }
        } catch {
            authError = error.localizedDescription
            return false
        }
    }
    
    private func normalizeUsername(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let disallowed = CharacterSet(charactersIn: " ()-")
        return trimmed.components(separatedBy: disallowed).joined()
    }
    
    // MARK: - Chat bot
    private struct ChatAPIResponse: Decodable { let response: String; let message: String? }
    
    func sendChat(text: String) async throws -> String {
        guard var comps = URLComponents(string: "\(base)/chat-bot/chat") else { throw URLError(.badURL) }
        comps.queryItems = [.init(name: "text", value: text)]
        guard let url = comps.url else { throw URLError(.badURL) }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        addAuth(&req)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        let decoded = try JSONDecoder().decode(ChatAPIResponse.self, from: data)
        return decoded.response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns audio bytes and content-type for TTS reply.
    func analyzeSpeech(text: String) async throws -> (Data, String?) {
        guard var comps = URLComponents(string: "\(base)/chat-bot/analyze-speech") else { throw URLError(.badURL) }
        comps.queryItems = [.init(name: "text", value: text)]
        guard let url = comps.url else { throw URLError(.badURL) }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("audio/aac, audio/mp4, audio/m4a, application/octet-stream", forHTTPHeaderField: "Accept")
        addAuth(&req)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        return (data, http.value(forHTTPHeaderField: "Content-Type"))
    }
    
    // MARK: - Cards
    func fetchCards() async {
        guard let url = URL(string: "\(base)/cards") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        addAuth(&req)
        
        struct TxnResponse: Decodable {
            let id: Int?
            let amount: Double?
            let message: String?
            let isSender: Bool?
            let createdAt: String?
        }
        struct CardResponse: Decodable {
            let id: Int?
            let cardNumber: String?
            let cardHolderName: String?
            let expirationDate: String?
            let cvv: String?
            let balance: Double?
            let currency: String?
            let transactions: [TxnResponse]?
            let designImageUrl: String?
        }
        
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return }
            let decoded = try JSONDecoder().decode([CardResponse].self, from: data)
            
            cards = decoded.map { c in
                CardDto(
                    id: c.id ?? -1,
                    cardNumber: c.cardNumber ?? "----",
                    cardHolderName: c.cardHolderName ?? "",
                    expirationDate: Self.parseDateOnly(c.expirationDate),
                    cvv: c.cvv ?? "",
                    balance: c.balance ?? 0,
                    currency: c.currency ?? "KZT",
                    imageURL: c.designImageUrl.flatMap(URL.init(string:))
                )
            }
        } catch { print("Fetch error:", error) }
    }
    
    // MARK: - Card design submit
    func submitPrompt() async {
        guard let url = URL(string: "\(base)/cards") else { return }
        let text = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        isSubmitting = true; defer { isSubmitting = false }
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            addAuth(&req)
            req.httpBody = try JSONSerialization.data(withJSONObject: ["designPreferences": text])
            
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode {
                showPopup = false
                await fetchCards()
            }
        } catch { print("Submit error:", error) }
    }
    
    // MARK: - Transfer
    struct TransferRequest: Encodable {
        let senderCardId: Int
        let receiverPhone: String?
        let receiverCardNumber: String?
        let amount: Double
        let message: String
    }
    
    func submitTransfer(
        senderCardId: Int,
        receiverPhone: String?,
        receiverCardNumber: String?,
        amount: Double,
        message: String
    ) async -> Bool {
        guard let url = URL(string: "\(base)/transactions") else { return false }
        isTransferring = true; defer { isTransferring = false }
        
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            addAuth(&req)
            let body = TransferRequest(
                senderCardId: senderCardId,
                receiverPhone: receiverPhone?.nilIfBlank(),
                receiverCardNumber: receiverCardNumber?.nilIfBlank(),
                amount: amount,
                message: message
            )
            req.httpBody = try JSONEncoder().encode(body)
            
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode { return true }
        } catch { print("Transfer error:", error) }
        return false
    }
    
    // MARK: - Fraud check
    func fraudCheck(phone: String) async -> Bool? {
        guard var comps = URLComponents(string: "\(base)/fraud-check") else { return nil }
        comps.queryItems = [.init(name: "phoneNumber", value: phone)]
        guard let url = comps.url else { return nil }
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        addAuth(&req)
        
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return nil }
            if let val = try? JSONDecoder().decode(Bool.self, from: data) { return val }
            if let s = String(data: data, encoding: .utf8) {
                return s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
            }
            return nil
        } catch { print("fraudCheck error:", error); return nil }
    }
    
    // MARK: - GET /transactions
    func fetchTransactions(cardId: Int) async -> [DayTransactionsDto] {
        guard var comps = URLComponents(string: "\(base)/transactions") else { return [] }
        comps.queryItems = [.init(name: "cardId", value: String(cardId))]
        guard let url = comps.url else { return [] }
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        addAuth(&req)
        
        struct TxnResp: Decodable {
            let id: Int?
            let amount: Double?
            let message: String?
            let isSender: Bool?
            let createdAt: String?
        }
        
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return [] }
            
            let raw = try JSONDecoder().decode([String: [TxnResp]].self, from: data)
            
            let dayFmt = DateFormatter()
            dayFmt.calendar = .init(identifier: .iso8601)
            dayFmt.locale = .init(identifier: "en_US_POSIX")
            dayFmt.timeZone = .init(secondsFromGMT: 0)
            dayFmt.dateFormat = "yyyy-MM-dd"
            
            var days: [DayTransactionsDto] = []
            for (key, txns) in raw {
                guard let d = dayFmt.date(from: key) else { continue }
                let items: [TxnDto] = txns.compactMap { t in
                    TxnDto(
                        id: t.id ?? -1,
                        amount: t.amount ?? 0,
                        message: t.message ?? "",
                        isSender: t.isSender ?? false,
                        createdAt: Self.parseISODateTime(t.createdAt)
                    )
                }
                days.append(.init(date: d, items: items))
            }
            days.sort { $0.date > $1.date }
            return days
        } catch { print("fetchTransactions error:", error); return [] }
    }
    
    // MARK: - PUT /transactions report
    struct ReportReq: Encodable { let reportMessage: String; let transactionId: Int }
    
    func reportTransaction(transactionId: Int, reportMessage: String) async -> Bool {
        guard var comps = URLComponents(string: "\(base)/transactions") else { return false }
        comps.queryItems = [
            .init(name: "reportMessage", value: reportMessage),
            .init(name: "transactionId", value: String(transactionId))
        ]
        guard let url = comps.url else { return false }
        
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            addAuth(&req)
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) { return true }
        } catch { print("reportTransaction error:", error) }
        return false
    }
    
    struct ReminderResp: Decodable {
        let mood: Int
        let advice: String
    }
    
    /// GET /reminders -> { mood: 0|1, advice: String }
    func fetchReminder() async -> (advice: String, mood: Bool)? {
        guard let url = URL(string: "\(base)/reminders") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        addAuth(&req)
        
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return nil }
            let obj = try JSONDecoder().decode(ReminderResp.self, from: data)
            return (obj.advice, obj.mood != 0)
        } catch {
            print("fetchReminder decode error:", error)
            return nil
        }
    }
    
    func updateFinancialGoal(_ financialGoal: String) async -> Bool {
            guard var comps = URLComponents(string: "\(base)/chat-bot/update-goal") else { return false }
            comps.queryItems = [URLQueryItem(name: "financialGoal", value: financialGoal)]
            guard let url = comps.url else { return false }

            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            addAuth(&req)

            do {
                let (_, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return false }
                return true
            } catch {
                print("updateFinancialGoal error:", error)
                return false
            }
        }
}
