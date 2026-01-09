import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

enum ClockInError: Error, LocalizedError {
    case notAuthenticated
    case locationNotAvailable
    case locationPermissionDenied
    case noActiveShiftFound
    case firestoreError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to clock in"
        case .locationNotAvailable:
            return "Unable to get your current location"
        case .locationPermissionDenied:
            return "Location permission is required to clock in"
        case .noActiveShiftFound:
            return "No active shift found to clock out"
        case .firestoreError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}

struct ShiftHistoryItem: Identifiable {
    let id: String
    let clockInTime: Date
    let clockOutTime: Date?
    let duration: TimeInterval

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

@MainActor
class ClockInViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isClockedIn = false
    @Published var currentShiftId: String?
    @Published var clockInTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var todayShifts: [ShiftHistoryItem] = []
    @Published var todayTotalHours: TimeInterval = 0

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Dependencies

    private let authService = AuthService.shared
    private let locationService = LocationService.shared
    private let db = Firestore.firestore()

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var activeShiftListener: ListenerRegistration?

    // MARK: - Computed Properties

    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var formattedTodayTotal: String {
        let hours = Int(todayTotalHours) / 3600
        let minutes = (Int(todayTotalHours) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var locationStatusText: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return "Location: Always"
        case .authorizedWhenInUse:
            return "Location: When In Use"
        case .denied, .restricted:
            return "Location: Denied"
        case .notDetermined:
            return "Location: Not Set"
        @unknown default:
            return "Location: Unknown"
        }
    }

    var isLocationAuthorized: Bool {
        locationService.authorizationStatus == .authorizedAlways ||
        locationService.authorizationStatus == .authorizedWhenInUse
    }

    // MARK: - Initialization

    init() {
        setupObservers()
    }

