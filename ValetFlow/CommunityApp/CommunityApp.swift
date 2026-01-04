import SwiftUI

@main
struct CommunityApp: App {
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                CommunityHomeView()
            } else {
                CommunityOnboardingView()
            }
        }
    }
}
