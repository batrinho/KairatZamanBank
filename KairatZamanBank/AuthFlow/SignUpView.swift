import SwiftUI

// MARK: - SignUpView (calls /auth/register and stores token via NetworkingService)
struct SignUpView: View {
    @EnvironmentObject private var net: NetworkingService
    var onComplete: () -> Void = {}

    @State private var username = ""
    @State private var password = ""
    @State private var name = ""
    @State private var surname = ""
    @FocusState private var focused: Field?
    enum Field { case username, password, name, surname }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 24)

            Text("Sign up")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.teal)

            VStack(alignment: .leading, spacing: 16) {
                LabeledField("Phone number") {
                    TextField("Enter phone number", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focused = .password }
                }
                LabeledField("Password") {
                    SecureField("Enter your password", text: $password)
                        .textContentType(.newPassword)
                        .focused($focused, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focused = .name }
                }
                LabeledField("Name") {
                    TextField("Enter your name", text: $name)
                        .textInputAutocapitalization(.words)
                        .focused($focused, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focused = .surname }
                }
                LabeledField("Surname") {
                    TextField("Enter your surname", text: $surname)
                        .textInputAutocapitalization(.words)
                        .focused($focused, equals: .surname)
                        .submitLabel(.done)
                        .onSubmit { focused = nil }
                }

                if let err = net.authError, !err.isEmpty {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 24)

            Button(action: submit) {
                HStack(spacing: 10) {
                    if net.isAuthBusy { ProgressView().progressViewStyle(.circular) }
                    Text("Create account")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.9)))
                .foregroundStyle(.black)
            }
            .padding(.horizontal, 80)
            .disabled(!canSubmit || net.isAuthBusy)
            .opacity(!canSubmit || net.isAuthBusy ? 0.6 : 1)

            Spacer()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
            }
        }
        .background(Color(white: 0.97))
    }

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !surname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        focused = nil
        Task {
            let ok = await net.register(username: username, password: password, name: name, surname: surname)
            if ok { onComplete() }
        }
    }
}
