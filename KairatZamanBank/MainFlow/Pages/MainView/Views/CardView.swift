// CardView.swift
import SwiftUI

struct CardView: View {
    let dto: CardDto
    @State private var isPressed = false
    @State private var showDetails = false

    var body: some View {
        ZStack {
            if let url = dto.imageURL {
                CachedAsyncImage(url: url) { gradient }
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
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressed { isPressed = true } }
                .onEnded { _ in
                    isPressed = false
                    showDetails = true
                }
        )
        .sheet(isPresented: $showDetails) {
            CardDetailView(dto: dto)
                .presentationDetents([.medium, .large])
        }
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

// MARK: - Detail sheet
private struct CardDetailView: View {
    let dto: CardDto

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card details")
                .font(.title3).fontWeight(.semibold)

            infoRow(title: "Balance", value: formattedBalance(dto.balance, dto.currency))
            infoRow(title: "Card number", value: formattedNumber(dto.cardNumber))
            infoRow(title: "Valid thru", value: formattedExpiry(dto.expirationDate))
            infoRow(title: "CVV", value: dto.cvv)
            infoRow(title: "Holder", value: dto.cardHolderName)

            Spacer()
        }
        .padding(20)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value).fontWeight(.semibold).textSelection(.enabled)
        }
        .font(.callout)
        .padding(.vertical, 6)
    }

    // Formatters
    private func formattedNumber(_ raw: String) -> String {
        let digits = raw.replacingOccurrences(of: " ", with: "")
        return stride(from: 0, to: digits.count, by: 4).map { idx in
            let s = digits.index(digits.startIndex, offsetBy: idx)
            let e = digits.index(s, offsetBy: min(4, digits.distance(from: s, to: digits.endIndex)), limitedBy: digits.endIndex) ?? digits.endIndex
            return String(digits[s..<e])
        }.joined(separator: " ")
    }

    private func formattedExpiry(_ date: Date?) -> String {
        guard let d = date else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "MM/yy"
        return f.string(from: d)
    }

    private func formattedBalance(_ amount: Double, _ currency: String) -> String {
        // Simple formatter. Adjust to your locale if needed.
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        let amt = nf.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "\(amt) \(currency)"
    }
}
