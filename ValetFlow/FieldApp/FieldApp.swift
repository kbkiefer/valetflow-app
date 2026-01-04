import SwiftUI

@main
struct FieldApp: App {
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                FieldHomeView()
            } else {
                FieldLoginView()
            }
        }
    }
}
