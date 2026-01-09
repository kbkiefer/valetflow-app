import SwiftUI

struct RouteRowView: View {
    let route: Route
    let formattedSchedule: String
    let formattedDuration: String

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(route.isActive ? Constants.Colors.success : Constants.Colors.adminAccent)
                .frame(width: 10, height: 10)

            // Route info
            VStack(alignment: .leading, spacing: 4) {
                Text(route.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                if !route.description.isEmpty {
                    Text(route.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 16) {
                    Label("\(route.communityIds.count) communities", systemImage: "building.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(formattedSchedule, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 16) {
                    Label(route.startTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(formattedDuration, systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Active badge
            if route.isActive {
                Text("Active")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Constants.Colors.success)
                    .cornerRadius(4)
            } else {
                Text("Inactive")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Constants.Colors.adminAccent)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let sampleRoute = Route(
        id: "route-1",
        companyId: "company-1",
        name: "North Austin Route",
        description: "Covers all north Austin communities",
        communityIds: ["comm-1", "comm-2", "comm-3"],
        assignedEmployeeId: "emp-1",
        scheduledDays: ["Monday", "Wednesday", "Friday"],
        startTime: "18:00",
        estimatedDuration: 120,
        stopOrder: ["comm-1", "comm-2", "comm-3"],
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    return List {
        RouteRowView(
            route: sampleRoute,
            formattedSchedule: "Mon, Wed, Fri",
            formattedDuration: "2h 0m"
        )
    }
}
