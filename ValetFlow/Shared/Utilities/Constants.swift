import Foundation
import SwiftUI

enum Constants {
    // MARK: - Firebase Collections
    enum Collections {
        static let users = "users"
        static let companies = "companies"
        static let employees = "employees"
        static let communities = "communities"
        static let routes = "routes"
        static let shifts = "shifts"
        static let activeShifts = "activeShifts"
        static let pickups = "pickups"
        static let issues = "issues"
        static let notifications = "notifications"
    }

    // MARK: - User Defaults Keys
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastKnownRole = "lastKnownRole"
        static let fcmToken = "fcmToken"
    }

    // MARK: - Notification Names
    enum NotificationNames {
        static let driverNearby = "driverNearby"
        static let pickupComplete = "pickupComplete"
        static let missedPickup = "missedPickup"
        static let scheduleChange = "scheduleChange"
    }

    // MARK: - GPS Tracking
    enum GPS {
        static let nearbyThresholdMeters: Double = 500 // 500 meters
        static let locationUpdateIntervalSeconds: Double = 15
        static let minimumDistanceFilter: Double = 10 // 10 meters
    }

    // MARK: - App Colors
    enum Colors {
        // Admin App
        static let adminPrimary = Color.blue
        static let adminAccent = Color.gray

        // Field App
        static let fieldPrimary = Color.green
        static let fieldAccent = Color.orange

        // Community App
        static let communityPrimary = Color.teal
        static let communityAccent = Color.purple

        // Shared
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
    }
}
