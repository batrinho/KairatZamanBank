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

    // MARK: Fetch
    func fetchCards() async {
        guard let url = URL(string: "https://zamanbank-api-production.up.railway.app/cards") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // TODO: do not hardcode tokens in production
        let token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI4Nzc3Nzc3Nzc3NyIsImlhdCI6MTc2MDgxNjYzMSwiZXhwIjoxNzYwOTAzMDMxfQ.alVHeshawy2-cJG9eSaFlsNkZY3SpZk0BeZE5Ny2xv8"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        struct CardResponse: Decodable { let cardNumber: String?; let designImageUrl: String? }

        do {
            let (data, resp) = try await URLSession.shared.data(for: request)
            guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return }
            let decoded = try JSONDecoder().decode([CardResponse].self, from: data)
            cards = decoded.map {
                let last4 = $0.cardNumber.map { String($0.suffix(4)) } ?? "0000"
                let url = $0.designImageUrl.flatMap(URL.init(string:))
                return CardDto(imageURL: url, last4: last4)
            }
        } catch {
            print("Fetch error:", error)
        }
    }

    // MARK: Submit
    func submitPrompt() async {
        guard let url = URL(string: "https://zamanbank-api-production.up.railway.app/cards") else { return }
        let text = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        let token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI4Nzc3Nzc3Nzc3NyIsImlhdCI6MTc2MDgxNjYzMSwiZXhwIjoxNzYwOTAzMDMxfQ.alVHeshawy2-cJG9eSaFlsNkZY3SpZk0BeZE5Ny2xv8"
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
