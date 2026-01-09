import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

enum AuthServiceError: Error, LocalizedError {
    case userProfileNotFound
    case userProfileLoadFailed(underlying: Error)
    case invalidUserId

    var errorDescription: String? {
        switch self {
        case .userProfileNotFound:
            return "User profile not found"
        case .userProfileLoadFailed(let error):
            return "Failed to load user profile: \(error.localizedDescription)"
        case .invalidUserId:
            return "Invalid user ID"
        }
    }
}

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var lastError: AuthServiceError?

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private init() {
        checkAuthStatus()
    }

    func checkAuthStatus() {
        if let firebaseUser = auth.currentUser {
            Task {
                do {
                    try await loadUserProfile(userId: firebaseUser.uid)
                } catch {
                    // Error is already stored in lastError property for UI observation
                }
            }
        }
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        try await loadUserProfile(userId: result.user.uid)
    }

    func signUp(email: String, password: String, firstName: String, lastName: String, role: UserRole, companyId: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)

        let newUser = User(
            id: result.user.uid,
            email: email,
            phone: nil,
            firstName: firstName,
            lastName: lastName,
            role: role,
            companyId: companyId,
            communityId: nil,
            unitNumber: nil,
            profilePhotoUrl: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true,
            fcmTokens: []
        )

        try await db.collection("users").document(result.user.uid).setData(from: newUser)
        currentUser = newUser
        isAuthenticated = true
    }

    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    // MARK: - User Profile

    private func loadUserProfile(userId: String) async throws {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            guard let user = try? document.data(as: User.self) else {
                let error = AuthServiceError.userProfileNotFound
                lastError = error
                throw error
            }
            currentUser = user
            isAuthenticated = true
            lastError = nil
        } catch let error as AuthServiceError {
            throw error
        } catch {
            let wrappedError = AuthServiceError.userProfileLoadFailed(underlying: error)
            lastError = wrappedError
            throw wrappedError
        }
    }

    func updateUserProfile(_ user: User) async throws {
        guard let userId = user.id else { return }
        var updatedUser = user
        updatedUser.updatedAt = Date()
        try await db.collection("users").document(userId).setData(from: updatedUser, merge: true)
        currentUser = updatedUser
    }

    // MARK: - FCM Token Management

    func registerFCMToken(_ token: String) async throws {
        guard let userId = currentUser?.id else { return }
        try await db.collection("users").document(userId).updateData([
            "fcmTokens": FieldValue.arrayUnion([token])
        ])
    }

    func unregisterFCMToken(_ token: String) async throws {
        guard let userId = currentUser?.id else { return }
        try await db.collection("users").document(userId).updateData([
            "fcmTokens": FieldValue.arrayRemove([token])
        ])
    }
}
