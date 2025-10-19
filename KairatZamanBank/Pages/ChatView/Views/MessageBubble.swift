//
//  MessageBubble.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant { Text("🧕").font(.system(size: 22)) }
            Text(message.text)
                .font(.callout)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(message.role == .user
                              ? Color(red: 0.93, green: 0.98, blue: 0.42)
                              : .white)
                )
                .foregroundStyle(message.role == .user ? .black : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(message.role == .assistant ? 0.05 : 0), lineWidth: 0.5)
                )
            if message.role == .user { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}
