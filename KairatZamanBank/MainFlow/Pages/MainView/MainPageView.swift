import SwiftUI

private enum MainRoute: Hashable {
    case settings
}

struct MainPageView: View {
    @EnvironmentObject private var net: NetworkingService
    @State private var tab: BankTab = .bank
    @State private var reminderTitle: String = "It’s time for Zakyat!"
    @State private var reminderMoodHappy: Bool = true

    @State private var path: [MainRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // content
                ZStack(alignment: .bottom) {
                    Group {
                        switch tab {
                        case .bank:
                            BankView(reminderTitle: reminderTitle, reminderMoodHappy: reminderMoodHappy) { tab = .chat }
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

                // top bar
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

                        Button {
                            withAnimation(.easeInOut) { path.append(.settings) } // push with animation
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "gear")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Settings")
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
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 14)

                    Spacer()
                }
            }
            .task { await loadReminder() }
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(for: MainRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView()
                        .environmentObject(net)
                        .navigationTitle("Settings")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    private func loadReminder() async {
        if let r = await net.fetchReminder() {
            reminderTitle = r.advice.isEmpty ? reminderTitle : r.advice
            reminderMoodHappy = r.mood
        }
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
