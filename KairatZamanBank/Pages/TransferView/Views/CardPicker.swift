//
//  CardPickerView.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI

// MARK: - CardPicker (CardDto-based)
struct CardPicker: View {
    let cards: [CardDto]
    @Binding var selected: CardDto?

    var body: some View {
        NavigationStack {
            List(cards, id: \.self) { c in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 32, height: 22)
                        .overlay(Image(systemName: "creditcard").font(.caption))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("** \(c.cardNumber)")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("\(Int(c.balance)) \(c.currency)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if selected?.id == c.id {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.zamanGreen)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { selected = c }
            }
            .listStyle(.plain)
            .navigationTitle("Choose a card")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


// MARK: - CardSelector (CardDto-based)
struct CardSelector: View {
    let cards: [CardDto]
    @Binding var selected: CardDto?
    @State private var showPicker = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 36, height: 26)
                .overlay(Image(systemName: "creditcard").font(.footnote))

            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(balanceText)
                    .font(.title3).fontWeight(.semibold)
            }
            Spacer()
            Image(systemName: showPicker ? "chevron.up" : "chevron.down")
                .font(.headline.weight(.semibold))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22).fill(.white))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .onTapGesture { if !cards.isEmpty { showPicker = true } }
        .sheet(isPresented: $showPicker) {
            CardPicker(cards: cards, selected: Binding(
                get: { selected ?? cards.first },
                set: { selected = $0 }
            ))
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var titleText: String {
        if let s = selected { return "Card ** \(s.cardNumber)" }
        return cards.isEmpty ? "No cards" : "Choose a card"
    }

    private var balanceText: String {
        if let s = selected { return "\(Int(s.balance)) \(s.currency)" }
        return " "
    }
}

