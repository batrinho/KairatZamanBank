//
//  StartingPageView.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI

struct BankView: View {
    @EnvironmentObject var net: NetworkingService
    var onTap: () -> Void = {}
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AishaButtonView().onTapGesture {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onTap()
                }
                
                LazyVStack(spacing: 10) {
                    ForEach(net.cards) { c in
                        CardView(dto: c)
                    }
                }
                
                AddCardView()
                    .onTapGesture {
                        net.showPopup = true
                    }
            }
        }
        .task { await net.fetchCards() }
        .scrollIndicators(.hidden)
        .padding(20)
        .padding(.bottom, 80)
        .background(Color.clear)
        .overlay { if net.showPopup { popupView } }
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: net.showPopup)
    }
    
    // MARK: - Popup
    private var popupView: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
                .onTapGesture { net.showPopup = false }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Design your card").font(.headline)
                    Spacer()
                    Button {
                        net.showPopup = false
                    } label: {
                        Image(systemName: "xmark.circle.fill").font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("Write a prompt for the card design:")
                    .font(.subheadline).foregroundStyle(.secondary)
                
                TextEditor(text: $net.promptText)
                    .frame(height: 160)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                Button {
                    Task { await net.submitPrompt() }
                } label: {
                    HStack {
                        if net.isSubmitting { ProgressView().tint(.black) }
                        Text(net.isSubmitting ? "Submitting..." : "Submit")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow.opacity(0.9))
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(net.isSubmitting)
            }
            .padding(24)
            .frame(maxWidth: 560)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
            .padding(.horizontal, 24)
        }
    }
}
