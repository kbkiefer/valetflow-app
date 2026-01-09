import SwiftUI

// MARK: - Animation Constants

enum AnimationConstants {
    static let standardDuration: Double = 0.35
    static let quickDuration: Double = 0.2
    static let slowDuration: Double = 0.5
    static let springResponse: Double = 0.55
    static let springDamping: Double = 0.7

    static let standardSpring = Animation.spring(response: springResponse, dampingFraction: springDamping)
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let bouncySpring = Animation.spring(response: 0.5, dampingFraction: 0.6)
}

// MARK: - Animated Status Badge

struct AnimatedStatusBadge: View {
    let isActive: Bool
    let activeText: String
    let inactiveText: String

    @State private var isPulsing = false

    init(isActive: Bool, activeText: String = "Active", inactiveText: String = "Inactive") {
        self.isActive = isActive
        self.activeText = activeText
        self.inactiveText = inactiveText
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing && isActive ? 1.3 : 1.0)
                .animation(
                    isActive ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                    value: isPulsing
                )

            Text(isActive ? activeText : inactiveText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isActive ? .green : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isActive ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
        )
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Animated Section Header

struct AnimatedSectionHeader: View {
    let title: String
    let icon: String?
    let isExpanded: Binding<Bool>?
    var delay: Double = 0

    @State private var hasAppeared = false

    init(title: String, icon: String? = nil, isExpanded: Binding<Bool>? = nil, delay: Double = 0) {
        self.title = title
        self.icon = icon
        self.isExpanded = isExpanded
        self.delay = delay
    }

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.adminPrimary)
            }

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()

            if let binding = isExpanded {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(binding.wrappedValue ? 90 : 0))
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(x: hasAppeared ? 0 : -20)
        .onAppear {
            withAnimation(AnimationConstants.standardSpring.delay(delay)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Floating Label Text Field

struct FloatingLabelTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences

    @FocusState private var isFocused: Bool
    @State private var hasAppeared = false

    private var isFloating: Bool {
        isFocused || !text.isEmpty
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Floating label
            Text(title)
                .font(isFloating ? .caption : .body)
                .foregroundColor(isFocused ? Constants.Colors.adminPrimary : .secondary)
                .offset(y: isFloating ? -24 : 0)
                .scaleEffect(isFloating ? 0.85 : 1, anchor: .leading)

            // Text field
            TextField("", text: $text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .focused($isFocused)
                .offset(y: 4)
        }
        .padding(.top, 16)
        .animation(AnimationConstants.quickSpring, value: isFloating)
        .animation(AnimationConstants.quickSpring, value: isFocused)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(isFocused ? Constants.Colors.adminPrimary : Color.gray.opacity(0.3))
                .frame(height: isFocused ? 2 : 1)
                .scaleEffect(x: isFocused ? 1 : 0.97, anchor: .center)
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 10)
        .onAppear {
            withAnimation(AnimationConstants.standardSpring) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Animated Toggle

struct AnimatedToggle: View {
    let title: String
    @Binding var isOn: Bool
    var icon: String? = nil

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(isOn ? Constants.Colors.adminPrimary : .secondary)
                    .symbolEffect(.bounce, value: isOn)
            }

            Text(title)
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Constants.Colors.adminPrimary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(AnimationConstants.quickSpring) {
                isOn.toggle()
            }
        }
    }
}

// MARK: - Animated Save Button

struct AnimatedSaveButton: View {
    enum State {
        case idle
        case loading
        case success
        case error
    }

    let title: String
    let state: State
    let action: () -> Void

    @SwiftUI.State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                switch state {
                case .idle:
                    Text(title)
                        .fontWeight(.semibold)
                        .transition(.scale.combined(with: .opacity))

                case .loading:
                    ProgressView()
                        .tint(.white)
                        .transition(.scale.combined(with: .opacity))
                    Text("Saving...")
                        .fontWeight(.semibold)
                        .transition(.scale.combined(with: .opacity))

                case .success:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                    Text("Saved!")
                        .fontWeight(.semibold)
                        .transition(.scale.combined(with: .opacity))

                case .error:
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                    Text("Error")
                        .fontWeight(.semibold)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .disabled(state == .loading)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(AnimationConstants.standardSpring, value: state)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var backgroundColor: Color {
        switch state {
        case .idle, .loading: return Constants.Colors.adminPrimary
        case .success: return Constants.Colors.success
        case .error: return Constants.Colors.error
        }
    }
}

// MARK: - Shake Effect Modifier

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * shakesPerUnit), y: 0))
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shakeAmount: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.linear(duration: 0.5)) {
                        shakeAmount = 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        shakeAmount = 0
                    }
                }
            }
    }
}

// MARK: - Staggered Animation Modifier

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .onAppear {
                withAnimation(AnimationConstants.standardSpring.delay(baseDelay + Double(index) * 0.08)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int, baseDelay: Double = 0.1) -> some View {
        modifier(StaggeredAppearModifier(index: index, baseDelay: baseDelay))
    }
}

// MARK: - Card Style Section

