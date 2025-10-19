import SwiftUI

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

struct CardItem: Identifiable, Hashable {
    let id = UUID()
    let brandAsset: String
    let last4: String
    let balance: String
}
