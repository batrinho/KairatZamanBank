//
//  StartingPageView.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import SwiftUI

struct BankView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AishaButtonView()
                VStack(spacing: 5) {
                    HStack {
                        Text("My cards:")
                            .bold()
                        Spacer()
                    }
                    LazyVStack(spacing: 10) {
                        CardView()
                        CardView()
                    }
                }
                AddCardView()
            }
        }
        .scrollIndicators(.hidden)
        .padding(20)
        .background(Color.clear)
    }
}
