import SwiftUI

struct CommunityOnboardingView: View {
    @State private var communityCode = ""
    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Logo and Title
                VStack(spacing: 12) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Constants.Colors.communityPrimary)

                    Text("ValetFlow")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Valet Trash Service")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(spacing: 16) {
                    Text("Enter your community code")
                        .font(.headline)

                    TextField("Community Code", text: $communityCode)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.oneTimeCode)
                        .autocapitalization(.allCharacters)

                    Button("Continue") {
                        showLogin = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Constants.Colors.communityPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(communityCode.isEmpty)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .sheet(isPresented: $showLogin) {
                CommunityLoginView(communityCode: communityCode)
            }
        }
    }
}

struct CommunityLoginView: View {
    let communityCode: String
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Sign in to ValetFlow")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 32)

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
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Constants.Colors.communityPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isLoading || !isValidInput)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    CommunityOnboardingView()
}
