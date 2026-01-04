import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var authService = AuthService.shared

    var body: some View {
        TabView {
            DashboardHomeView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            EmployeesListView()
                .tabItem {
                    Label("Employees", systemImage: "person.3.fill")
                }

            CommunitiesListView()
                .tabItem {
                    Label("Communities", systemImage: "building.2.fill")
                }

            RoutesListView()
                .tabItem {
                    Label("Routes", systemImage: "map.fill")
                }

            LiveTrackingView()
                .tabItem {
                    Label("Live", systemImage: "location.fill")
                }
        }
        .accentColor(Constants.Colors.adminPrimary)
    }
}

struct DashboardHomeView: View {
    @StateObject private var authService = AuthService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome back,")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Text(authService.currentUser?.fullName ?? "Admin")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .padding()

                    // Quick Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Active Routes", value: "12", icon: "map.fill", color: .blue)
                        StatCard(title: "Employees", value: "24", icon: "person.3.fill", color: .green)
                        StatCard(title: "Communities", value: "45", icon: "building.2.fill", color: .orange)
                        StatCard(title: "Today's Pickups", value: "156", icon: "checkmark.circle.fill", color: .purple)
                    }
                    .padding(.horizontal)

                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ActivityRow(icon: "checkmark.circle.fill", title: "Route completed", subtitle: "Oak Ridge Apartments", time: "2m ago", color: .green)
                            ActivityRow(icon: "exclamationmark.triangle.fill", title: "Missed pickup reported", subtitle: "Unit 204", time: "15m ago", color: .orange)
                            ActivityRow(icon: "person.badge.plus.fill", title: "New employee added", subtitle: "John Smith", time: "1h ago", color: .blue)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: signOut) {
                        Image(systemName: "arrow.right.square")
                    }
                }
            }
        }
    }

    private func signOut() {
        try? authService.signOut()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AdminDashboardView()
}
