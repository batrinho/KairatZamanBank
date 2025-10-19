// TransfersCardView.swift
import SwiftUI

struct TransfersCardView: View {
    let sections: [DayTransactionsDto]
    var onReport: (Int) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transactions").font(.title3).fontWeight(.semibold)

            ForEach(sections) { day in
                Text(day.date.isToday ? "Today" : day.date.dayHeader)
                    .font(.caption).foregroundStyle(.secondary)

                LazyVStack(spacing: 14) {
                    ForEach(day.items, id: \.id) { txn in
                        TransactionRow(item: txn, onReport: onReport)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
        )
    }
}

private struct TransactionRow: View {
    let item: TxnDto
    var onReport: (Int) -> Void

    private var type: TxnType { item.isSender ? .outgoing : .incoming }
    private var subtitle: String {
        item.message.isEmpty
        ? (item.isSender ? "Outgoing transfer" : "Incoming transfer")
        : item.message
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(type.tint.opacity(0.25))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: type.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(type.tint)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Transfer").font(.subheadline).fontWeight(.semibold)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }

            Spacer()

            Text("\(type.sign) \(item.amount, specifier: "%.2f") ₸")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(type.amtColor)
                .monospacedDigit()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onReport(item.id)
            } label: {
                Image(systemName: "exclamationmark.circle").font(.headline)
            }
            .buttonStyle(.plain)
            .padding(.leading, 6)
        }
    }
}
