import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

enum LocationServiceError: Error, LocalizedError {
    case authorizationDenied
    case locationUpdateFailed(underlying: Error)
    case firebaseUpdateFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Location authorization not granted"
        case .locationUpdateFailed(let error):
            return "Location update failed: \(error.localizedDescription)"
        case .firebaseUpdateFailed(let error):
            return "Failed to update location in Firebase: \(error.localizedDescription)"
        }
    }
}

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    @Published var lastError: LocationServiceError?

    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    private var locationUpdateTimer: Timer?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    deinit {
        stopTracking()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Location Tracking

    func startTracking(for shiftId: String, employeeId: String) throws {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            let error = LocationServiceError.authorizationDenied
            lastError = error
            throw error
        }

        locationManager.startUpdatingLocation()
        isTracking = true

        // Update Firebase every 15 seconds
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            guard let self = self, let location = self.currentLocation else { return }

            Task {
                await self.updateLocationInFirebase(
                    shiftId: shiftId,
                    employeeId: employeeId,
                    location: location
                )
            }
        }
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        isTracking = false
    }

    // MARK: - Firebase Updates

    private func updateLocationInFirebase(shiftId: String, employeeId: String, location: CLLocation) async {
        let locationUpdate = LocationUpdate(
            coordinates: Coordinates(lat: location.coordinate.latitude, lng: location.coordinate.longitude),
            timestamp: Date(),
            speed: location.speed >= 0 ? location.speed : nil,
            heading: location.course >= 0 ? location.course : nil
        )

        do {
            try await db.collection("activeShifts").document(shiftId).updateData([
                "currentLocation": try Firestore.Encoder().encode(locationUpdate),
                "lastUpdated": FieldValue.serverTimestamp()
            ])
            lastError = nil
        } catch {
            let wrappedError = LocationServiceError.firebaseUpdateFailed(underlying: error)
            lastError = wrappedError
            // Error is stored in lastError for UI observation
        }
    }

    // MARK: - Distance Calculation

    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    func isNearby(userLocation: CLLocationCoordinate2D, targetLocation: CLLocationCoordinate2D, threshold: Double = 500) -> Bool {
        return distance(from: userLocation, to: targetLocation) <= threshold
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = LocationServiceError.locationUpdateFailed(underlying: error)
        }
    }
}
