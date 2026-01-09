import Foundation
import SwiftUI

/// Filter options for routes list
enum RouteFilterOption: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case inactive = "Inactive"
}

@MainActor
class RoutesListViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var routes: [Route] = []
    @Published var searchText = ""
    @Published var filterOption: RouteFilterOption = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Private Properties

    private let firebaseService = FirebaseService.shared

    // MARK: - Computed Properties

    var filteredRoutes: [Route] {
        var result = routes

        // Apply filter
        switch filterOption {
        case .all:
            break
        case .active:
            result = result.filter { $0.isActive }
        case .inactive:
            result = result.filter { !$0.isActive }
        }

        // Apply search
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { route in
                route.name.lowercased().contains(searchLower) ||
                route.description.lowercased().contains(searchLower)
            }
        }

        return result
    }

    var hasNoRoutes: Bool {
        !isLoading && routes.isEmpty
    }

    var hasNoSearchResults: Bool {
        !isLoading && !routes.isEmpty && filteredRoutes.isEmpty
    }

    // MARK: - Public Methods

    func loadRoutes() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedRoutes: [Route] = try await firebaseService.fetchAll(
                collection: Constants.Collections.routes
            )
            routes = fetchedRoutes.sorted { $0.name < $1.name }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func deleteRoute(_ route: Route) async {
        guard let routeId = route.id else {
            errorMessage = "Cannot delete route: missing ID"
            showError = true
            return
        }

        do {
            try await firebaseService.delete(
                collection: Constants.Collections.routes,
                documentId: routeId
            )
            routes.removeAll { $0.id == routeId }
        } catch {
            errorMessage = "Failed to delete route: \(error.localizedDescription)"
            showError = true
        }
    }

    func refresh() async {
        await loadRoutes()
    }

    // MARK: - Helper Methods

    /// Formats the scheduled days for display
    func formattedSchedule(for route: Route) -> String {
        guard !route.scheduledDays.isEmpty else {
            return "No schedule"
        }

        // Abbreviate day names for compact display
        let abbreviations: [String: String] = [
            "Monday": "Mon",
            "Tuesday": "Tue",
            "Wednesday": "Wed",
            "Thursday": "Thu",
            "Friday": "Fri",
            "Saturday": "Sat",
            "Sunday": "Sun"
        ]

        let abbreviated = route.scheduledDays.compactMap { abbreviations[$0] ?? $0.prefix(3).description }
        return abbreviated.joined(separator: ", ")
    }

    /// Formats the estimated duration for display
    func formattedDuration(for route: Route) -> String {
        let hours = route.estimatedDuration / 60
        let minutes = route.estimatedDuration % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}
