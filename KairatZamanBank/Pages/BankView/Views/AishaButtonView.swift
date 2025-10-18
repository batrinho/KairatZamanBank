//
//  AssistantButtonView.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI

struct AishaButtonView: View {
    var title: String = "It’s time for Zakyat!"
    var subtitle: String = "- Aisha Assistant"
    var onTap: () -> Void = {}
    
    var body: some View {
        HStack(spacing: 14) {
            Text("🧕")
                .font(.system(size: 34))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 14))
            }
            .foregroundStyle(.primary)
            .lineLimit(1)
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.7))
        }
        .frame(height: 100)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            ZamanGradientView()
                .cornerRadius(22)
        )
    }
}

