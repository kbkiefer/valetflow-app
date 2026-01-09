import SwiftUI

struct EmployeeDetailView: View {
    @StateObject private var viewModel: EmployeeDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation

    // Animation states
    @State private var hasAppeared = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .success
    @State private var saveButtonState: AnimatedSaveButton.State = .idle
    @State private var shakeError = false

    // Section expansion states
    @State private var isPersonalInfoExpanded = true
    @State private var isEmploymentExpanded = true
    @State private var isPerformanceExpanded = true
    @State private var isDocumentsExpanded = true

    // Focus states for edit mode
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case firstName, lastName, email, phone
        case employeeNumber, position, payRate, vehicle
    }

    init(employeeId: String) {
        _viewModel = StateObject(wrappedValue: EmployeeDetailViewModel(employeeId: employeeId))
    }

    init(displayItem: EmployeeDisplayItem) {
        _viewModel = StateObject(wrappedValue: EmployeeDetailViewModel(displayItem: displayItem))
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.employee != nil {
                    mainContent
                } else {
                    errorStateView
                }
            }

            // Toast overlay
            VStack {
                ToastView(message: toastMessage, type: toastType, isShowing: showToast)
                    .padding(.top, 60)
                Spacer()
            }
            .animation(AnimationConstants.standardSpring, value: showToast)
        }
        .navigationTitle(viewModel.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
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

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header
                heroHeader
                    .padding(.bottom, -20)

                // Content sections
                VStack(spacing: 16) {
                    // Unsaved changes indicator
                    if viewModel.mode == .edit && viewModel.hasChanges {
                        UnsavedChangesIndicator(hasChanges: viewModel.hasChanges)
                            .padding(.top, 8)
                    }

                    ModeTransitionContainer(isEditMode: viewModel.mode == .edit) {
                        viewModeContent
                    } editContent: {
                        editModeContent
                    }
                }
                .padding(.horizontal)
                .padding(.top, 32)
                .padding(.bottom, 100)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Constants.Colors.adminPrimary,
                    Constants.Colors.adminPrimary.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            GeometryReader { geometry in
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .offset(x: -50, y: -30)

                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .offset(x: geometry.size.width - 80, y: 20)
            }

            // Content
            VStack(spacing: 16) {
                Spacer()
                    .frame(height: 60)

                // Avatar
                AvatarView(
                    initials: viewModel.user?.initials ?? "?",
                    size: 90,
                    backgroundColor: .white.opacity(0.2)
                )
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 3)
                }

                // Name
                Text(viewModel.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)

                // Position
                Text(viewModel.employee?.position ?? "Employee")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)

                // Status badge
                AnimatedStatusBadge(isActive: viewModel.employee?.isActive ?? false)
                    .scaleEffect(hasAppeared ? 1 : 0.8)
                    .opacity(hasAppeared ? 1 : 0)

                Spacer()
                    .frame(height: 30)
            }
        }
        .frame(height: 280)
        .clipShape(RoundedCorner(radius: 32, corners: [.bottomLeft, .bottomRight]))
        .onAppear {
            withAnimation(AnimationConstants.standardSpring.delay(0.2)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Constants.Colors.adminPrimary)

            Text("Loading employee details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error State View

    private var errorStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Constants.Colors.warning.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Constants.Colors.warning)
            }

            Text("Unable to Load Employee")
                .font(.title3)
                .fontWeight(.semibold)

            Text(viewModel.errorMessage ?? "Please try again later")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                dismiss()
            } label: {
                Text("Go Back")
                    .fontWeight(.medium)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Constants.Colors.adminPrimary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - View Mode Content

    @ViewBuilder
    private var viewModeContent: some View {
        VStack(spacing: 16) {
            // Personal Information Section
            CardSection(delay: 0.1) {
                ExpandableSection(isExpanded: $isPersonalInfoExpanded) {
                    AnimatedSectionHeader(title: "Personal Information", icon: "person.fill")
                } content: {
                    VStack(spacing: 12) {
                        if let user = viewModel.user {
                            AnimatedInfoRow(label: "Full Name", value: user.fullName, icon: "person", delay: 0.15)
                            Divider()
                            AnimatedInfoRow(label: "Email", value: user.email, icon: "envelope", delay: 0.2)
                            if let phone = user.phone, !phone.isEmpty {
                                Divider()
                                AnimatedInfoRow(label: "Phone", value: phone, icon: "phone", delay: 0.25)
                            }
                        } else {
                            Text("User information not available")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .padding(.top, 8)
                }
            }

            // Employment Details Section
            CardSection(delay: 0.2) {
                ExpandableSection(isExpanded: $isEmploymentExpanded) {
                    AnimatedSectionHeader(title: "Employment Details", icon: "briefcase.fill")
                } content: {
                    VStack(spacing: 12) {
                        AnimatedInfoRow(label: "Employee Number", value: viewModel.employee?.employeeNumber ?? "-", icon: "number", delay: 0.25)
                        Divider()
                        AnimatedInfoRow(label: "Position", value: viewModel.employee?.position ?? "-", icon: "person.badge.key", delay: 0.3)
                        Divider()
                        AnimatedInfoRow(label: "Pay Rate", value: viewModel.formattedPayRate, icon: "dollarsign.circle", delay: 0.35)
                        Divider()
                        AnimatedInfoRow(label: "Hire Date", value: viewModel.formattedHireDate, icon: "calendar", delay: 0.4)
                        if let vehicle = viewModel.employee?.vehicleAssigned, !vehicle.isEmpty {
                            Divider()
                            AnimatedInfoRow(label: "Assigned Vehicle", value: vehicle, icon: "car", delay: 0.45)
                        }
                    }
                    .padding(.top, 8)
                }
            }

            // Performance Section
            CardSection(delay: 0.3) {
                ExpandableSection(isExpanded: $isPerformanceExpanded) {
                    AnimatedSectionHeader(title: "Performance", icon: "chart.bar.fill")
                } content: {
                    VStack(spacing: 16) {
                        performanceMetricView(
                            title: "Completion Rate",
                            value: viewModel.performanceCompletionRate,
                            icon: "checkmark.circle.fill",
                            color: .green,
                            delay: 0.35
                        )

                        performanceMetricView(
                            title: "Avg Time per Route",
                            value: viewModel.performanceAverageTime,
                            icon: "clock.fill",
                            color: .blue,
                            delay: 0.4
                        )

                        performanceMetricView(
                            title: "Issue Reports",
                            value: viewModel.performanceIssueCount,
                            icon: "exclamationmark.triangle.fill",
                            color: .orange,
                            delay: 0.45
                        )
                    }
                    .padding(.top, 8)
                }
            }

            // Documents Section
            CardSection(delay: 0.4) {
                ExpandableSection(isExpanded: $isDocumentsExpanded) {
                    AnimatedSectionHeader(title: "Documents", icon: "doc.fill")
                } content: {
                    VStack(spacing: 12) {
                        documentRow(
                            title: "Driver's License",
                            icon: "car.fill",
                            document: viewModel.employee?.driversLicense,
                            delay: 0.45
                        )
                        Divider()
                        documentRow(
                            title: "Background Check",
                            icon: "checkmark.shield.fill",
                            document: viewModel.employee?.backgroundCheck,
                            delay: 0.5
                        )
                    }
                    .padding(.top, 8)
                }
            }

            // Actions Section
            CardSection(delay: 0.5) {
                VStack(spacing: 12) {
                    AnimatedSectionHeader(title: "Actions", icon: "gearshape.fill")

                    // Toggle status button
                    Button {
                        Task {
                            await viewModel.toggleActiveStatus()
                            showSuccessToast(viewModel.employee?.isActive == true ? "Employee activated" : "Employee deactivated")
                        }
                    } label: {
                        HStack {
                            Image(systemName: viewModel.employee?.isActive == true ? "person.fill.xmark" : "person.fill.checkmark")
                                .font(.body)
                            Text(viewModel.employee?.isActive == true ? "Deactivate Employee" : "Activate Employee")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(viewModel.employee?.isActive == true ? .orange : .green)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill((viewModel.employee?.isActive == true ? Color.orange : Color.green).opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)

                    // Delete button
                    AnimatedDeleteButton(
                        title: "Delete Employee",
                        isDeleting: false
                    ) {
                        viewModel.showDeleteConfirmation = true
                    }
                }
            }
        }
    }

    // MARK: - Edit Mode Content

    @ViewBuilder
    private var editModeContent: some View {
        VStack(spacing: 16) {
            // Personal Information Section
            CardSection(delay: 0.1) {
                VStack(spacing: 16) {
                    AnimatedSectionHeader(title: "Personal Information", icon: "person.fill")

                    VStack(spacing: 20) {
                        FloatingLabelTextField(
                            title: "First Name",
                            text: $viewModel.editFirstName,
                            textContentType: .givenName
                        )
                        .focused($focusedField, equals: .firstName)

                        FloatingLabelTextField(
                            title: "Last Name",
                            text: $viewModel.editLastName,
                            textContentType: .familyName
                        )
                        .focused($focusedField, equals: .lastName)

                        FloatingLabelTextField(
                            title: "Email",
                            text: $viewModel.editEmail,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            autocapitalization: .never
                        )
                        .focused($focusedField, equals: .email)

                        FloatingLabelTextField(
                            title: "Phone",
                            text: $viewModel.editPhone,
                            keyboardType: .phonePad,
                            textContentType: .telephoneNumber
                        )
                        .focused($focusedField, equals: .phone)
                    }
                    .padding(.top, 8)
                }
            }
            .shake(trigger: shakeError)

            // Employment Details Section
            CardSection(delay: 0.2) {
                VStack(spacing: 16) {
                    AnimatedSectionHeader(title: "Employment Details", icon: "briefcase.fill")

                    VStack(spacing: 20) {
                        FloatingLabelTextField(
                            title: "Employee Number",
                            text: $viewModel.editEmployeeNumber
                        )
                        .focused($focusedField, equals: .employeeNumber)

                        FloatingLabelTextField(
                            title: "Position",
                            text: $viewModel.editPosition
                        )
                        .focused($focusedField, equals: .position)

                        HStack(alignment: .bottom, spacing: 8) {
                            Text("$")
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)

                            FloatingLabelTextField(
                                title: "Pay Rate",
                                text: $viewModel.editPayRate,
                                keyboardType: .decimalPad
                            )
                            .focused($focusedField, equals: .payRate)

                            Text("/hr")
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)
                        }

                        FloatingLabelTextField(
                            title: "Assigned Vehicle",
                            text: $viewModel.editVehicleAssigned
                        )
                        .focused($focusedField, equals: .vehicle)
                    }
                    .padding(.top, 8)
                }
            }

            // Status Section
            CardSection(delay: 0.3) {
                VStack(spacing: 12) {
                    AnimatedSectionHeader(title: "Status", icon: "checkmark.circle.fill")

                    AnimatedToggle(
                        title: "Active",
                        isOn: $viewModel.editIsActive,
                        icon: "person.fill.checkmark"
                    )
                    .padding(.vertical, 4)
                }
            }

            // Save Button
            AnimatedSaveButton(
                title: "Save Changes",
                state: saveButtonState
            ) {
                Task {
                    await saveChanges()
                }
            }
            .disabled(!viewModel.hasChanges)
            .opacity(viewModel.hasChanges ? 1 : 0.6)
            .padding(.top, 8)
            .staggeredAppear(index: 4, baseDelay: 0.3)
        }
    }

    // MARK: - Helper Views

    private func performanceMetricView(title: String, value: String, icon: String, color: Color, delay: Double) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .staggeredAppear(index: Int(delay * 20), baseDelay: 0.1)
    }

    private func documentRow(title: String, icon: String, document: EmployeeDocument?, delay: Double) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Constants.Colors.adminPrimary.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(Constants.Colors.adminPrimary)
            }

            Text(title)
                .font(.body)

            Spacer()

            if let doc = document {
                if let expiryDate = doc.expiryDate {
                    documentStatusBadge(isValid: expiryDate >= Date(), validText: "Valid", invalidText: "Expired")
                } else if doc.completedDate != nil {
                    documentStatusBadge(isValid: true, validText: "Completed", invalidText: "")
                } else {
                    documentStatusBadge(isValid: false, validText: "", invalidText: "Pending")
                }
            } else {
                Text("Not uploaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                    )
            }
        }
        .staggeredAppear(index: Int(delay * 20), baseDelay: 0.1)
    }

    private func documentStatusBadge(isValid: Bool, validText: String, invalidText: String) -> some View {
        Text(isValid ? validText : invalidText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(isValid ? .green : .red)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill((isValid ? Color.green : Color.red).opacity(0.15))
            )
    }

    // MARK: - Saving Overlay

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Constants.Colors.adminPrimary)
                Text("Saving...")
                    .font(.headline)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            )
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Toolbar Content

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if viewModel.mode == .view {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(AnimationConstants.standardSpring) {
                        viewModel.enterEditMode()
                    }
                } label: {
                    Text("Edit")
                        .fontWeight(.medium)
                }
                .disabled(viewModel.isSaving)
            }
        } else {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    withAnimation(AnimationConstants.standardSpring) {
                        viewModel.cancelEdit()
                        focusedField = nil
                    }
                } label: {
                    Text("Cancel")
                }
                .disabled(viewModel.isSaving)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await saveChanges()
                    }
                } label: {
                    Text("Save")
                        .fontWeight(.semibold)
                }
                .disabled(!viewModel.hasChanges || viewModel.isSaving)
            }
        }
    }

    // MARK: - Actions

    private func saveChanges() async {
        focusedField = nil
        saveButtonState = .loading

        await viewModel.saveChanges()

        if viewModel.showError {
            saveButtonState = .error
            shakeError = true
            showErrorToast(viewModel.errorMessage ?? "Failed to save changes")
        } else {
            saveButtonState = .success
            showSuccessToast("Changes saved successfully")
        }

        try? await Task.sleep(nanoseconds: 1_500_000_000)
        saveButtonState = .idle
    }

    private func showSuccessToast(_ message: String) {
        toastMessage = message
        toastType = .success
        withAnimation(AnimationConstants.standardSpring) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(AnimationConstants.standardSpring) {
                showToast = false
            }
        }
    }

    private func showErrorToast(_ message: String) {
        toastMessage = message
        toastType = .error
        withAnimation(AnimationConstants.standardSpring) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(AnimationConstants.standardSpring) {
                showToast = false
            }
        }
    }
}

// MARK: - User Extension for Initials

extension User {
    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
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
