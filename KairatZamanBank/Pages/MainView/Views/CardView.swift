//
//  CardView.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI
struct CardView: View {
    let dto: CardDto
    
    var body: some View {
        ZStack {
            if let url = dto.imageURL {
                CachedAsyncImage(url: url) {
                    gradient
                }
                .clipped()
            } else {
                gradient
            }
            
            LinearGradient(colors: [Color.white.opacity(0.20), .clear, Color.black.opacity(0.10)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            VStack {
                Spacer()
                HStack {
                    Text("••\(dto.last4)")
                        .font(.headline).fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.95))
                    Spacer()
                }
            }
            .padding(16)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private var gradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.83, blue: 0.45),
                Color(red: 0.92, green: 0.79, blue: 0.40),
                Color(red: 0.98, green: 0.88, blue: 0.55)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}
