// AssistantButtonView.swift — show happy/sad image by mood, flexible height
import SwiftUI

struct AishaButtonView: View {
    var title: String = "It’s time for Zakyat!"
    var subtitle: String = "- Aisha Assistant"
    var moodHappy: Bool = true
    var onTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 14) {
            Image(moodHappy ? "AishaHappy" : "AishaSad")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "arrow.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.7))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(ZamanGradientView().cornerRadius(22))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
