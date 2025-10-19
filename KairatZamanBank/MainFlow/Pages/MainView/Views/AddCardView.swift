import SwiftUI

struct AddCardView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
                .font(.footnote.weight(.semibold))
            Text("Add a new Card!")
                .font(.footnote).fontWeight(.semibold)
        }
        .foregroundStyle(.primary)
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(
            Capsule(style: .continuous)
                .fill(.white)
        )
    }
}
