import SwiftUI

// MARK: - Input bar mic ↔︎ arrow
struct ChatInputBar: View {
    @Binding var text: String
    var typing: FocusState<Bool>.Binding
    var sendAction: (String) -> Void
    var voiceAction: () -> Void

    private var isComposing: Bool { typing.wrappedValue || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        HStack(spacing: 12) {
            TextField("Send a message", text: $text, axis: .vertical)
                .focused(typing)
                .textFieldStyle(.plain)
                .submitLabel(.send)
                .onSubmit { if isComposing { sendAndClear() } }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.05), lineWidth: 0.5))

            Button {
                if isComposing { sendAndClear() } else { voiceAction() }
            } label: {
                Image(systemName: isComposing ? "arrow.up.right.circle.fill" : "mic.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
        }
    }

    private func sendAndClear() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        sendAction(t)
        text = ""
        typing.wrappedValue = false
    }
}
