//
//  ZamanGradientView.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI

struct ZamanGradientView: View {
    @State private var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.1 : 0.8, 0.5], [1.0, isAnimating ? 0.5 : 1.0],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .white, .zamanDarkGreen, .white, .zamanGreen, .white,
                isAnimating ? .white : .white, .zamanDarkGreen, .white, .zamanGreen, .white,
                .white, .zamanDarkGreen, .white, .zamanGreen, .white,
            ]
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                isAnimating.toggle()
            }
        }
    }
}
