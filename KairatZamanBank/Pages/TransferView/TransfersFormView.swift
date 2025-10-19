import SwiftUI

// MARK: - Transfer form
struct TransferFormView: View {
    @EnvironmentObject private var net: NetworkingService
    
    enum Target: String, CaseIterable { case phone = "Phone Number", card = "Card Number" }
    enum Field { case phone, card, amount, note }
    
    @State private var target: Target = .phone
    @Namespace private var segNS
    @State private var phone = ""
    @State private var card = ""
    @State private var amount = "17 000 ₸"
    @State private var note = ""
    @FocusState private var focus: Field?
    
    @State private var selectedCard: CardDto
    
    var pickerCards: [CardDto] {
        net.cards
    }
    
    init() {
        selectedCard = (pickerCards.first ?? CardDto(imageURL: nil, last4: "----"))
    }
    
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
