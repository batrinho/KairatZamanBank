//
//  VoiceRecordedOverlay.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI

struct VoiceOverlay: View {
    @Binding var level: CGFloat
    var stop: () -> Void
    var cancel: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Image("AishaListening")
                .resizable().renderingMode(.original)
                .scaledToFit()
                .frame(width: 150, height: 150)
                .scaleEffect(1 + 0.5 * level)
                .animation(.easeInOut(duration: 0.12), value: level)
            HStack(spacing: 30) {
                Button(action: stop) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                Button(action: cancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(.ultraThinMaterial))
                }
            }
        }
        .padding(24)
    }
}
