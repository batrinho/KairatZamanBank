//
//  NetworkingService.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 19.10.2025.
//

import SwiftUI

@MainActor
final class NetworkingService: ObservableObject {
    @Published var cards: [CardDto] = []
    @Published var promptText: String = ""
    @Published var isSubmitting: Bool = false
    @Published var showPopup: Bool = false
    @Published var isTransferring = false
    
    let token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI4Nzc3Nzc3Nzc3NyIsImlhdCI6MTc2MDgxNjYzMSwiZXhwIjoxNzYwOTAzMDMxfQ.alVHeshawy2-cJG9eSaFlsNkZY3SpZk0BeZE5Ny2xv8"
    
    
    let base = "https://zamanbank-api-production.up.railway.app"
    func fetchCards() async {
        guard let url = URL(string: "\(base)/cards") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        struct TxnResponse: Decodable {
            let id: Int?
            let amount: Double?
            let message: String?
            let isSender: Bool?        // <- optional to tolerate null
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
                    transactions: (c.transactions ?? []).map { t in
                        TxnDto(
                            id: t.id ?? -1,
                            amount: t.amount ?? 0,
                            message: t.message ?? "",
                            isSender: t.isSender ?? false,   // <- safe default
                            createdAt: Self.parseISODateTime(t.createdAt)
                        )
                    },
                    imageURL: c.designImageUrl.flatMap(URL.init(string:))
                )
            }
        } catch {
            print("Fetch error:", error)
        }
    }
    
    
    // MARK: - Date parsers
    private static func parseDateOnly(_ s: String?) -> Date? {
        guard let s else { return nil }
        // "2025-10-19"
        var fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        return fmt.date(from: s)
    }
    
    private static func parseISODateTime(_ s: String?) -> Date? {
        guard let s else { return nil }
        // e.g. "2025-10-19T02:05:46.113Z" or without fraction
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: s) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: s)
    }
    
    // MARK: Submit
    func submitPrompt() async {
        guard let url = URL(string: "https://zamanbank-api-production.up.railway.app/cards") else { return }
        let text = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        let body = ["designPreferences": text]
        
        do {
            let json = try JSONSerialization.data(withJSONObject: body)
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.httpBody = json
            
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode {
                showPopup = false
                await fetchCards()
            }
        } catch {
            print("Submit error:", error)
        }
    }
}

// transactions
extension NetworkingService {
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
        guard let url = URL(string: "https://zamanbank-api-production.up.railway.app/transactions") else { return false }
        
        isTransferring = true
        defer { isTransferring = false }
        
        let body = TransferRequest(
            senderCardId: senderCardId,
            receiverPhone: receiverPhone?.nilIfBlank(),
            receiverCardNumber: receiverCardNumber?.nilIfBlank(),
            amount: amount,
            message: message
        )
        
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.httpBody = try JSONEncoder().encode(body)
            
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode {
                return true
            }
        } catch {
            print("Transfer error:", error)
        }
        return false
    }
}

// fraud check
extension NetworkingService {
    func fraudCheck(phone: String) async -> Bool? {
        guard var comps = URLComponents(string: "\(base)/fraud-check") else { return nil }
        comps.queryItems = [.init(name: "phone-number", value: phone)]
        guard let url = comps.url else { return nil }
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return nil }
            if let val = try? JSONDecoder().decode(Bool.self, from: data) { return val }
            if let s = String(data: data, encoding: .utf8) { return s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true" }
            return nil
        } catch {
            print("fraudCheck error:", error)
            return nil
        }
    }
}
