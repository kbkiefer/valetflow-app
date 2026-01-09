import SwiftUI

// MARK: - Clock In View with Premium Animations

struct ClockInView: View {
    @StateObject private var viewModel = ClockInViewModel()
    @StateObject private var locationService = LocationService.shared

    // Animation States
    @State private var showConfetti = false
    @State private var clockInSuccess = false
    @State private var clockOutSuccess = false
    @State private var cardAppeared = false
    @State private var backgroundPhase: Double = 0
    @State private var pulsePhase: Double = 0

    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                animatedBackground

                ScrollView {
                    VStack(spacing: 24) {
                        // Status Card with animations
                        statusCard
                            .offset(y: cardAppeared ? 0 : -50)
                            .opacity(cardAppeared ? 1 : 0)

                        // Clock In/Out Button
                        clockButton
                            .offset(y: cardAppeared ? 0 : 50)
                            .opacity(cardAppeared ? 1 : 0)

                        // Elapsed Time (when clocked in)
                        if viewModel.isClockedIn {
                            elapsedTimeCard
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }

                        // Location Status
                        locationStatusCard
                            .offset(y: cardAppeared ? 0 : 30)
                            .opacity(cardAppeared ? 1 : 0)

                        // Today's Summary
                        todaySummaryCard
                            .offset(y: cardAppeared ? 0 : 30)
                            .opacity(cardAppeared ? 1 : 0)

                        // Today's Shifts List
                        if !viewModel.todayShifts.isEmpty {
                            todayShiftsCard
                        }

                        Spacer(minLength: 20)
                    }
                    .padding()
                }

                // Confetti Overlay
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // Success Burst Overlay
                if clockInSuccess {
                    SuccessBurstView(color: Constants.Colors.success)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Clock In/Out")
            .task {
                await viewModel.initialize()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    cardAppeared = true
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
        }
    }

    // MARK: - Animated Background

    private var animatedBackground: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                // Create subtle gradient animation
                let gradientColors: [Color] = viewModel.isClockedIn
                    ? [Constants.Colors.success.opacity(0.05), Constants.Colors.fieldPrimary.opacity(0.08)]
                    : [Constants.Colors.fieldPrimary.opacity(0.05), Color.purple.opacity(0.05)]

                let offset = sin(phase * 0.3) * 50

                let gradient = Gradient(colors: gradientColors)
                let startPoint = CGPoint(x: size.width / 2 + offset, y: 0)
                let endPoint = CGPoint(x: size.width / 2 - offset, y: size.height)

                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(gradient, startPoint: startPoint, endPoint: endPoint)
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Status Card with Animations

    private var statusCard: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate

            VStack(spacing: 12) {
                // Animated Icon
                ZStack {
                    // Glow effect
                    if viewModel.isClockedIn {
                        Circle()
                            .fill(Constants.Colors.success.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .blur(radius: 20)
                            .scaleEffect(1.0 + sin(phase * 2) * 0.1)
                    }

                    Image(systemName: viewModel.isClockedIn ? "clock.badge.checkmark.fill" : "clock.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            viewModel.isClockedIn
                                ? Constants.Colors.success
                                : Constants.Colors.fieldPrimary
                        )
                        .symbolEffect(.bounce, value: viewModel.isClockedIn)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                }
                .animation(.spring(response: 0.5), value: viewModel.isClockedIn)

                Text(viewModel.isClockedIn ? "Currently Clocked In" : "Currently Clocked Out")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())

                if let clockInTime = viewModel.clockInTime {
                    Text("Since \(clockInTime, style: .time)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .transition(.push(from: .bottom))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: viewModel.isClockedIn
                            ? Constants.Colors.success.opacity(0.2 + sin(phase * 2) * 0.1)
                            : .black.opacity(0.1),
                        radius: viewModel.isClockedIn ? 12 : 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        viewModel.isClockedIn
                            ? Constants.Colors.success.opacity(0.3)
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .animation(.spring(response: 0.6), value: viewModel.isClockedIn)
    }

    // MARK: - Clock Button with Premium Animations

    private var clockButton: some View {
        ClockButtonView(
            isClockedIn: viewModel.isClockedIn,
            isLoading: viewModel.isLoading,
            onTap: {
                Task {
                    if viewModel.isClockedIn {
                        await viewModel.clockOut()
                        triggerClockOutAnimation()
                    } else {
                        await viewModel.clockIn()
                        triggerClockInAnimation()
                    }
                }
            }
        )
    }

    private func triggerClockInAnimation() {
        withAnimation(.spring(response: 0.3)) {
            clockInSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                clockInSuccess = false
            }
        }
    }

    private func triggerClockOutAnimation() {
        withAnimation(.spring(response: 0.3)) {
            showConfetti = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showConfetti = false
            }
        }
    }

