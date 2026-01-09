import Foundation
import SwiftUI

/// A display model that combines Employee and User data for the list view
struct EmployeeDisplayItem: Identifiable {
    let id: String
    let employee: Employee
    let user: User?

    var displayName: String {
        user?.fullName ?? "Employee #\(employee.employeeNumber)"
    }

    var position: String {
        employee.position
    }

    var isActive: Bool {
        employee.isActive
    }

    var payRate: Double {
        employee.payRate
    }

    var hireDate: Date {
        employee.hireDate
    }

    var formattedPayRate: String {
        String(format: "$%.2f/hr", payRate)
    }

    var formattedHireDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: hireDate)
    }
}

@MainActor
class EmployeesListViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var employees: [EmployeeDisplayItem] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Private Properties

    private let firebaseService = FirebaseService.shared

    // MARK: - Computed Properties

    var filteredEmployees: [EmployeeDisplayItem] {
        guard !searchText.isEmpty else {
            return employees
        }

        let searchLower = searchText.lowercased()
        return employees.filter { item in
            item.displayName.lowercased().contains(searchLower) ||
            item.position.lowercased().contains(searchLower) ||
            item.employee.employeeNumber.lowercased().contains(searchLower)
        }
    }

    var isEmpty: Bool {
        employees.isEmpty && !isLoading
    }

    var isSearchEmpty: Bool {
        filteredEmployees.isEmpty && !searchText.isEmpty && !employees.isEmpty
    }

    // MARK: - Public Methods

    func loadEmployees() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all employees from Firestore
            let fetchedEmployees: [Employee] = try await firebaseService.fetchAll(
                collection: "employees"
            )

            // Fetch all users to match with employees
            let fetchedUsers: [User] = try await firebaseService.fetchAll(
                collection: "users"
            )

            // Create a dictionary for quick user lookup
            let userDict = Dictionary(uniqueKeysWithValues: fetchedUsers.compactMap { user in
                user.id.map { ($0, user) }
            })

            // Combine employees with their user data
            employees = fetchedEmployees.compactMap { employee in
                guard let employeeId = employee.id else { return nil }
                let user = userDict[employee.userId]
                return EmployeeDisplayItem(
                    id: employeeId,
                    employee: employee,
                    user: user
                )
            }.sorted { $0.displayName < $1.displayName }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func deleteEmployee(_ employee: EmployeeDisplayItem) async {
        do {
            try await firebaseService.delete(
                collection: "employees",
                documentId: employee.id
            )

            // Remove from local list
            employees.removeAll { $0.id == employee.id }
        } catch {
            errorMessage = "Failed to delete employee: \(error.localizedDescription)"
            showError = true
        }
    }

    func refresh() async {
        await loadEmployees()
    }
}
