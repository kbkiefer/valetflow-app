import Foundation
import SwiftUI

@MainActor
class EmployeeDetailViewModel: ObservableObject {
    // MARK: - Mode Enum

    enum Mode {
        case view
        case edit
    }

    // MARK: - Published Properties

    @Published var employee: Employee?
    @Published var user: User?
    @Published var mode: Mode = .view
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showDeleteConfirmation = false
    @Published var didDelete = false

    // MARK: - Editable Fields

    @Published var editPosition: String = ""
    @Published var editPayRate: String = ""
    @Published var editEmployeeNumber: String = ""
    @Published var editVehicleAssigned: String = ""
    @Published var editIsActive: Bool = true
    @Published var editFirstName: String = ""
    @Published var editLastName: String = ""
    @Published var editEmail: String = ""
    @Published var editPhone: String = ""

    // MARK: - Private Properties

    private let firebaseService = FirebaseService.shared
    private let employeeId: String
    private var initialDisplayItem: EmployeeDisplayItem?

    // MARK: - Computed Properties

    var displayItem: EmployeeDisplayItem? {
        guard let employee = employee, let id = employee.id else { return nil }
        return EmployeeDisplayItem(id: id, employee: employee, user: user)
    }

    var displayName: String {
        displayItem?.displayName ?? "Employee"
    }

    var hasChanges: Bool {
        guard let employee = employee else { return false }

        let payRateChanged = Double(editPayRate) != employee.payRate
        let positionChanged = editPosition != employee.position
        let employeeNumberChanged = editEmployeeNumber != employee.employeeNumber
        let vehicleChanged = editVehicleAssigned != (employee.vehicleAssigned ?? "")
        let activeChanged = editIsActive != employee.isActive

        var userChanged = false
        if let user = user {
            userChanged = editFirstName != user.firstName ||
                          editLastName != user.lastName ||
                          editEmail != user.email ||
                          editPhone != (user.phone ?? "")
        }

        return payRateChanged || positionChanged || employeeNumberChanged ||
               vehicleChanged || activeChanged || userChanged
    }

    var formattedHireDate: String {
        guard let employee = employee else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: employee.hireDate)
    }

    var formattedPayRate: String {
        guard let employee = employee else { return "" }
        return String(format: "$%.2f/hr", employee.payRate)
    }

    var performanceCompletionRate: String {
        guard let employee = employee else { return "" }
        return String(format: "%.0f%%", employee.performance.completionRate * 100)
    }

    var performanceAverageTime: String {
        guard let employee = employee else { return "" }
        return String(format: "%.0f min", employee.performance.averageTimePerRoute)
    }

    var performanceIssueCount: String {
        guard let employee = employee else { return "" }
        return "\(employee.performance.issueReportCount)"
    }

    // MARK: - Initialization

    init(employeeId: String) {
        self.employeeId = employeeId
    }

    init(displayItem: EmployeeDisplayItem) {
        self.employeeId = displayItem.id
        self.initialDisplayItem = displayItem
        self.employee = displayItem.employee
        self.user = displayItem.user
        populateEditFields()
    }

    // MARK: - Public Methods

    func loadEmployee() async {
        guard employee == nil else { return }

        isLoading = true
        errorMessage = nil

        do {
            let fetchedEmployee: Employee = try await firebaseService.fetch(
                collection: "employees",
                documentId: employeeId
            )
            employee = fetchedEmployee

            // Try to fetch associated user
            do {
                let fetchedUser: User = try await firebaseService.fetch(
                    collection: "users",
                    documentId: fetchedEmployee.userId
                )
                user = fetchedUser
            } catch {
                // User fetch failed, but employee data is still valid
                user = nil
            }

            populateEditFields()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func enterEditMode() {
        populateEditFields()
        mode = .edit
    }

    func cancelEdit() {
        populateEditFields()
        mode = .view
    }

    func saveChanges() async {
        guard var employee = employee else { return }

        isSaving = true
        errorMessage = nil

        do {
            // Update employee fields
            employee.position = editPosition
            employee.payRate = Double(editPayRate) ?? employee.payRate
            employee.employeeNumber = editEmployeeNumber
            employee.vehicleAssigned = editVehicleAssigned.isEmpty ? nil : editVehicleAssigned
            employee.isActive = editIsActive
            employee.updatedAt = Date()

            try await firebaseService.update(
                collection: "employees",
                documentId: employeeId,
                data: employee
            )

            // Update user if we have one
            if var user = user, let userId = user.id {
                user.firstName = editFirstName
                user.lastName = editLastName
                user.email = editEmail
                user.phone = editPhone.isEmpty ? nil : editPhone
                user.updatedAt = Date()

                try await firebaseService.update(
                    collection: "users",
                    documentId: userId,
                    data: user
                )

                self.user = user
            }

            self.employee = employee
            isSaving = false
            mode = .view
        } catch {
            isSaving = false
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showError = true
        }
    }

    func deleteEmployee() async {
        isSaving = true
        errorMessage = nil

        do {
            try await firebaseService.delete(
                collection: "employees",
                documentId: employeeId
            )
            isSaving = false
            didDelete = true
        } catch {
            isSaving = false
            errorMessage = "Failed to delete employee: \(error.localizedDescription)"
            showError = true
        }
    }

    func toggleActiveStatus() async {
        guard var employee = employee else { return }

        isSaving = true
        errorMessage = nil

        do {
            employee.isActive.toggle()
            employee.updatedAt = Date()

            try await firebaseService.update(
                collection: "employees",
                documentId: employeeId,
                data: employee
            )

            self.employee = employee
            editIsActive = employee.isActive
            isSaving = false
        } catch {
            isSaving = false
            errorMessage = "Failed to update status: \(error.localizedDescription)"
            showError = true
        }
    }

    // MARK: - Private Methods

    private func populateEditFields() {
        guard let employee = employee else { return }

        editPosition = employee.position
        editPayRate = String(format: "%.2f", employee.payRate)
        editEmployeeNumber = employee.employeeNumber
        editVehicleAssigned = employee.vehicleAssigned ?? ""
        editIsActive = employee.isActive

        if let user = user {
            editFirstName = user.firstName
            editLastName = user.lastName
            editEmail = user.email
            editPhone = user.phone ?? ""
        }
    }
}