    // MARK: - Elapsed Time Card with Flip Animation

    private var elapsedTimeCard: some View {
        AnimatedTimerCard(
            formattedTime: viewModel.formattedElapsedTime,
            clockInTime: viewModel.clockInTime
        )
    }

    // MARK: - Location Status Card with Animations

    private var locationStatusCard: some View {
        HStack {
            // Animated Location Pin
            ZStack {
                if locationService.isTracking {
                    // Radar waves
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(locationStatusColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 32, height: 32)
                            .scaleEffect(radarScale(for: index))
                            .opacity(radarOpacity(for: index))
                    }
                }

                Image(systemName: locationStatusIcon)
                    .font(.title3)
                    .foregroundColor(locationStatusColor)
                    .symbolEffect(.pulse, isActive: locationService.isTracking)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.locationStatusText)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if locationService.isTracking {
                    // Location accuracy progress bar
                    LocationAccuracyBar(accuracy: locationService.currentLocation?.horizontalAccuracy ?? 100)
                } else if !viewModel.isLocationAuthorized {
                    Button("Enable Location") {
                        viewModel.requestLocationPermission()
                    }
                    .font(.caption)
                    .foregroundColor(Constants.Colors.fieldPrimary)
                }
            }

            Spacer()

            if locationService.isTracking {
                TrackingIndicator()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func radarScale(for index: Int) -> CGFloat {
        let baseScale: CGFloat = 1.0
        let maxScale: CGFloat = 2.5
        let phase = (Date().timeIntervalSinceReferenceDate + Double(index) * 0.4).truncatingRemainder(dividingBy: 1.2) / 1.2
        return baseScale + (maxScale - baseScale) * phase
    }

    private func radarOpacity(for index: Int) -> Double {
        let phase = (Date().timeIntervalSinceReferenceDate + Double(index) * 0.4).truncatingRemainder(dividingBy: 1.2) / 1.2
        return 1.0 - phase
    }

    private var locationStatusIcon: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "location.fill"
        case .denied, .restricted:
            return "location.slash.fill"
        case .notDetermined:
            return "location.circle"
        @unknown default:
            return "location.circle"
        }
    }

    private var locationStatusColor: Color {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return Constants.Colors.success
        case .denied, .restricted:
            return Constants.Colors.error
        case .notDetermined:
            return Constants.Colors.warning
        @unknown default:
            return .secondary
        }
    }

    // MARK: - Today's Summary Card

    private var todaySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Constants.Colors.fieldPrimary)
                    .symbolEffect(.bounce, value: viewModel.todayShifts.count)
                Text("Today's Summary")
                    .font(.headline)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.formattedTodayTotal)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Shifts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.todayShifts.count + (viewModel.isClockedIn ? 1 : 0))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Today's Shifts Card with Staggered Animation

    private var todayShiftsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundColor(Constants.Colors.fieldPrimary)
                Text("Today's Shifts")
                    .font(.headline)
            }

            Divider()

            ForEach(Array(viewModel.todayShifts.enumerated()), id: \.element.id) { index, shift in
                AnimatedShiftRow(
                    shift: shift,
                    isLast: shift.id == viewModel.todayShifts.last?.id,
                    delay: Double(index) * 0.1
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Custom animated loader
                LoadingSpinner()

                Text(viewModel.isClockedIn ? "Clocking out..." : "Clocking in...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
        .transition(.opacity)
    }
}

// MARK: - Clock Button Component

struct ClockButtonView: View {
    let isClockedIn: Bool
    let isLoading: Bool
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var pulsePhase: Double = 0
    @State private var progressValue: Double = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.02)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate

            Button {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()

                onTap()
            } label: {
                ZStack {
                    // Pulsing glow when ready to clock in
                    if !isClockedIn && !isLoading {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Constants.Colors.fieldPrimary.opacity(0.3))
                            .blur(radius: 20)
                            .scaleEffect(1.05 + sin(phase * 3) * 0.05)
                    }

                    // Circular progress ring around button
                    if isClockedIn {
                        CircularProgressRing(progress: progressValue)
                            .frame(width: 280, height: 70)
                    }

                    // Main button content
                    HStack(spacing: 12) {
                        Image(systemName: isClockedIn ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .symbolEffect(.bounce, value: isClockedIn)
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))

                        Text(isClockedIn ? "Clock Out" : "Clock In")
                            .font(.title2)
                            .fontWeight(.bold)
                            .contentTransition(.numericText())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: isClockedIn
                                        ? [Constants.Colors.error, Constants.Colors.error.opacity(0.8)]
                                        : [Constants.Colors.fieldPrimary, Constants.Colors.fieldPrimary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: (isClockedIn ? Constants.Colors.error : Constants.Colors.fieldPrimary).opacity(0.4),
                                radius: isPressed ? 4 : 12,
                                x: 0,
                                y: isPressed ? 2 : 6
                            )
                    )
                }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .disabled(isLoading)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            // Haptic for press
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
            .onAppear {
                // Animate progress when clocked in
                if isClockedIn {
                    withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                        progressValue = 1.0
                    }
                }
            }
            .onChange(of: isClockedIn) { _, newValue in
                if newValue {
                    progressValue = 0
                    withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                        progressValue = 1.0
                    }
                    // Success haptic
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                } else {
                    progressValue = 0
                }
            }
        }
    }
}

