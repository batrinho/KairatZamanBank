import SwiftUI

struct MainPageView: View {
    @StateObject private var net = NetworkingService()
    @State private var tab: BankTab = .bank
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .bank:
                    BankView { tab = .chat }
                case .transfers:
                    TransferFormView()
                case .chat:
                    AishaAssistantView()
                }
            }
            .environmentObject(net)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            PillTabBar(selection: $tab)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct PillTabBar: View {
    @Binding var selection: BankTab
    
    var body: some View {
        HStack {
            ForEach(BankTab.allCases) { t in
                Button {
                    selection = t
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: t.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                        Text(t.rawValue).font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selection == t ? Color.zamanDarkGreen : .primary.opacity(0.85))
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .background(
            Capsule(style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        )
    }
}
