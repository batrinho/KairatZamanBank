//
//  CardView.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI

struct CardView: View {var bankLogoName: String = "zamanbank"
    var brandLogoName: String = "mastercard"
    var last4: String = "5460"

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.83, blue: 0.45),
                            Color(red: 0.92, green: 0.79, blue: 0.40),
                            Color(red: 0.98, green: 0.88, blue: 0.55)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), .clear, Color.black.opacity(0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )

            VStack {
                HStack {
                    Image(bankLogoName)
                        .resizable().renderingMode(.original)
                        .scaledToFit()
                        .frame(height: 28)
                    Spacer()
                }
                Spacer()
                HStack {
                    Text("••\(last4)")
                        .font(.headline).fontWeight(.semibold)
                        .foregroundStyle(Color.white.opacity(0.9))
                    Spacer()
                    Image(brandLogoName)
                        .resizable().renderingMode(.original)
                        .scaledToFit()
                        .frame(height: 28)
                }
            }
            .padding(16)
        }
        .frame(height: 200)
    }
}