// MARK: - Circular Progress Ring

struct CircularProgressRing: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let cornerRadius: CGFloat = 16

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Constants.Colors.error.opacity(0.2), lineWidth: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .trim(from: 0, to: progress)
                        .stroke(
                            Constants.Colors.error,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                )
                .frame(width: width, height: height)
        }
    }
}

// MARK: - Animated Timer Card

struct AnimatedTimerCard: View {
    let formattedTime: String
    let clockInTime: Date?

    @State private var previousTime: String = ""
    @State private var isGlowing = false
    @State private var minutePulse = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.5)) { timeline in
            VStack(spacing: 8) {
                Text("Shift Duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Animated timer display
                HStack(spacing: 2) {
                    ForEach(Array(formattedTime.enumerated()), id: \.offset) { index, char in
                        TimerDigit(character: char, index: index)
                    }
                }
                .scaleEffect(minutePulse ? 1.02 : 1.0)
                .animation(.spring(response: 0.3), value: minutePulse)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Constants.Colors.fieldPrimary.opacity(0.1))

                    // Glow effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Constants.Colors.fieldPrimary.opacity(isGlowing ? 0.15 : 0.1))
                        .blur(radius: 10)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Constants.Colors.fieldPrimary.opacity(0.3), lineWidth: 1)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
            .onChange(of: formattedTime) { oldValue, newValue in
                // Check if minute changed (format is HH:MM:SS)
                let oldMinute = oldValue.dropFirst(3).prefix(2)
                let newMinute = newValue.dropFirst(3).prefix(2)
                if oldMinute != newMinute {
                    withAnimation(.spring(response: 0.2)) {
                        minutePulse = true
                    }
                    // Haptic for minute change
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            minutePulse = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Timer Digit with Flip Animation

struct TimerDigit: View {
    let character: Character
    let index: Int

    @State private var flip = false

    var body: some View {
        Text(String(character))
            .font(.system(size: 48, weight: .bold, design: .monospaced))
            .foregroundColor(Constants.Colors.fieldPrimary)
            .rotation3DEffect(
                .degrees(flip ? 0 : 360),
                axis: (x: 1, y: 0, z: 0)
            )
            .onChange(of: character) { _, _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    flip.toggle()
                }
            }
    }
}

// MARK: - Location Accuracy Bar

struct LocationAccuracyBar: View {
    let accuracy: Double

    private var normalizedAccuracy: Double {
        // 0 = best (green), 100+ = worst (red)
        min(max(1 - (accuracy / 100), 0), 1)
    }

    private var accuracyColor: Color {
        if accuracy < 10 {
            return Constants.Colors.success
        } else if accuracy < 50 {
            return Constants.Colors.warning
        } else {
            return Constants.Colors.error
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Accuracy: \(Int(accuracy))m")
                .font(.caption2)
                .foregroundColor(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(accuracyColor)
                        .frame(width: geometry.size.width * normalizedAccuracy)
                        .animation(.spring(response: 0.5), value: normalizedAccuracy)
                }
            }
            .frame(height: 4)
        }
        .frame(width: 100)
    }
}

// MARK: - Tracking Indicator

struct TrackingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Constants.Colors.success)
                .frame(width: 12, height: 12)

            Circle()
                .stroke(Constants.Colors.success.opacity(0.5), lineWidth: 2)
                .frame(width: 12, height: 12)
                .scaleEffect(isAnimating ? 2 : 1)
                .opacity(isAnimating ? 0 : 1)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Animated Shift Row

