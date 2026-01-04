import SwiftUI

@main
struct AdminApp: App {
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                AdminDashboardView()
            } else {
                AdminLoginView()
            }
        }
    }
}
