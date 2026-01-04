import SwiftUI

struct CommunityHomeView: View {
    var body: some View {
        TabView {
            ScheduleTabView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar.fill")
                }

            TrackingTabView()
                .tabItem {
                    Label("Track", systemImage: "location.fill")
                }

            IssuesTabView()
                .tabItem {
                    Label("Issues", systemImage: "exclamationmark.bubble.fill")
                }

            AccountTabView()
                .tabItem {
                    Label("Account", systemImage: "person.fill")
                }
        }
        .accentColor(Constants.Colors.communityPrimary)
    }
}

struct ScheduleTabView: View {
    var body: some View {
        NavigationView {
            Text("Pickup schedule coming soon")
                .navigationTitle("Schedule")
        }
    }
}

struct TrackingTabView: View {
    var body: some View {
        NavigationView {
            Text("Driver tracking coming soon")
                .navigationTitle("Track Driver")
        }
    }
}

struct IssuesTabView: View {
    var body: some View {
        NavigationView {
            Text("Issue reporting coming soon")
                .navigationTitle("Issues")
        }
    }
}

struct AccountTabView: View {
    @StateObject private var authService = AuthService.shared

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(authService.currentUser?.fullName ?? "")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Unit")
                        Spacer()
                        Text(authService.currentUser?.unitNumber ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        try? authService.signOut()
                    }
                }
            }
            .navigationTitle("Account")
        }
    }
}

#Preview {
    CommunityHomeView()
}