struct AnimatedShiftRow: View {
    let shift: ShiftHistoryItem
    let isLast: Bool
    let delay: Double

    @State private var appeared = false
    @State private var durationFill: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                // Timeline connector
                VStack(spacing: 0) {
                    Circle()
                        .fill(Constants.Colors.fieldPrimary)
                        .frame(width: 10, height: 10)

                    if !isLast {
                        Rectangle()
                            .fill(Constants.Colors.fieldPrimary.opacity(0.3))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(shift.clockInTime, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let clockOutTime = shift.clockOutTime {
                        Text("to \(clockOutTime, style: .time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Animated duration bar
                VStack(alignment: .trailing, spacing: 4) {
                    Text(shift.formattedDuration)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Constants.Colors.fieldPrimary)

                    // Duration bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Constants.Colors.fieldPrimary.opacity(0.2))

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Constants.Colors.fieldPrimary)
                                .frame(width: geometry.size.width * durationFill)
                        }
                    }
                    .frame(width: 60, height: 4)
                }
            }
            .padding(.vertical, 8)
            .offset(x: appeared ? 0 : 50)
            .opacity(appeared ? 1 : 0)

            if !isLast {
                Divider()
                    .padding(.leading, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(delay + 0.3)) {
                durationFill = min(CGFloat(shift.duration ?? 0) / (8 * 3600), 1.0) // Normalize to 8-hour day
            }
        }
    }
}

// MARK: - Loading Spinner

struct LoadingSpinner: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                .frame(width: 50, height: 50)

            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Success Burst View

struct SuccessBurstView: View {
    let color: Color

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            // Multiple expanding rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 4)
                    .scaleEffect(scale + CGFloat(index) * 0.2)
                    .opacity(opacity)
            }

            // Center burst
            Circle()
                .fill(color.opacity(0.3))
                .scaleEffect(scale * 0.5)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 3
                opacity = 0
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let currentTime = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let age = currentTime - particle.startTime
                    if age < particle.lifetime {
                        let progress = age / particle.lifetime

                        // Physics simulation
                        let x = particle.startX + particle.velocityX * age
                        let y = particle.startY + particle.velocityY * age + 0.5 * 500 * age * age // Gravity
                        let rotation = particle.rotation + particle.rotationSpeed * age
                        let alpha = 1.0 - progress

                        var contextCopy = context
                        contextCopy.translateBy(x: x, y: y)
                        contextCopy.rotate(by: .degrees(rotation))
                        contextCopy.opacity = alpha

                        let rect = CGRect(x: -particle.size/2, y: -particle.size/2, width: particle.size, height: particle.size)

                        if particle.isCircle {
                            contextCopy.fill(Circle().path(in: rect), with: .color(particle.color))
                        } else {
                            contextCopy.fill(Rectangle().path(in: rect), with: .color(particle.color))
                        }
                    }
                }
            }
        }
        .onAppear {
            createParticles()
        }
    }

    private func createParticles() {
        let colors: [Color] = [
            Constants.Colors.fieldPrimary,
            Constants.Colors.success,
            .orange,
            .pink,
            .purple,
            .yellow
        ]

        let currentTime = Date().timeIntervalSinceReferenceDate
        let screenWidth = UIScreen.main.bounds.width

        particles = (0..<50).map { _ in
            ConfettiParticle(
                startX: screenWidth / 2 + CGFloat.random(in: -50...50),
                startY: 300,
                velocityX: CGFloat.random(in: -200...200),
                velocityY: CGFloat.random(in: -600 ... -300),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -360...360),
                size: CGFloat.random(in: 8...16),
                color: colors.randomElement() ?? .blue,
                isCircle: Bool.random(),
                lifetime: Double.random(in: 1.5...2.5),
                startTime: currentTime
            )
        }
    }
}

struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let rotation: Double
    let rotationSpeed: Double
    let size: CGFloat
    let color: Color
    let isCircle: Bool
    let lifetime: Double
    let startTime: TimeInterval
}

// MARK: - Previews

#Preview("Clocked Out") {
    ClockInView()
}

#Preview("Clocked In") {
    ClockInView()
}
