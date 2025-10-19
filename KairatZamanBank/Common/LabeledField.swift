//
//  LabeledField.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 19.10.2025.
//

import SwiftUI

struct LabeledField<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).foregroundStyle(.primary)
            content
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
        }
    }
}
