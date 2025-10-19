import SwiftUI

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

    @State private var selectedCard: CardDto? = nil

    // Alerts and progress
    @State private var showAlert = false
    @State private var alertText = ""

    @State private var isFraudChecking = false
    @State private var showFraudPopup = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    CardSelector(cards: net.cards, selected: $selectedCard)

                    SegmentedSelector(selection: $target, namespace: segNS)

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
                                .onSubmit { if target == .phone { Task { await runFraudCheckIfNeeded() } } }

                            Image(systemName: target == .phone ? "person.crop.circle" : "creditcard")
                                .font(.headline).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Transfer amount").font(.caption).foregroundStyle(.secondary)
                        TextField("0 ₸", text: $amount)
                            .multilineTextAlignment(.center)
                            .font(.title2).fontWeight(.semibold)
                            .keyboardType(.decimalPad)
                            .submitLabel(.done)
                            .focused($focus, equals: .amount)
                            .padding(.horizontal, 16).padding(.vertical, 18)
                            .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                    }

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

                    Button {
                        Task { await submitTransfer() }
                    } label: {
                        HStack {
                            if net.isTransferring { ProgressView().tint(.black) }
                            Text(net.isTransferring ? "Transferring..." : "Transfer")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.93, green: 0.98, blue: 0.42)))
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                        .foregroundStyle(.black)
                    }
                    .disabled(net.isTransferring)

                    TransfersCardView()
                }
            }
            .task { if net.cards.isEmpty { await net.fetchCards() } }
            .onChange(of: net.cards) { new in if selectedCard == nil { selectedCard = new.first } }
            .scrollIndicators(.hidden)
            .padding(20)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        // on dismissing keyboard, if phone target, run fraud-check
                        let leavingPhone = (focus == .phone)
                        focus = nil
                        if leavingPhone, target == .phone { Task { await runFraudCheckIfNeeded() } }
                    }
                }
            }
            .alert("Transfer", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: { Text(alertText) }

            // Full-screen blur + spinner during fraud check
            if isFraudChecking {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .overlay(ProgressView().scaleEffect(1.3))
                    .transition(.opacity)
            }

            // Fraud popup
            if showFraudPopup {
                Rectangle()
                    .fill(Color.black.opacity(0.25))
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showFraudPopup = false } }

                VStack(spacing: 12) {
                    if let img = UIImage(named: "AishaScared") {
                        Image(uiImage: img).resizable().scaledToFit().frame(height: 120)
                    } else {
                        Text("🧕").font(.system(size: 64))
                    }
                    Text("Suspicious recipient")
                        .font(.title3).fontWeight(.semibold)
                    Text("This phone number is flagged as suspicious. Please verify before sending.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                    Button {
                        withAnimation { showFraudPopup = false }
                    } label: {
                        Text("OK").fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.9)))
                            .foregroundStyle(.black)
                    }
                }
                .padding(20)
                .frame(maxWidth: 480)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
                .padding(.horizontal, 24)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Fraud check trigger
    private func runFraudCheckIfNeeded() async {
        guard target == .phone else { return }
        let raw = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        await fraudCheck(phone: raw)
    }

    private func fraudCheck(phone: String) async {
        await MainActor.run {
            isFraudChecking = true
        }
        let result = await net.fraudCheck(phone: phone)   // true = suspicious
        await MainActor.run {
            isFraudChecking = false
            if result == true {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    showFraudPopup = true
                }
            }
        }
    }

    // MARK: - Submit transfer (unchanged from your last)
    private func submitTransfer() async {
        guard let sender = selectedCard else { show("Select a card."); return }
        let amt = parseAmount(amount)
        guard amt > 0 else { show("Enter a valid amount."); return }

        let phoneValue = (target == .phone) ? phone.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        let cardValue  = (target == .card)  ? card.trimmingCharacters(in: .whitespacesAndNewlines)  : nil
        if target == .phone, (phoneValue ?? "").isEmpty { show("Enter receiver phone."); return }
        if target == .card,  (cardValue  ?? "").isEmpty { show("Enter receiver card number."); return }

        let ok = await net.submitTransfer(
            senderCardId: sender.id,
            receiverPhone: phoneValue,
            receiverCardNumber: cardValue,
            amount: amt,
            message: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        if ok {
            show("Transfer submitted."); phone = ""; card = ""; note = ""
        } else {
            show("Transfer failed. Try again.")
        }
    }

    // MARK: - Helpers
    private func parseAmount(_ s: String) -> Double {
        let cleaned = s.replacingOccurrences(of: "₸", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }
    private func show(_ text: String) { alertText = text; showAlert = true }
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