struct CardSection<Content: View>: View {
    let content: Content
    var delay: Double = 0

    @State private var hasAppeared = false

    init(delay: Double = 0, @ViewBuilder content: () -> Content) {
        self.delay = delay
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 15)
            .onAppear {
                withAnimation(AnimationConstants.standardSpring.delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

// MARK: - Gradient Header

struct GradientHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let isActive: Bool

    @State private var hasAppeared = false

    init(title: String, subtitle: String? = nil, icon: String? = nil, isActive: Bool = true) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isActive = isActive
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Constants.Colors.adminPrimary,
                        Constants.Colors.adminPrimary.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Content
                VStack(spacing: 12) {
                    if let icon = icon {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: icon)
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(hasAppeared ? 1 : 0.5)
                        .opacity(hasAppeared ? 1 : 0)
                    }

                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .offset(y: hasAppeared ? 0 : 20)
                        .opacity(hasAppeared ? 1 : 0)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .offset(y: hasAppeared ? 0 : 20)
                            .opacity(hasAppeared ? 1 : 0)
                    }

                    AnimatedStatusBadge(isActive: isActive)
                        .scaleEffect(hasAppeared ? 1 : 0.8)
                        .opacity(hasAppeared ? 1 : 0)
                }
                .padding(.vertical, 24)
            }
            .frame(height: 200)
            .clipShape(
                RoundedCorner(radius: 24, corners: [.bottomLeft, .bottomRight])
            )
        }
        .onAppear {
            withAnimation(AnimationConstants.standardSpring.delay(0.1)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Rounded Corner Shape

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Unsaved Changes Indicator

struct UnsavedChangesIndicator: View {
    let hasChanges: Bool

    @State private var isPulsing = false

    var body: some View {
        if hasChanges {
            HStack(spacing: 6) {
                Circle()
                    .fill(Constants.Colors.warning)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isPulsing ? 1.2 : 1)

                Text("Unsaved changes")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.warning)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Constants.Colors.warning.opacity(0.15))
            )
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
}

// MARK: - Animated Delete Button

struct AnimatedDeleteButton: View {
    let title: String
    let isDeleting: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var shakeAmount: CGFloat = 0

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isDeleting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "trash.fill")
                        .symbolEffect(.bounce, value: isPressed)
                }

                Text(isDeleting ? "Deleting..." : title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Constants.Colors.error)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDeleting)
        .modifier(ShakeEffect(animatableData: shakeAmount))
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    func triggerShake() {
        withAnimation(.linear(duration: 0.5)) {
            shakeAmount = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shakeAmount = 0
        }
    }
}

// MARK: - Expandable Section

struct ExpandableSection<Header: View, Content: View>: View {
    @Binding var isExpanded: Bool
    let header: Header
    let content: Content

    init(isExpanded: Binding<Bool>, @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self._isExpanded = isExpanded
        self.header = header()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(AnimationConstants.standardSpring) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    header
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    enum ToastType {
        case success
        case error
        case warning
        case info
    }

    let message: String
    let type: ToastType
    let isShowing: Bool

    var body: some View {
        if isShowing {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title3)

                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .clipShape(Capsule())
            .shadow(color: backgroundColor.opacity(0.3), radius: 10, x: 0, y: 5)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var iconName: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var backgroundColor: Color {
        switch type {
        case .success: return Constants.Colors.success
        case .error: return Constants.Colors.error
        case .warning: return Constants.Colors.warning
        case .info: return Constants.Colors.adminPrimary
        }
    }
}

// MARK: - Mode Transition Container

struct ModeTransitionContainer<ViewContent: View, EditContent: View>: View {
    let isEditMode: Bool
    let viewContent: ViewContent
    let editContent: EditContent

    @Namespace private var animation

    init(isEditMode: Bool, @ViewBuilder viewContent: () -> ViewContent, @ViewBuilder editContent: () -> EditContent) {
        self.isEditMode = isEditMode
        self.viewContent = viewContent()
        self.editContent = editContent()
    }

    var body: some View {
        ZStack {
            if isEditMode {
                editContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
            } else {
                viewContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
            }
        }
        .animation(AnimationConstants.standardSpring, value: isEditMode)
    }
}

// MARK: - Avatar View

struct AvatarView: View {
    let initials: String
    let size: CGFloat
    var backgroundColor: Color = Constants.Colors.adminPrimary

    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [backgroundColor, backgroundColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .scaleEffect(hasAppeared ? 1 : 0.5)
        .opacity(hasAppeared ? 1 : 0)
        .onAppear {
            withAnimation(AnimationConstants.bouncySpring.delay(0.2)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Info Row

struct AnimatedInfoRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var delay: Double = 0

    @State private var hasAppeared = false

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(Constants.Colors.adminPrimary)
                    .frame(width: 24)
            }

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
        .opacity(hasAppeared ? 1 : 0)
        .offset(x: hasAppeared ? 0 : 20)
        .onAppear {
            withAnimation(AnimationConstants.standardSpring.delay(delay)) {
                hasAppeared = true
            }
        }
    }
}
