import SwiftUI

struct RouteRowView: View {
    let route: Route
    let formattedSchedule: String
    let formattedDuration: String
    let index: Int

    @State private var isVisible = false
    @State private var isPressed = false

    init(route: Route, formattedSchedule: String, formattedDuration: String, index: Int = 0) {
        self.route = route
        self.formattedSchedule = formattedSchedule
        self.formattedDuration = formattedDuration
        self.index = index
    }

    private var animationDelay: Double {
        Double(index) * 0.05
    }

    var body: some View {
        HStack(spacing: 14) {
            // Animated status indicator
            PulsingStatusIndicator(
                isActive: route.isActive,
                activeColor: Constants.Colors.success,
                inactiveColor: Constants.Colors.adminAccent
            )

            // Route info with enhanced styling
            VStack(alignment: .leading, spacing: 6) {
                Text(route.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())

                if !route.description.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "text.alignleft")
                            .font(.caption2)
                            .foregroundColor(Constants.Colors.fieldPrimary.opacity(0.7))

                        Text(route.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 12) {
                    RouteStatLabel(
                        icon: "building.2.fill",
                        value: "\(route.communityIds.count)",
                        label: "communities",
                        color: Constants.Colors.communityPrimary
                    )

                    RouteStatLabel(
                        icon: "calendar",
                        value: formattedSchedule,
                        label: "",
                        color: Constants.Colors.adminPrimary
                    )
                }

                HStack(spacing: 12) {
                    RouteStatLabel(
                        icon: "clock.fill",
                        value: route.startTime,
                        label: "",
                        color: Constants.Colors.fieldAccent
                    )

                    RouteStatLabel(
                        icon: "timer",
                        value: formattedDuration,
                        label: "",
                        color: Constants.Colors.fieldPrimary
                    )
                }
            }

            Spacer()

            // Animated status badge
            AnimatedStatusBadge(
                isActive: route.isActive,
                activeColor: Constants.Colors.success,
                inactiveColor: Constants.Colors.adminAccent
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(
                    color: route.isActive
                        ? Constants.Colors.success.opacity(0.08)
                        : Color.black.opacity(0.04),
                    radius: 10,
                    x: 0,
                    y: 3
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    LinearGradient(
                        colors: route.isActive
                            ? [Constants.Colors.success.opacity(0.25), Constants.Colors.success.opacity(0.05)]
                            : [Color.gray.opacity(0.15), Color.gray.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8)
            .delay(animationDelay),
            value: isVisible
        )
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Route Stat Label Component

private struct RouteStatLabel: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    @State private var isAnimated = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color.opacity(0.7))
                .scaleEffect(isAnimated ? 1.0 : 0.8)

            if label.isEmpty {
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text("\(value) \(label)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .contentTransition(.numericText())
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) {
                isAnimated = true
            }
        }
    }
}

// MARK: - Skeleton Loading for Route Row

struct RouteRowSkeleton: View {
    let index: Int

    @State private var isVisible = false

    private var animationDelay: Double {
        Double(index) * 0.08
    }

    var body: some View {
        HStack(spacing: 14) {
            // Status indicator placeholder
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 10, height: 10)

            // Content placeholders
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 16)

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 12, height: 12)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 200, height: 12)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 10, height: 10)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 70, height: 10)
                    }

                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 10, height: 10)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 80, height: 10)
                    }
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 10, height: 10)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 40, height: 10)
                    }

                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 10, height: 10)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 50, height: 10)
                    }
                }
            }

            Spacer()

            // Badge placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 55, height: 24)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .shimmer()
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 15)
        .animation(
            .easeOut(duration: 0.35)
            .delay(animationDelay),
            value: isVisible
        )
        .onAppear {
            isVisible = true
        }
    }
}

#Preview("Route Row") {
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

    return ScrollView {
        VStack(spacing: 12) {
            RouteRowView(
                route: sampleRoute,
                formattedSchedule: "Mon, Wed, Fri",
                formattedDuration: "2h 0m",
                index: 0
            )
            RouteRowView(
                route: sampleRoute,
                formattedSchedule: "Mon, Wed, Fri",
                formattedDuration: "2h 0m",
                index: 1
            )
            RouteRowView(
                route: sampleRoute,
                formattedSchedule: "Mon, Wed, Fri",
                formattedDuration: "2h 0m",
                index: 2
            )
        }
        .padding()
    }
}

#Preview("Skeleton Loading") {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { index in
                RouteRowSkeleton(index: index)
            }
        }
        .padding()
    }
}
