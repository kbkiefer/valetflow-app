import SwiftUI

struct FieldHomeView: View {
    @StateObject private var authService = AuthService.shared

    var body: some View {
        TabView {
            ClockInView()
                .tabItem {
                    Label("Clock", systemImage: "clock.fill")
                }

            RouteView()
                .tabItem {
                    Label("Route", systemImage: "map.fill")
                }

            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(Constants.Colors.fieldPrimary)
    }
}

struct RouteView: View {
    var body: some View {
        NavigationView {
            Text("Today's route coming soon")
                .navigationTitle("Route")
        }
    }
}

struct ScheduleView: View {
    var body: some View {
        NavigationView {
            Text("Schedule coming soon")
                .navigationTitle("Schedule")
        }
    }
}

struct ProfileView: View {
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
                        Text("Email")
                        Spacer()
                        Text(authService.currentUser?.email ?? "")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        try? authService.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    FieldHomeView()
}
