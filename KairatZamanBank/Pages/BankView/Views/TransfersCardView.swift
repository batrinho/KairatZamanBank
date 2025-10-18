import SwiftUI

// MARK: Models
enum TxnType { case incoming, outgoing
    var icon: String { self == .incoming ? "arrow.down" : "arrow.up" }
    var tint: Color { self == .incoming ? .yellow : .teal }
    var amtColor: Color { self == .incoming ? .green : .red }
    var sign: String { self == .incoming ? "+" : "-" }
}
struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let amount: Decimal
    let type: TxnType
}
struct DayTransactions: Identifiable {
    let id = UUID()
    let date: Date
    let items: [Transaction]
}

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

// MARK: Helpers
private extension Decimal {
    func kzt() -> String {
        let n = NSDecimalNumber(decimal: self).doubleValue
        let f = NumberFormatter(); f.locale = .init(identifier: "ru_RU")
        f.numberStyle = .decimal; f.maximumFractionDigits = 2; f.minimumFractionDigits = 0
        return (f.string(from: NSNumber(value: n)) ?? "\(n)") + "₸"
    }
}
private extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var dayHeader: String { let f = DateFormatter(); f.dateFormat = "d MMMM"; return f.string(from: self) }
}

// MARK: Sample
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
