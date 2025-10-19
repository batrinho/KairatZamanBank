//
//  ChatModel.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import Foundation

enum ChatRole { case user, assistant }
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: ChatRole
    let text: String
    let time: Date = .init()
}
