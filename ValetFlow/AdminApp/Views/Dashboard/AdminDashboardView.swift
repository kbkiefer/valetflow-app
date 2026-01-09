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

// MARK: - Dashboard Home View

struct DashboardHomeView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var viewModel = DashboardViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var hasAppeared = false
    @State private var isRefreshing = false
    @Namespace private var animation

    var body: some View {
        NavigationView {
            ScrollView {
                scrollOffsetReader

                VStack(spacing: 24) {
                    // Animated Welcome Header with Parallax
                    welcomeHeader
                        .offset(y: parallaxOffset)

                    // Animated Quick Stats Grid
                    statsGrid

                    // Error State with Animation
                    if viewModel.hasError {
                        errorBanner
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Animated Recent Activity Section
                    recentActivitySection

                    Spacer(minLength: 40)
                }
            }
            .coordinateSpace(name: "scroll")
            .refreshable {
                await performRefresh()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    signOutButton
                }
            }
            .task {
                await viewModel.loadDashboardData()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Scroll Offset Reader

    private var scrollOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ScrollOffsetPreferenceKey.self,
                value: proxy.frame(in: .named("scroll")).minY
            )
        }
        .frame(height: 0)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
    }

    private var parallaxOffset: CGFloat {
        scrollOffset > 0 ? scrollOffset * 0.3 : 0
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)

                Text(authService.currentUser?.fullName ?? "Admin")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: hasAppeared)

            Spacer()

            // Animated greeting icon
            greetingIcon
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var greetingIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)

            Image(systemName: currentTimeIcon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating)
        }
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.5)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: hasAppeared)
    }

    private var currentTimeIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "sun.rise.fill"
        case 12..<17: return "sun.max.fill"
        case 17..<21: return "sunset.fill"
        default: return "moon.stars.fill"
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            AnimatedStatCard(
                title: "Active Routes",
                value: viewModel.routeCount,
                icon: "map.fill",
                gradient: [Color.blue, Color.cyan],
                isLoading: viewModel.isLoading,
                index: 0,
                hasAppeared: hasAppeared
            )

            AnimatedStatCard(
                title: "Employees",
                value: viewModel.employeeCount,
                icon: "person.3.fill",
                gradient: [Color.green, Color.mint],
                isLoading: viewModel.isLoading,
                index: 1,
                hasAppeared: hasAppeared
            )

            AnimatedStatCard(
                title: "Communities",
                value: viewModel.communityCount,
                icon: "building.2.fill",
                gradient: [Color.orange, Color.yellow],
                isLoading: viewModel.isLoading,
                index: 2,
                hasAppeared: hasAppeared
            )

            AnimatedStatCard(
                title: "Today's Pickups",
                value: viewModel.activePickupCount,
                icon: "checkmark.circle.fill",
                gradient: [Color.purple, Color.pink],
                isLoading: viewModel.isLoading,
                index: 3,
                hasAppeared: hasAppeared
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Error Banner

    private var errorBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .symbolEffect(.pulse)

            Text("Failed to load some data. Pull to refresh.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                Task {
                    await performRefresh()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                if !viewModel.recentActivity.isEmpty {
                    Text("\(viewModel.recentActivity.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.secondary.opacity(0.1)))
                }
            }
            .padding(.horizontal, 20)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: hasAppeared)

            activityContent
        }
    }

    @ViewBuilder
    private var activityContent: some View {
        if viewModel.isLoading {
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    AnimatedActivityRowPlaceholder(index: index)
                }
            }
            .padding(16)
            .background(GlassBackground())
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        } else if viewModel.recentActivity.isEmpty {
            emptyActivityState
        } else {
            VStack(spacing: 4) {
                ForEach(Array(viewModel.recentActivity.enumerated()), id: \.element.id) { index, activity in
                    AnimatedActivityRow(
                        icon: activity.icon,
                        title: activity.title,
                        subtitle: activity.subtitle,
                        time: activity.time,
                        color: activity.color,
                        index: index,
                        hasAppeared: hasAppeared
                    )

                    if index < viewModel.recentActivity.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .padding(16)
            .background(GlassBackground())
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }

    private var emptyActivityState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "tray")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))
            }

            VStack(spacing: 4) {
                Text("No recent activity")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Activity will appear here as it happens")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(GlassBackground())
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .opacity(hasAppeared ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: hasAppeared)
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button(action: signOut) {
            Image(systemName: "arrow.right.square")
                .symbolRenderingMode(.hierarchical)
                .font(.title3)
        }
    }

    // MARK: - Actions

    private func signOut() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        try? authService.signOut()
    }

    private func performRefresh() async {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isRefreshing = true
        }

        await viewModel.refresh()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isRefreshing = false
        }
    }
}

