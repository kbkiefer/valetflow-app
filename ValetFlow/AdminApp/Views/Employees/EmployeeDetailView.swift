import SwiftUI

struct EmployeeDetailView: View {
    @StateObject private var viewModel: EmployeeDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(employeeId: String) {
        _viewModel = StateObject(wrappedValue: EmployeeDetailViewModel(employeeId: employeeId))
    }

    init(displayItem: EmployeeDisplayItem) {
        _viewModel = StateObject(wrappedValue: EmployeeDetailViewModel(displayItem: displayItem))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.employee != nil {
                contentView
            } else {
                errorStateView
            }
        }
        .navigationTitle(viewModel.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert("Delete Employee", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteEmployee()
                }
            }
        } message: {
            Text("Are you sure you want to delete this employee? This action cannot be undone.")
        }
        .onChange(of: viewModel.didDelete) { _, didDelete in
            if didDelete {
                dismiss()
            }
        }
        .task {
            await viewModel.loadEmployee()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading employee details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error State View

    private var errorStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Unable to Load Employee")
                .font(.title3)
                .fontWeight(.semibold)

            Text(viewModel.errorMessage ?? "Please try again later")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Go Back") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content View

    private var contentView: some View {
        Form {
            if viewModel.mode == .view {
                viewModeContent
            } else {
                editModeContent
            }
        }
        .disabled(viewModel.isSaving)
        .overlay {
            if viewModel.isSaving {
                savingOverlay
            }
        }
    }

    // MARK: - View Mode Content

    @ViewBuilder
    private var viewModeContent: some View {
        // Status Section
        Section {
            HStack {
                Label("Status", systemImage: "circle.fill")
                    .foregroundColor(viewModel.employee?.isActive == true ? .green : .gray)
                Spacer()
                Text(viewModel.employee?.isActive == true ? "Active" : "Inactive")
                    .foregroundColor(.secondary)
            }
        }

        // Personal Information Section
        Section("Personal Information") {
            if let user = viewModel.user {
                LabeledContent("Name", value: user.fullName)
                LabeledContent("Email", value: user.email)
                if let phone = user.phone, !phone.isEmpty {
                    LabeledContent("Phone", value: phone)
                }
            } else {
                Text("User information not available")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }

        // Employment Details Section
        Section("Employment Details") {
            LabeledContent("Employee Number", value: viewModel.employee?.employeeNumber ?? "")
            LabeledContent("Position", value: viewModel.employee?.position ?? "")
            LabeledContent("Pay Rate", value: viewModel.formattedPayRate)
            LabeledContent("Hire Date", value: viewModel.formattedHireDate)
            if let vehicle = viewModel.employee?.vehicleAssigned, !vehicle.isEmpty {
                LabeledContent("Assigned Vehicle", value: vehicle)
            }
        }

        // Performance Section
        Section("Performance") {
            LabeledContent("Completion Rate", value: viewModel.performanceCompletionRate)
            LabeledContent("Avg Time per Route", value: viewModel.performanceAverageTime)
            LabeledContent("Issue Reports", value: viewModel.performanceIssueCount)
        }

        // Documents Section
        Section("Documents") {
            documentsView
        }

        // Actions Section
        Section {
            Button {
                Task {
                    await viewModel.toggleActiveStatus()
                }
            } label: {
                Label(
                    viewModel.employee?.isActive == true ? "Deactivate Employee" : "Activate Employee",
                    systemImage: viewModel.employee?.isActive == true ? "person.fill.xmark" : "person.fill.checkmark"
                )
            }
            .foregroundColor(viewModel.employee?.isActive == true ? .orange : .green)

            Button(role: .destructive) {
                viewModel.showDeleteConfirmation = true
            } label: {
                Label("Delete Employee", systemImage: "trash")
            }
        }
    }

    // MARK: - Edit Mode Content

    @ViewBuilder
    private var editModeContent: some View {
        // Personal Information Section
        Section("Personal Information") {
            TextField("First Name", text: $viewModel.editFirstName)
                .textContentType(.givenName)
            TextField("Last Name", text: $viewModel.editLastName)
                .textContentType(.familyName)
            TextField("Email", text: $viewModel.editEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            TextField("Phone", text: $viewModel.editPhone)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
        }

        // Employment Details Section
        Section("Employment Details") {
            TextField("Employee Number", text: $viewModel.editEmployeeNumber)
            TextField("Position", text: $viewModel.editPosition)
            HStack {
                Text("$")
                TextField("Pay Rate", text: $viewModel.editPayRate)
                    .keyboardType(.decimalPad)
                Text("/hr")
                    .foregroundColor(.secondary)
            }
            TextField("Assigned Vehicle", text: $viewModel.editVehicleAssigned)
        }

        // Status Section
        Section("Status") {
            Toggle("Active", isOn: $viewModel.editIsActive)
        }
    }

    // MARK: - Documents View

    @ViewBuilder
    private var documentsView: some View {
        if let license = viewModel.employee?.driversLicense {
            HStack {
                Label("Driver's License", systemImage: "car.fill")
                Spacer()
                if let expiryDate = license.expiryDate {
                    Text(expiryDate < Date() ? "Expired" : "Valid")
                        .font(.caption)
                        .foregroundColor(expiryDate < Date() ? .red : .green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(expiryDate < Date() ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                        )
                }
            }
        } else {
            HStack {
                Label("Driver's License", systemImage: "car.fill")
                Spacer()
                Text("Not uploaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }

        if let backgroundCheck = viewModel.employee?.backgroundCheck {
            HStack {
                Label("Background Check", systemImage: "checkmark.shield.fill")
                Spacer()
                if backgroundCheck.completedDate != nil {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.1))
                        )
                } else {
                    Text("Pending")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.1))
                        )
                }
            }
        } else {
            HStack {
                Label("Background Check", systemImage: "checkmark.shield.fill")
                Spacer()
                Text("Not uploaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Saving Overlay

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Saving...")
                    .font(.headline)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
        }
    }

    // MARK: - Toolbar Content

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if viewModel.mode == .view {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    viewModel.enterEditMode()
                }
                .disabled(viewModel.isSaving)
            }
        } else {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.cancelEdit()
                }
                .disabled(viewModel.isSaving)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.saveChanges()
                    }
                }
                .disabled(!viewModel.hasChanges || viewModel.isSaving)
                .fontWeight(.semibold)
            }
        }
    }
}

