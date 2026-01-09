import SwiftUI

struct ClockInView: View {
    @StateObject private var viewModel = ClockInViewModel()
    @StateObject private var locationService = LocationService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Card
                    statusCard

                    // Clock In/Out Button
                    clockButton

                    // Elapsed Time (when clocked in)
                    if viewModel.isClockedIn {
                        elapsedTimeCard
                    }

                    // Location Status
                    locationStatusCard

                    // Today's Summary
                    todaySummaryCard

                    // Today's Shifts List
                    if !viewModel.todayShifts.isEmpty {
                        todayShiftsCard
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Clock In/Out")
            .task {
                await viewModel.initialize()
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

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.isClockedIn ? "clock.badge.checkmark.fill" : "clock.fill")
                .font(.system(size: 48))
                .foregroundColor(viewModel.isClockedIn ? Constants.Colors.success : Constants.Colors.fieldPrimary)

            Text(viewModel.isClockedIn ? "Currently Clocked In" : "Currently Clocked Out")
                .font(.title2)
                .fontWeight(.semibold)

            if let clockInTime = viewModel.clockInTime {
                Text("Since \(clockInTime, style: .time)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Clock Button

    private var clockButton: some View {
        Button {
            Task {
                if viewModel.isClockedIn {
                    await viewModel.clockOut()
                } else {
                    await viewModel.clockIn()
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isClockedIn ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)

                Text(viewModel.isClockedIn ? "Clock Out" : "Clock In")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.isClockedIn ? Constants.Colors.error : Constants.Colors.fieldPrimary)
            )
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Elapsed Time Card

    private var elapsedTimeCard: some View {
        VStack(spacing: 8) {
            Text("Shift Duration")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(viewModel.formattedElapsedTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(Constants.Colors.fieldPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.fieldPrimary.opacity(0.1))
        )
    }

    // MARK: - Location Status Card

    private var locationStatusCard: some View {
        HStack {
            Image(systemName: locationStatusIcon)
                .font(.title3)
                .foregroundColor(locationStatusColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.locationStatusText)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if locationService.isTracking {
                    Text("GPS tracking active")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                Circle()
                    .fill(Constants.Colors.success)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Constants.Colors.success.opacity(0.3), lineWidth: 4)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
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
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Shifts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.todayShifts.count + (viewModel.isClockedIn ? 1 : 0))")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Today's Shifts Card

    private var todayShiftsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundColor(Constants.Colors.fieldPrimary)
                Text("Today's Shifts")
                    .font(.headline)
            }

            Divider()

            ForEach(viewModel.todayShifts) { shift in
                shiftRow(shift)

                if shift.id != viewModel.todayShifts.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func shiftRow(_ shift: ShiftHistoryItem) -> some View {
        HStack {
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

            Text(shift.formattedDuration)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Constants.Colors.fieldPrimary)
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(viewModel.isClockedIn ? "Clocking out..." : "Clocking in...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray))
            )
        }
    }
}

#Preview("Clocked Out") {
    ClockInView()
}

#Preview("Clocked In") {
    ClockInView()
}
