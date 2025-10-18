//
//  CurrencyView.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI

struct CurrencyView: View {
    struct Rate: Identifiable {
        let id = UUID()
        let code: String
        let symbol: String
        let buy: String
        let sell: String
    }

    let rates: [Rate] = [
        .init(code: "USD", symbol: "$", buy: "$ 78,92", sell: "$ 78,92"),
        .init(code: "EUR", symbol: "€", buy: "$ 78,92", sell: "$ 78,92"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Currencies")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Buy").font(.caption).foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .trailing)
                Text("Sell").font(.caption).foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .trailing)
            }

            ForEach(rates) { r in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 28, height: 28)
                        .overlay(Text(r.symbol).font(.subheadline).fontWeight(.semibold))

                    Text(r.code)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(r.buy)
                        .font(.subheadline)
                        .frame(width: 80, alignment: .trailing)

                    Text(r.sell)
                        .font(.subheadline)
                        .frame(width: 80, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
    }
}
