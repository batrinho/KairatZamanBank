// FinancialGoalView.swift — use NetworkingService, no direct networking
import SwiftUI

struct FinancialGoalView: View {
    @EnvironmentObject private var net: NetworkingService

    @State private var goalText: String = ""
    @State private var showingPopup = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.white, Color(red: 0.96, green: 1.0, blue: 0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Your financial goal")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.top, 8)

                    Text("Your goal and amount of money needed should be included*")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $goalText)
                            .padding(10)
                            .frame(height: 250)
                            .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )

                        if goalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Vacation in the Maldives e.g.")
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.top, 18)
                                .padding(.leading, 16)
                        }
                    }

                    Text("*This information is needed for better cohesion of your financial report and your personal preferences.\nWith this we can provide you with the best advices")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 20)

                    Button(action: saveGoal) {
                        Text(isSaving ? "Saving..." : "Save")
                            .bold()
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.91, green: 1.0, blue: 0.3))
                            .cornerRadius(14)
                    }
                    .disabled(isSaving || goalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Aisha Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.clear, for: .navigationBar)
            .tint(.black)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { SettingsView() } label: {
                        Image(systemName: "gearshape.fill").font(.title3)
                    }
                }
            }
            .alert("Goal Saved!", isPresented: $showingPopup) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your financial goal has been successfully saved.")
            }
        }
    }

    private func saveGoal() {
        let trimmed = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            if await net.updateFinancialGoal(trimmed) {
                showingPopup = true
                goalText = ""
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var net: NetworkingService

    @State private var goalText: String = ""
    @State private var isSaving = false
    @State private var showPopup = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color(red: 0.96, green: 1.0, blue: 0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Your financial goal")
                    .font(.headline)
                    .foregroundColor(.black)

                Text("Your goal and amount of money needed should be included*")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $goalText)
                        .padding(10)
                        .frame(height: 250)
                        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    if goalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Vacation in the Maldives e.g.")
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.top, 18)
                            .padding(.leading, 16)
                    }
                }

                Text("*This information is needed for better cohesion of your financial report and your personal preferences.\nWith this we can provide you with the best advices")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Button(action: saveGoal) {
                    Text(isSaving ? "Saving..." : "Save")
                        .bold()
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.91, green: 1.0, blue: 0.3))
                        .cornerRadius(14)
                }
                .disabled(isSaving || goalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.clear, for: .navigationBar)
        .tint(.black)
        .alert("Goal Saved!", isPresented: $showPopup) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your financial goal has been successfully saved.")
        }
    }

    private func saveGoal() {
        let trimmed = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            if await net.updateFinancialGoal(trimmed) {
                showPopup = true
                goalText = ""
            }
        }
    }
}
