// MARK: - LoginView (closure-based, refined)
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var net: NetworkingService
    var onSignIn: () -> Void = {}
    var onShowSignUp: () -> Void = {}

    @State private var phone = ""
    @State private var password = ""
    @FocusState private var focused: Field?
    @State private var showError = false
    @State private var errorText = ""

    enum Field { case phone, password }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 24)

            Text("Log in")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.teal)

            VStack(alignment: .leading, spacing: 16) {
                LabeledField("Phone number") {
                    TextField("+7 (___) ___-__-__", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .focused($focused, equals: .phone)
                        .submitLabel(.next)
                        .onSubmit { focused = .password }
                }

                LabeledField("Password") {
                    SecureField("Enter your password", text: $password)
                        .textContentType(.password)
                        .focused($focused, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { triggerLogin() }
                }
            }
            .padding(.horizontal, 24)

            Button(action: triggerLogin) {
                HStack(spacing: 10) {
                    if net.isAuthBusy { ProgressView().tint(.black) }
                    Text(net.isAuthBusy ? "Logging in..." : "Log in")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.9)))
                .foregroundStyle(.black)
            }
            .padding(.horizontal, 80)
            .disabled(net.isAuthBusy || phone.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)

            Spacer()

            HStack(spacing: 6) {
                Text("Do not have account?").foregroundStyle(.secondary)
                Button("Sign up") { onShowSignUp() }
                    .font(.callout.weight(.semibold))
            }
            .padding(.bottom, 20)
        }
        .onChange(of: net.authError) { new in
            showError = new != nil
            errorText = new ?? ""
        }
        .alert("Login failed", isPresented: $showError) {
            Button("OK") { net.authError = nil }
        } message: {
            Text(errorText)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
            }
        }
        .background(Color(white: 0.97))
    }

    private func triggerLogin() {
        guard !net.isAuthBusy else { return }
        focused = nil
        Task {
            let ok = await net.login(username: phone, password: password)
            if ok {
                NotificationCenter.default.post(name: .authDidChange, object: nil)
                onSignIn() // optional direct handoff
            }
        }
    }
}
