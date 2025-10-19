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

struct CardDto: Identifiable, Hashable {
    let id = UUID()
    let imageURL: URL?
    let last4: String
}
