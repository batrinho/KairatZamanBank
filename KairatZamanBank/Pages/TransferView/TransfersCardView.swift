import SwiftUI

// MARK: Card
struct TransfersCardView: View {
    let sections: [DayTransactions] = sampleTransfers

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transactions").font(.title3).fontWeight(.semibold)

            ForEach(sections) { day in
                Text(day.date.isToday ? "Today" : day.date.dayHeader)
                    .font(.caption).foregroundStyle(.secondary)

                LazyVStack(spacing: 14, pinnedViews: []) {
                    ForEach(day.items) { TransactionRow(item: $0) }
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

// MARK: Row
private struct TransactionRow: View {
    let item: Transaction
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.type.tint.opacity(0.25))
                .frame(width: 34, height: 34)
                .overlay(Image(systemName: item.type.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(item.type.tint))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.subheadline).fontWeight(.semibold)
                if let s = item.subtitle, !s.isEmpty {
                    Text(s).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }

            Spacer()

            Text("\(item.type.sign) \(item.amount.kzt())")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(item.type.amtColor)
                .monospacedDigit()
        }
    }
}


let sampleTransfers: [DayTransactions] = {
    let today = Date()
    let y = Calendar.current.date(byAdding: .day, value: -1, to: today)!
    return [
        .init(date: today, items: [
            .init(title: "Transfer", subtitle: "Incoming transfer", amount: 3110, type: .incoming),
            .init(title: "Purchase", subtitle: "ИП “Толкынбаев Б. А.”", amount: 312.9, type: .outgoing),
        ]),
        .init(date: y, items: [
            .init(title: "Mobile top-up", subtitle: "Beeline", amount: 1500, type: .outgoing),
            .init(title: "Salary", subtitle: "Acme LLC", amount: 259000, type: .incoming),
        ]),
        .init(date: today, items: [
            .init(title: "Transfer", subtitle: "Incoming transfer", amount: 3110, type: .incoming),
            .init(title: "Purchase", subtitle: "ИП “Толкынбаев Б. А.”", amount: 312.9, type: .outgoing),
        ]),
        .init(date: y, items: [
            .init(title: "Mobile top-up", subtitle: "Beeline", amount: 1500, type: .outgoing),
            .init(title: "Salary", subtitle: "Acme LLC", amount: 259000, type: .incoming),
        ]),
        .init(date: today, items: [
            .init(title: "Transfer", subtitle: "Incoming transfer", amount: 3110, type: .incoming),
            .init(title: "Purchase", subtitle: "ИП “Толкынбаев Б. А.”", amount: 312.9, type: .outgoing),
        ]),
        .init(date: y, items: [
            .init(title: "Mobile top-up", subtitle: "Beeline", amount: 1500, type: .outgoing),
            .init(title: "Salary", subtitle: "Acme LLC", amount: 259000, type: .incoming),
        ])
    ]
}()
