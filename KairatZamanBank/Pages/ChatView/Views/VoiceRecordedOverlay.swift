//
//  VoiceRecordedOverlay.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI

struct VoiceOverlay: View {
    @Binding var level: CGFloat
    @Binding var phase: VoiceOverlayPhase
    var stop: () -> Void      // stops recording (keeps overlay)
    var cancel: () -> Void    // cancels and closes overlay

    private var speakingURL: URL? {
        Bundle.main.url(forResource: "aisha_speaking", withExtension: "mp4")
    }

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { } // block taps to dismiss

            VStack(spacing: 24) {
                content
                controls
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 20)
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .listening:
            VStack(spacing: 18) {
                Image("AishaListening")
                    .resizable().renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .scaleEffect(1 + 0.5 * level)
                    .animation(.easeInOut(duration: 0.12), value: level)
                Text("Listening…")
                    .font(.headline).fontWeight(.semibold)
            }

        case .waiting:
            VStack(spacing: 18) {
                Image("AishaThinking")
                    .resizable().renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .scaleEffect(1 + 0.5 * level)
                    .animation(.easeInOut(duration: 0.12), value: level)
                Text("Thinking…")
                    .font(.headline).fontWeight(.semibold)
            }

        case .speaking:
            VStack(spacing: 14) {
                if let url = speakingURL {
                    SpeakingVideoView(url: url)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
                } else {
                    // Fallback if video missing
                    Image("AishaHappy")
                        .resizable().scaledToFit()
                        .frame(height: 180)
                }
                Text("Speaking…")
                    .font(.headline).fontWeight(.semibold)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch phase {
        case .listening:
            HStack(spacing: 18) {
                Button(action: stop) {
                    Label("Stop", systemImage: "checkmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(Color.white))
                }
                Button(action: cancel) {
                    Label("Cancel", systemImage: "xmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(.black.opacity(0.35)))
                }
            }

        case .waiting:
            HStack {
                Button(action: cancel) {
                    Label("Cancel", systemImage: "xmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(.black.opacity(0.35)))
                }
            }

        case .speaking:
            // Optional: allow cancel during playback; if you prefer no buttons, remove this block.
            HStack {
                Button(action: cancel) {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(.black.opacity(0.35)))
                }
            }
        }
    }
}
