//
//  MainModel.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import Foundation

enum BankTab: String, CaseIterable, Identifiable {
    case bank = "My Bank"
    case transfers = "Transfers"
    case chat = "Chat"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .bank: return "creditcard"
        case .transfers: return "arrow.2.squarepath"
        case .chat: return "bubble.left"
        }
    }
}

struct TxnDto: Identifiable, Hashable {
    let id: Int
    let amount: Double
    let message: String
    let isSender: Bool
    let createdAt: Date?
}

struct CardDto: Identifiable, Hashable {
    let id: Int
    let cardNumber: String
    let cardHolderName: String
    let expirationDate: Date?
    let cvv: String
    let balance: Double
    let currency: String
    let transactions: [TxnDto]
    let imageURL: URL?

    var last4: String { String(cardNumber.suffix(4)) }
}
