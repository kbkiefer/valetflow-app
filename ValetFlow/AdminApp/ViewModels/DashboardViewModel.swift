import Foundation
import SwiftUI

struct ActivityItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    let timestamp: Date
}

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var employeeCount: Int = 0
    @Published var communityCount: Int = 0
    @Published var routeCount: Int = 0
    @Published var activePickupCount: Int = 0

    @Published var recentActivity: [ActivityItem] = []

    @Published var isLoading = true
    @Published var error: Error?
    @Published var hasError = false

    // MARK: - Private Properties

    private let firebaseService = FirebaseService.shared

    // MARK: - Public Methods

    func loadDashboardData() async {
        isLoading = true
        hasError = false
        error = nil

        do {
            async let employeesTask = fetchEmployeeCount()
            async let communitiesTask = fetchCommunityCount()
            async let routesTask = fetchRouteCount()
            async let pickupsTask = fetchActivePickupCount()
            async let activityTask = fetchRecentActivity()

            let (employees, communities, routes, pickups, activity) = await (
                try employeesTask,
                try communitiesTask,
                try routesTask,
                try pickupsTask,
                try activityTask
            )

            employeeCount = employees
            communityCount = communities
            routeCount = routes
            activePickupCount = pickups
            recentActivity = activity

        } catch {
            self.error = error
            self.hasError = true
            print("Dashboard error: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func refresh() async {
        await loadDashboardData()
    }

    // MARK: - Private Methods

    private func fetchEmployeeCount() async throws -> Int {
        let employees: [Employee] = try await firebaseService.fetchAll(
            collection: "employees",
            whereField: "isActive",
            isEqualTo: true
        )
        return employees.count
    }

    private func fetchCommunityCount() async throws -> Int {
        let communities: [Community] = try await firebaseService.fetchAll(
            collection: "communities",
            whereField: "isActive",
            isEqualTo: true
        )
        return communities.count
    }

    private func fetchRouteCount() async throws -> Int {
        let routes: [Route] = try await firebaseService.fetchAll(
            collection: "routes",
            whereField: "isActive",
            isEqualTo: true
        )
        return routes.count
    }

    private func fetchActivePickupCount() async throws -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let pickups: [Pickup] = try await firebaseService.fetchAll(collection: "pickups")

        // Filter for today's pickups that are pending or completed
        let todayPickups = pickups.filter { pickup in
            let pickupDate = Calendar.current.startOfDay(for: pickup.scheduledDate)
            return pickupDate == today
        }

        return todayPickups.count
    }

    private func fetchRecentActivity() async throws -> [ActivityItem] {
        var activities: [ActivityItem] = []

        // Fetch recent pickups
        let pickups: [Pickup] = try await firebaseService.fetchAll(collection: "pickups")
        let recentPickups = pickups
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(5)

        for pickup in recentPickups {
            let activity = createActivityFromPickup(pickup)
            activities.append(activity)
        }

        // Fetch recent issues
        let issues: [Issue] = try await firebaseService.fetchAll(collection: "issues")
        let recentIssues = issues
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)

        for issue in recentIssues {
            let activity = createActivityFromIssue(issue)
            activities.append(activity)
        }

        // Sort all activities by timestamp and return the most recent
        return activities
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(10)
            .map { $0 }
    }

    private func createActivityFromPickup(_ pickup: Pickup) -> ActivityItem {
        let (icon, title, color): (String, String, Color) = {
            switch pickup.status {
            case .completed:
                return ("checkmark.circle.fill", "Pickup completed", .green)
            case .missed:
                return ("xmark.circle.fill", "Pickup missed", .red)
            case .pending:
                return ("clock.fill", "Pickup scheduled", .blue)
            case .issue:
                return ("exclamationmark.triangle.fill", "Pickup issue reported", .orange)
            }
        }()

        return ActivityItem(
            icon: icon,
            title: title,
            subtitle: "Community \(pickup.communityId.prefix(8))...",
            time: formatRelativeTime(pickup.updatedAt),
            color: color,
            timestamp: pickup.updatedAt
        )
    }

    private func createActivityFromIssue(_ issue: Issue) -> ActivityItem {
        let (icon, color): (String, Color) = {
            switch issue.priority {
            case .high:
                return ("exclamationmark.triangle.fill", .red)
            case .medium:
                return ("exclamationmark.circle.fill", .orange)
            case .low:
                return ("info.circle.fill", .yellow)
            }
        }()

        let title: String = {
            switch issue.status {
            case .open:
                return "Issue reported"
            case .investigating:
                return "Issue under investigation"
            case .resolved:
                return "Issue resolved"
            case .closed:
                return "Issue closed"
            }
        }()

        return ActivityItem(
            icon: icon,
            title: title,
            subtitle: issue.description.prefix(30) + (issue.description.count > 30 ? "..." : ""),
            time: formatRelativeTime(issue.createdAt),
            color: color,
            timestamp: issue.createdAt
        )
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "1d ago" : "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1h ago" : "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1m ago" : "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}