    deinit {
        timer?.invalidate()
        activeShiftListener?.remove()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe location service changes
        locationService.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        locationService.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func initialize() async {
        await checkForActiveShift()
        await fetchTodayShifts()
    }

    func requestLocationPermission() {
        locationService.requestAlwaysAuthorization()
    }

    func clockIn() async {
        guard let user = authService.currentUser, let userId = user.id else {
            showError(ClockInError.notAuthenticated)
            return
        }

        guard isLocationAuthorized else {
            showError(ClockInError.locationPermissionDenied)
            return
        }

        // Request location update if not available
        if locationService.currentLocation == nil {
            locationService.requestAuthorization()
            // Wait briefly for location
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }

        guard let location = locationService.currentLocation else {
            showError(ClockInError.locationNotAvailable)
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let now = Date()
            let coordinates = Coordinates(
                lat: location.coordinate.latitude,
                lng: location.coordinate.longitude
            )

            let locationUpdate = LocationUpdate(
                coordinates: coordinates,
                timestamp: now,
                speed: location.speed >= 0 ? location.speed : nil,
                heading: location.course >= 0 ? location.course : nil
            )

            let routeProgress = RouteProgress(
                currentCommunityId: nil,
                completedCommunityIds: [],
                totalCommunities: 0,
                completedPickups: 0,
                totalPickups: 0
            )

            // Create the active shift document
            let activeShift = ActiveShift(
                id: nil,
                shiftId: UUID().uuidString,
                employeeId: userId,
                routeId: "", // Will be assigned when route is selected
                currentLocation: locationUpdate,
                routeProgress: routeProgress,
                startedAt: now,
                lastUpdated: now
            )

            // Save to Firestore
            let docRef = try db.collection(Constants.Collections.activeShifts).addDocument(from: activeShift)

            // Start location tracking
            try locationService.startTracking(for: docRef.documentID, employeeId: userId)

            // Update local state
            currentShiftId = docRef.documentID
            clockInTime = now
            isClockedIn = true

            // Start the timer
            startTimer()

            // Listen for changes to the active shift
            listenToActiveShift(shiftId: docRef.documentID)

            isLoading = false

        } catch {
            isLoading = false
            showError(ClockInError.firestoreError(underlying: error))
        }
    }

    func clockOut() async {
        guard let shiftId = currentShiftId else {
            showError(ClockInError.noActiveShiftFound)
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let now = Date()
            var clockOutLocation: Coordinates?

            if let location = locationService.currentLocation {
                clockOutLocation = Coordinates(
                    lat: location.coordinate.latitude,
                    lng: location.coordinate.longitude
                )
            }

            // Stop location tracking first
            locationService.stopTracking()

            // Calculate shift duration
            let duration = clockInTime.map { now.timeIntervalSince($0) } ?? 0

            // Update the active shift document with clock out info
            // Note: We store this in a separate shifts collection for history
            if let clockInTime = clockInTime {
                let shiftRecord: [String: Any] = [
                    "employeeId": authService.currentUser?.id ?? "",
                    "companyId": authService.currentUser?.companyId ?? "",
                    "clockInTime": Timestamp(date: clockInTime),
                    "clockOutTime": Timestamp(date: now),
                    "clockInLocation": try? Firestore.Encoder().encode(getCurrentLocationCoordinates()),
                    "clockOutLocation": clockOutLocation.map { try? Firestore.Encoder().encode($0) } ?? NSNull(),
                    "duration": duration,
                    "createdAt": Timestamp(date: now)
                ]

                // Add to shift history
                try await db.collection("shiftHistory").addDocument(data: shiftRecord)
            }

            // Delete the active shift document
            try await db.collection(Constants.Collections.activeShifts).document(shiftId).delete()

            // Stop listening to the active shift
            activeShiftListener?.remove()
            activeShiftListener = nil

            // Stop the timer
            stopTimer()

            // Update local state
            isClockedIn = false
            currentShiftId = nil
            clockInTime = nil
            elapsedTime = 0

            // Refresh today's shifts
            await fetchTodayShifts()

            isLoading = false

        } catch {
            isLoading = false
            showError(ClockInError.firestoreError(underlying: error))
        }
    }

    // MARK: - Private Methods

    private func checkForActiveShift() async {
        guard let userId = authService.currentUser?.id else { return }

        isLoading = true

        do {
            let snapshot = try await db.collection(Constants.Collections.activeShifts)
                .whereField("employeeId", isEqualTo: userId)
                .limit(to: 1)
                .getDocuments()

            if let document = snapshot.documents.first,
               let activeShift = try? document.data(as: ActiveShift.self) {
                // Found an active shift
                currentShiftId = document.documentID
                clockInTime = activeShift.startedAt
                isClockedIn = true

                // Calculate elapsed time
                elapsedTime = Date().timeIntervalSince(activeShift.startedAt)

                // Start the timer
                startTimer()

                // Resume location tracking
                try? locationService.startTracking(for: document.documentID, employeeId: userId)

                // Listen for changes
                listenToActiveShift(shiftId: document.documentID)
            }

            isLoading = false

        } catch {
            isLoading = false
            // Silently fail - user might not have an active shift
        }
    }

    private func fetchTodayShifts() async {
        guard let userId = authService.currentUser?.id else { return }

        // Get start of today
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        do {
            let snapshot = try await db.collection("shiftHistory")
                .whereField("employeeId", isEqualTo: userId)
                .whereField("clockInTime", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("clockInTime", isLessThan: Timestamp(date: endOfDay))
                .order(by: "clockInTime", descending: true)
                .getDocuments()

            var shifts: [ShiftHistoryItem] = []
            var totalDuration: TimeInterval = 0

            for document in snapshot.documents {
                let data = document.data()

                guard let clockInTimestamp = data["clockInTime"] as? Timestamp else { continue }
                let clockInTime = clockInTimestamp.dateValue()

                let clockOutTime = (data["clockOutTime"] as? Timestamp)?.dateValue()
                let duration = data["duration"] as? TimeInterval ?? 0

                let item = ShiftHistoryItem(
                    id: document.documentID,
                    clockInTime: clockInTime,
                    clockOutTime: clockOutTime,
                    duration: duration
                )

                shifts.append(item)
                totalDuration += duration
            }

            // Add current shift duration if clocked in
            if isClockedIn {
                totalDuration += elapsedTime
            }

            todayShifts = shifts
            todayTotalHours = totalDuration

        } catch {
            // Silently fail - might be no history yet
        }
    }

    private func listenToActiveShift(shiftId: String) {
        activeShiftListener?.remove()

        activeShiftListener = db.collection(Constants.Collections.activeShifts)
            .document(shiftId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    Task { @MainActor in
                        self.showError(ClockInError.firestoreError(underlying: error))
                    }
                    return
                }

                // If document was deleted (clocked out from another device)
                if snapshot?.exists == false {
                    Task { @MainActor in
                        self.handleExternalClockOut()
                    }
                }
            }
    }

    private func handleExternalClockOut() {
        stopTimer()
        locationService.stopTracking()

        isClockedIn = false
        currentShiftId = nil
        clockInTime = nil
        elapsedTime = 0

        activeShiftListener?.remove()
        activeShiftListener = nil

        Task {
            await fetchTodayShifts()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let clockInTime = self.clockInTime else { return }
                self.elapsedTime = Date().timeIntervalSince(clockInTime)

                // Update today's total (previous shifts + current)
                let previousTotal = self.todayShifts.reduce(0) { $0 + $1.duration }
                self.todayTotalHours = previousTotal + self.elapsedTime
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func getCurrentLocationCoordinates() -> Coordinates? {
        guard let location = locationService.currentLocation else { return nil }
        return Coordinates(
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude
        )
    }

    private func showError(_ error: ClockInError) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
