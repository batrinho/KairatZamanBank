import SwiftUI

struct MainPageView: View {
    @EnvironmentObject private var net: NetworkingService
    @State private var tab: BankTab = .bank

    var body: some View {
        ZStack {
            // content
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
            .ignoresSafeArea(edges: .bottom)

            // top-left logout
            VStack {
                HStack {
                    Button {
                        net.logout()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "power")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Log out")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 16)

                    Spacer()
                }
                .padding(.top, 14)

                Spacer()
            }
        }
        .scrollDismissesKeyboard(.interactively)
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
