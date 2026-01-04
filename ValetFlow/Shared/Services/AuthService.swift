import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private init() {
        checkAuthStatus()
    }

    func checkAuthStatus() {
        if let firebaseUser = auth.currentUser {
            Task {
                await loadUserProfile(userId: firebaseUser.uid)
            }
        }
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        await loadUserProfile(userId: result.user.uid)
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

    private func loadUserProfile(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let user = try? document.data(as: User.self) {
                currentUser = user
                isAuthenticated = true
            }
        } catch {
            print("Error loading user profile: \(error)")
        }
    }

    func updateUserProfile(_ user: User) async throws {
        guard let userId = user.id else { return }
        var updatedUser = user
        updatedUser.updatedAt = Date()
        try db.collection("users").document(userId).setData(from: updatedUser, merge: true)
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