// MARK: - Animated Stat Card

struct AnimatedStatCard: View {
    let title: String
    let value: Int
    let icon: String
    let gradient: [Color]
    let isLoading: Bool
    let index: Int
    let hasAppeared: Bool

    @State private var isPressed = false
    @State private var displayValue: Int = 0
    @State private var hasAnimatedValue = false

    private var animationDelay: Double {
        Double(index) * 0.1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon with animated background
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: hasAppeared && !isLoading)
                }

                Spacer()

                // Trend indicator (placeholder for future)
                if !isLoading {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.green)
                        .opacity(0.8)
                }
            }

            // Value with counting animation
            if isLoading {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 32)
                    .shimmer()
            } else {
                Text("\(displayValue)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText(value: Double(displayValue)))
                    .onAppear {
                        animateValue()
                    }
                    .onChange(of: value) { _, newValue in
                        animateToValue(newValue)
                    }
            }

            // Title
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                // Glass background
                GlassBackground()

                // Gradient accent at top
                LinearGradient(
                    colors: gradient.map { $0.opacity(0.1) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: gradient[0].opacity(isPressed ? 0.3 : 0.15),
            radius: isPressed ? 8 : 12,
            x: 0,
            y: isPressed ? 2 : 6
        )
        .scaleEffect(isPressed ? 0.96 : 1)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 30)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7).delay(animationDelay),
            value: hasAppeared
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            performTapAnimation()
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private func animateValue() {
        guard !hasAnimatedValue && !isLoading else { return }
        hasAnimatedValue = true

        let duration: Double = 0.8
        let steps = 20
        let stepDuration = duration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step) + animationDelay + 0.3) {
                withAnimation(.easeOut(duration: 0.05)) {
                    displayValue = Int(Double(value) * easeOutQuart(Double(step) / Double(steps)))
                }
            }
        }
    }

    private func animateToValue(_ newValue: Int) {
        let duration: Double = 0.5
        let steps = 15
        let stepDuration = duration / Double(steps)
        let startValue = displayValue
        let difference = newValue - startValue

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                withAnimation(.easeOut(duration: 0.05)) {
                    displayValue = startValue + Int(Double(difference) * easeOutQuart(Double(step) / Double(steps)))
                }
            }
        }
    }

    private func easeOutQuart(_ x: Double) -> Double {
        1 - pow(1 - x, 4)
    }

    private func performTapAnimation() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            isPressed = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Legacy StatCard (for compatibility)

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isLoading: Bool = false

    var body: some View {
        AnimatedStatCard(
            title: title,
            value: Int(value) ?? 0,
            icon: icon,
            gradient: [color, color.opacity(0.7)],
            isLoading: isLoading,
            index: 0,
            hasAppeared: true
        )
    }
}

// MARK: - Animated Activity Row

struct AnimatedActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    let index: Int
    let hasAppeared: Bool

    @State private var isHovered = false

    private var animationDelay: Double {
        0.5 + Double(index) * 0.08
    }

    var body: some View {
        HStack(spacing: 12) {
            // Animated Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Time badge
            Text(time)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        )
        .opacity(hasAppeared ? 1 : 0)
        .offset(x: hasAppeared ? 0 : -30)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8).delay(animationDelay),
            value: hasAppeared
        )
        .onTapGesture {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

// MARK: - Legacy ActivityRow (for compatibility)

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color

    var body: some View {
        AnimatedActivityRow(
            icon: icon,
            title: title,
            subtitle: subtitle,
            time: time,
            color: color,
            index: 0,
            hasAppeared: true
        )
    }
}

// MARK: - Animated Activity Row Placeholder

struct AnimatedActivityRowPlaceholder: View {
    let index: Int

    private var animationDelay: Double {
        Double(index) * 0.1
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 36, height: 36)
                .shimmer()

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 140, height: 14)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 100, height: 10)
                    .shimmer()
            }

            Spacer()

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 50, height: 20)
                .shimmer()
        }
        .padding(.vertical, 8)
    }
}

// Legacy placeholder for compatibility
struct ActivityRowPlaceholder: View {
    var body: some View {
        AnimatedActivityRowPlaceholder(index: 0)
    }
}

// MARK: - Glass Background

struct GlassBackground: View {
    var body: some View {
        ZStack {
            // Base layer
            Color(UIColor.secondarySystemBackground)

            // Glass effect overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
