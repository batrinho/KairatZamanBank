import SwiftUI

// MARK: - Card model + demo
struct CardItem: Identifiable, Hashable {
    let id = UUID()
    let brandAsset: String
    let last4: String
    let balance: String
}

private let demoCards: [CardItem] = [
    .init(brandAsset: "mastercard", last4: "6917", balance: "27 567,67 ₸"),
    .init(brandAsset: "mastercard", last4: "1123", balance: "83 240,10 ₸"),
    .init(brandAsset: "visa",       last4: "5460", balance: "15 004,00 ₸")
]

// MARK: - Selector button → opens sheet
struct CardSelector: View {
    @Binding var selected: CardItem
    @State private var showPicker = false

    var body: some View {
        HStack(spacing: 12) {
            Image(selected.brandAsset)
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
            CardPicker(cards: demoCards, selected: $selected)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Picker sheet
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

// MARK: - Transfer form
struct TransferFormView: View {
    enum Target: String, CaseIterable { case phone = "Phone Number", card = "Card Number" }
    enum Field { case phone, card, amount, note }

    @State private var target: Target = .phone
    @Namespace private var segNS

    @State private var phone = ""
    @State private var card = ""
    @State private var amount = "17 000 ₸"
    @State private var note = ""
    @FocusState private var focus: Field?

    @State private var selectedCard: CardItem = demoCards.first!   // <- selected state

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Card selector (tap to change)
                CardSelector(selected: $selectedCard)

                SegmentedSelector(selection: $target, namespace: segNS)

                // Target input
                Group {
                    Text(target == .phone ? "Dial a number" : "Enter card number")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        TextField(target == .phone ? "+7 (___) ___-__-__" : "____ ____ ____ ____",
                                  text: target == .phone ? $phone : $card)
                            .keyboardType(target == .phone ? .phonePad : .numberPad)
                            .submitLabel(.done)
                            .focused($focus, equals: target == .phone ? .phone : .card)

                        Image(systemName: target == .phone ? "person.crop.circle" : "creditcard")
                            .font(.headline).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                }

                // Amount
                VStack(alignment: .leading, spacing: 6) {
                    Text("Transfer amount").font(.caption).foregroundStyle(.secondary)
                    TextField("0 ₸", text: $amount)
                        .multilineTextAlignment(.center)
                        .font(.title2).fontWeight(.semibold)
                        .keyboardType(.numberPad)
                        .submitLabel(.done)
                        .focused($focus, equals: .amount)
                        .padding(.horizontal, 16).padding(.vertical, 18)
                        .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                }

                // Note
                TextEditor(text: $note)
                    .scrollContentBackground(.hidden)
                    .focused($focus, equals: .note)
                    .frame(minHeight: 90, maxHeight: 120)
                    .padding(12)
                    .background(
                        ZStack(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("Message to receiver")
                                    .foregroundStyle(.secondary)
                                    .font(.callout)
                                    .padding(.horizontal, 18).padding(.top, 18)
                            }
                            RoundedRectangle(cornerRadius: 18).fill(.white)
                        }
                    )
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 3)

                // Quick notes
                HStack(spacing: 12) {
                    ForEach(["Thank you!🥰","Congrats!👏","Alhamdulillah"], id: \.self) { chip in
                        Text(chip)
                            .font(.footnote).fontWeight(.semibold)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(.white))
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                            .onTapGesture { note = chip }
                    }
                }

                // CTA
                Text("Transfer")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.93, green: 0.98, blue: 0.42)))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                    .foregroundStyle(.black)

                TransfersCardView()
            }
        }
        .scrollIndicators(.hidden)
        .padding(20)
        .toolbar {                               // keyboard “Done”
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
    }
}

// MARK: - Segmented selector (unchanged)
private struct SegmentedSelector: View {
    @Binding var selection: TransferFormView.Target
    var namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TransferFormView.Target.allCases, id: \.self) { tab in
                ZStack {
                    if selection == tab {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(white: 0.92))
                            .matchedGeometryEffect(id: "SEG_BG", in: namespace)
                    }
                    Text(tab.rawValue)
                        .font(.callout).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        selection = tab
                    }
                }
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 20).fill(.white))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}
