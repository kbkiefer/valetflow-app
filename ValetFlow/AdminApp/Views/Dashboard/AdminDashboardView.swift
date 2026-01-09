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
    @StateObject private var viewModel = DashboardViewModel()

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
                    if viewModel.isLoading {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(title: "Active Routes", value: "-", icon: "map.fill", color: .blue, isLoading: true)
                            StatCard(title: "Employees", value: "-", icon: "person.3.fill", color: .green, isLoading: true)
                            StatCard(title: "Communities", value: "-", icon: "building.2.fill", color: .orange, isLoading: true)
                            StatCard(title: "Today's Pickups", value: "-", icon: "checkmark.circle.fill", color: .purple, isLoading: true)
                        }
                        .padding(.horizontal)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(title: "Active Routes", value: "\(viewModel.routeCount)", icon: "map.fill", color: .blue)
                            StatCard(title: "Employees", value: "\(viewModel.employeeCount)", icon: "person.3.fill", color: .green)
                            StatCard(title: "Communities", value: "\(viewModel.communityCount)", icon: "building.2.fill", color: .orange)
                            StatCard(title: "Today's Pickups", value: "\(viewModel.activePickupCount)", icon: "checkmark.circle.fill", color: .purple)
                        }
                        .padding(.horizontal)
                    }

                    // Error State
                    if viewModel.hasError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Failed to load some data. Pull to refresh.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)

                        if viewModel.isLoading {
                            VStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { _ in
                                    ActivityRowPlaceholder()
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else if viewModel.recentActivity.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No recent activity")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(viewModel.recentActivity) { activity in
                                    ActivityRow(
                                        icon: activity.icon,
                                        title: activity.title,
                                        subtitle: activity.subtitle,
                                        time: activity.time,
                                        color: activity.color
                                    )
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }

                    Spacer()
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: signOut) {
                        Image(systemName: "arrow.right.square")
                    }
                }
            }
            .task {
                await viewModel.loadDashboardData()
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
    var isLoading: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            if isLoading {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 28)
                    .shimmer()
            } else {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
            }
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

struct ActivityRowPlaceholder: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
                .shimmer()

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 14)
                    .shimmer()
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 10)
                    .shimmer()
            }

            Spacer()

            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 10)
                .shimmer()
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.4),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview {
    AdminDashboardView()
}