#Preview("View Mode") {
    let sampleEmployee = Employee(
        id: "emp-1",
        userId: "user-1",
        companyId: "company-1",
        employeeNumber: "EMP001",
        hireDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
        position: "Valet Driver",
        payRate: 18.50,
        vehicleAssigned: "Toyota Camry #12",
        driversLicense: EmployeeDocument(
            url: "https://example.com/license.pdf",
            expiryDate: Date().addingTimeInterval(180 * 24 * 60 * 60),
            completedDate: nil
        ),
        backgroundCheck: EmployeeDocument(
            url: "https://example.com/bgcheck.pdf",
            expiryDate: nil,
            completedDate: Date().addingTimeInterval(-30 * 24 * 60 * 60)
        ),
        availability: [:],
        performance: EmployeePerformance(
            completionRate: 0.95,
            averageTimePerRoute: 45.0,
            issueReportCount: 2
        ),
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    let sampleUser = User(
        id: "user-1",
        email: "john.doe@example.com",
        phone: "555-123-4567",
        firstName: "John",
        lastName: "Doe",
        role: .employee,
        companyId: "company-1",
        communityId: nil,
        unitNumber: nil,
        profilePhotoUrl: nil,
        createdAt: Date(),
        updatedAt: Date(),
        isActive: true,
        fcmTokens: []
    )

    let displayItem = EmployeeDisplayItem(
        id: "emp-1",
        employee: sampleEmployee,
        user: sampleUser
    )

    return NavigationStack {
        EmployeeDetailView(displayItem: displayItem)
    }
}
