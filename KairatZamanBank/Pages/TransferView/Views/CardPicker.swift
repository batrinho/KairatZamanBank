//
//  CardPickerView.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI

struct CardPicker: View {
    let cards: [CardItem]
    @Binding var selected: CardItem

    var body: some View {
        NavigationStack {
            List(cards, id: \.self) { card in
                HStack(spacing: 12) {
                    Image(card.brandAsset)
                        .resizable().renderingMode(.original)
                        .scaledToFit().frame(height: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("** \(card.last4)").font(.subheadline).fontWeight(.semibold)
                        Text(card.balance).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if card == selected {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.zamanGreen)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { selected = card }
            }
            .listStyle(.plain)
            .navigationTitle("Choose a card")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CardSelector: View {
    @Binding var selected: CardDto
    @State private var showPicker = false

    var body: some View {
        HStack(spacing: 12) {
            Image("mastercard")
                .resizable().renderingMode(.original)
                .scaledToFit().frame(height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("Card ** \(selected.last4)").font(.caption).foregroundStyle(.secondary)
                Text(selected.balance).font(.title3).fontWeight(.semibold)
            }
            Spacer()
            Image(systemName: showPicker ? "chevron.up" : "chevron.down")
                .font(.headline.weight(.semibold))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22).fill(.white))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .onTapGesture { showPicker = true }
        .sheet(isPresented: $showPicker) {
            CardPicker(cards: pickerCards, selected: $selected)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}
