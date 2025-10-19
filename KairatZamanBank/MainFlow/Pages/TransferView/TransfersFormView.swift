// TransferFormView.swift
import SwiftUI

struct TransferFormView: View {
    @EnvironmentObject private var net: NetworkingService

    enum Target: String, CaseIterable { case phone = "Phone Number", card = "Card Number" }
    enum Field { case phone, card, amount, note }

    @State private var target: Target = .phone
    @Namespace private var segNS

    @State private var phone = ""
    @State private var card = ""
    @State private var amount = "0 ₸"
    @State private var note = ""
    @FocusState private var focus: Field?

    @State private var selectedCard: CardDto? = nil
    @State private var sections: [DayTransactionsDto] = []

    // alerts
    @State private var showAlert = false
    @State private var alertText = ""

    // fraud
    @State private var isFraudChecking = false
    @State private var showFraudPopup = false

    // report popup
    @State private var showReport = false
    @State private var reportText = ""
    @State private var isReporting = false
    @State private var reportError: String? = nil
    @State private var reportTxnId: Int? = nil

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

                    TransfersCardView(sections: sections) { tid in
                        reportTxnId = tid
                        reportText = ""
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { showReport = true }
                    }
                }
            }
            .task {
                if net.cards.isEmpty { await net.fetchCards() }
                if selectedCard == nil { selectedCard = net.cards.first }
            }
            .onChange(of: net.cards) { new in
                if selectedCard == nil, let first = new.first {
                    selectedCard = first
                    Task { sections = await net.fetchTransactions(cardId: first.id) }
                }
            }
            .onChange(of: selectedCard?.id) { newId in
                guard let id = newId else { return }
                Task { sections = await net.fetchTransactions(cardId: id) }
            }
            .scrollIndicators(.hidden)
            .padding(20)
            .padding(.bottom, 80)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        let leavingPhone = (focus == .phone)
                        focus = nil
                        if leavingPhone, target == .phone { Task { await runFraudCheckIfNeeded() } }
                    }
                }
            }
            .alert("Transfer", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: { Text(alertText) }

            // fraud overlay
            if isFraudChecking {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .overlay(ProgressView().scaleEffect(1.3))
                    .transition(.opacity)
            }

            // fraud popup
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
                    Text("Suspicious recipient").font(.title3).fontWeight(.semibold)
                    Text("This phone number is flagged as suspicious. Please verify before sending.")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                    Button {
                        withAnimation { showFraudPopup = false }
                    } label: {
                        Text("OK").fontWeight(.semibold)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
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

            // report popup
            if showReport {
                Color.black.opacity(0.25).ignoresSafeArea()
                    .onTapGesture { withAnimation { showReport = false } }

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Describe your problem").font(.headline)
                        Spacer()
                        Button { withAnimation { showReport = false } } label: {
                            Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.secondary)
                        }
                    }
                    Text("Explain what went wrong with this transaction:")
                        .font(.subheadline).foregroundStyle(.secondary)

                    TextEditor(text: $reportText)
                        .frame(height: 150)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if let err = reportError {
                        Text(err).font(.footnote).foregroundStyle(.red)
                    }

                    Button { Task { await submitReport() } } label: {
                        HStack {
                            if isReporting { ProgressView().tint(.black) }
                            Text(isReporting ? "Submitting..." : "Submit").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow.opacity(0.9))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isReporting || reportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(24)
                .frame(maxWidth: 560)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
                .padding(.horizontal, 24)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: fraud
    private func runFraudCheckIfNeeded() async {
        guard target == .phone else { return }
        let raw = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        await fraudCheck(phone: raw)
    }

    private func fraudCheck(phone: String) async {
        isFraudChecking = true
        let result = await net.fraudCheck(phone: phone)
        isFraudChecking = false
        if result == true {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                showFraudPopup = true
            }
        }
    }

    // MARK: submit transfer
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
        if ok { show("Transfer submitted."); phone = ""; card = ""; note = "" }
        else { show("Transfer failed. Try again.") }
    }

    // MARK: submit report
    private func submitReport() async {
        guard let tid = reportTxnId else { return }
        let msg = reportText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !msg.isEmpty else { reportError = "Please enter a description."; return }
        isReporting = true
        reportError = nil
        let ok = await net.reportTransaction(transactionId: tid, reportMessage: msg)
        isReporting = false
        if ok {
            withAnimation {
                showReport = false
            };
            reportText = ""
        }
        else {
            reportError = "Failed to submit. Try again."
        }
    }

    // MARK: helpers
    private func parseAmount(_ s: String) -> Double {
        let cleaned = s
            .replacingOccurrences(of: "₸", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }
    private func show(_ text: String) { alertText = text; showAlert = true }
}

// SegmentedSelector unchanged
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
