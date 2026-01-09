import SwiftUI

struct FieldLoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Logo and Title
                VStack(spacing: 12) {
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Constants.Colors.fieldPrimary)

                    Text("ValetFlow Field")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Employee App")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button(action: signIn) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Clock In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Constants.Colors.fieldPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isLoading || !isValidInput)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }

    private var isValidInput: Bool {
        !email.isEmpty && !password.isEmpty && email.isValidEmail
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    FieldLoginView()
}
