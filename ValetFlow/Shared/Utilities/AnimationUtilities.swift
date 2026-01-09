import SwiftUI

// MARK: - Animated List Row Modifier

struct AnimatedListRowModifier: ViewModifier {
    let index: Int
    let isLoaded: Bool

    @State private var isVisible = false
    @State private var isPressed = false

    private var animationDelay: Double {
        Double(index) * 0.05
    }

    func body(content: Content) -> some View {
        content
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
                guard isLoaded else { return }
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

extension View {
    func animatedListRow(index: Int, isLoaded: Bool = true) -> some View {
        modifier(AnimatedListRowModifier(index: index, isLoaded: isLoaded))
    }
}

// MARK: - Card Style Modifier

struct CardStyleModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowOpacity: Double

    init(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 4, shadowOpacity: Double = 0.08) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(shadowOpacity),
                        radius: shadowRadius,
                        x: 0,
                        y: 2
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 4, shadowOpacity: Double = 0.08) -> some View {
        modifier(CardStyleModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius, shadowOpacity: shadowOpacity))
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
                        gradient: Gradient(stops: [
                            .init(color: Color.clear, location: 0),
                            .init(color: Color.white.opacity(0.5), location: 0.5),
                            .init(color: Color.clear, location: 1)
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
                    .linear(duration: 1.5)
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

// MARK: - Skeleton Loading View

struct SkeletonRow: View {
    let index: Int

    @State private var isVisible = false

    private var animationDelay: Double {
        Double(index) * 0.1
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator placeholder
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 10, height: 10)

            // Content placeholders
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 16)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 200, height: 12)

                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 80, height: 10)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 10)
                }
            }

            Spacer()

            // Badge placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 20)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .shimmer()
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .animation(
            .easeOut(duration: 0.3)
            .delay(animationDelay),
            value: isVisible
        )
        .onAppear {
            isVisible = true
        }
    }
}

struct SkeletonLoadingView: View {
    let rowCount: Int

    init(rowCount: Int = 5) {
        self.rowCount = rowCount
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rowCount, id: \.self) { index in
                SkeletonRow(index: index)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Pulsing Status Indicator

struct PulsingStatusIndicator: View {
    let isActive: Bool
    let activeColor: Color
    let inactiveColor: Color

    @State private var isPulsing = false

    init(isActive: Bool, activeColor: Color = .green, inactiveColor: Color = .gray) {
        self.isActive = isActive
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
    }

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .fill(activeColor.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0 : 0.5)
            }

            Circle()
                .fill(isActive ? activeColor : inactiveColor)
                .frame(width: 10, height: 10)
        }
        .onAppear {
            guard isActive else { return }
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }
}

// MARK: - Animated Status Badge

struct AnimatedStatusBadge: View {
    let isActive: Bool
    let activeText: String
    let inactiveText: String
    let activeColor: Color
    let inactiveColor: Color

    @State private var isVisible = false

    init(
        isActive: Bool,
        activeText: String = "Active",
        inactiveText: String = "Inactive",
        activeColor: Color = Constants.Colors.success,
        inactiveColor: Color = Constants.Colors.adminAccent
    ) {
        self.isActive = isActive
        self.activeText = activeText
        self.inactiveText = inactiveText
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
    }

    var body: some View {
        Text(isActive ? activeText : inactiveText)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isActive
                                ? [activeColor, activeColor.opacity(0.8)]
                                : [inactiveColor, inactiveColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - Animated Empty State

struct AnimatedEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let accentColor: Color
    let buttonTitle: String?
    let buttonAction: (() -> Void)?

    @State private var isVisible = false
    @State private var iconRotation: Double = 0

    init(
        icon: String,
        title: String,
        message: String,
        accentColor: Color = Constants.Colors.adminAccent,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.accentColor = accentColor
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isVisible ? 1 : 0.5)

                Image(systemName: icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(iconRotation))
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 30)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    Label(buttonTitle, systemImage: "plus.circle.fill")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(Constants.Colors.adminPrimary)
                .scaleEffect(isVisible ? 1 : 0.8)
                .opacity(isVisible ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            isVisible = true
            withAnimation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                iconRotation = 5
            }
        }
    }
}

// MARK: - Animated Search Empty State

struct AnimatedSearchEmptyState: View {
    let searchText: String
    let accentColor: Color

    @State private var isVisible = false
    @State private var bounce = false

    init(searchText: String, accentColor: Color = Constants.Colors.adminAccent) {
        self.searchText = searchText
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 35, weight: .light))
                    .foregroundColor(accentColor)
                    .offset(y: bounce ? -3 : 3)
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.5)

            Text("No Results")
                .font(.title3)
                .fontWeight(.semibold)
                .opacity(isVisible ? 1 : 0)

            Text("No matches for \"\(searchText)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .opacity(isVisible ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            isVisible = true
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                bounce = true
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Constants.Colors.adminPrimary : Color(.systemGray6))
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Swipe Action Button

struct SwipeActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isVisible = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .scaleEffect(isVisible ? 1 : 0.5)
                    .rotationEffect(.degrees(isVisible ? 0 : -90))

                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .opacity(isVisible ? 1 : 0)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Content Transition Extensions

extension View {
    @ViewBuilder
    func animatedContent<T: Equatable>(
        trigger: T,
        transition: AnyTransition = .opacity.combined(with: .scale(scale: 0.95))
    ) -> some View {
        self
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: trigger)
            .transition(transition)
    }
}

// MARK: - Previews

#Preview("Skeleton Loading") {
    SkeletonLoadingView(rowCount: 5)
}

#Preview("Empty State") {
    AnimatedEmptyState(
        icon: "person.3.fill",
        title: "No Employees",
        message: "Add employees to start managing your team",
        buttonTitle: "Add Employee",
        buttonAction: {}
    )
}

#Preview("Search Empty State") {
    AnimatedSearchEmptyState(searchText: "John")
}

#Preview("Status Indicators") {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            PulsingStatusIndicator(isActive: true)
            PulsingStatusIndicator(isActive: false)
        }

        HStack(spacing: 20) {
            AnimatedStatusBadge(isActive: true)
            AnimatedStatusBadge(isActive: false)
        }
    }
    .padding()
}
