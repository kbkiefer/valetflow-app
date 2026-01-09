import SwiftUI

struct CommunityDetailView: View {
    @StateObject private var viewModel: CommunityDetailViewModel
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
    @State private var isGeneralInfoExpanded = true
    @State private var isAddressExpanded = true
    @State private var isPropertyManagerExpanded = true
    @State private var isServiceScheduleExpanded = true
    @State private var isAccessInfoExpanded = true
    @State private var isContractInfoExpanded = true

    // Focus states
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, unitCount, buildingCount
        case street, city, state, zip
        case managerName, managerEmail, managerPhone
        case gateCode, accessInstructions, specialInstructions
        case monthlyRate, billingContact
    }

    init(community: Community) {
        _viewModel = StateObject(wrappedValue: CommunityDetailViewModel(community: community))
    }

    init(communityId: String) {
        _viewModel = StateObject(wrappedValue: CommunityDetailViewModel(communityId: communityId))
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.community != nil {
                    mainContent
                } else {
                    errorView
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
        .navigationTitle(viewModel.community?.name ?? "Community")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert("Delete Community", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteCommunity()
                }
            }
        } message: {
            Text("Are you sure you want to delete this community? This action cannot be undone.")
        }
        .onChange(of: viewModel.didDeleteCommunity) { _, didDelete in
            if didDelete {
                dismiss()
            }
        }
        .task {
            if viewModel.community == nil {
                await viewModel.loadCommunity()
            }
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
                    if viewModel.isEditMode && viewModel.hasUnsavedChanges {
                        UnsavedChangesIndicator(hasChanges: viewModel.hasUnsavedChanges)
                            .padding(.top, 8)
                    }

                    ModeTransitionContainer(isEditMode: viewModel.isEditMode) {
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

            // Decorative elements
            GeometryReader { geometry in
                // Building shapes
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.08))
                            .frame(width: 30, height: CGFloat(40 + index * 20))
                    }
                }
                .offset(x: -20, y: geometry.size.height - 100)

                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .offset(x: geometry.size.width - 60, y: -20)
            }

            // Content
            VStack(spacing: 16) {
                Spacer()
                    .frame(height: 60)

                // Community icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 90, height: 90)

                    Image(systemName: "building.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .scaleEffect(hasAppeared ? 1 : 0.5)
                .opacity(hasAppeared ? 1 : 0)

                // Community name
                Text(viewModel.community?.name ?? "Community")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)

                // Location
                if let community = viewModel.community {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption)
                        Text("\(community.address.city), \(community.address.state)")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                }

                // Status badge
                AnimatedStatusBadge(isActive: viewModel.community?.isActive ?? false)
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

            Text("Loading community details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Constants.Colors.error.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Constants.Colors.error)
            }

            Text("Unable to Load Community")
                .font(.title3)
                .fontWeight(.semibold)

            Text(viewModel.errorMessage ?? "Something went wrong")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Task {
                    await viewModel.loadCommunity()
                }
            } label: {
                Text("Try Again")
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
        guard let community = viewModel.community else { return }

        VStack(spacing: 16) {
            // Quick Stats Card
            CardSection(delay: 0.05) {
                HStack(spacing: 0) {
                    quickStatItem(
                        value: "\(community.serviceDetails.unitCount)",
                        label: "Units",
                        icon: "house.fill",
                        color: .blue
                    )

                    Divider()
                        .frame(height: 50)

                    quickStatItem(
                        value: "\(community.serviceDetails.buildingCount)",
                        label: "Buildings",
                        icon: "building.2.fill",
                        color: .purple
                    )

                    Divider()
                        .frame(height: 50)

                    quickStatItem(
                        value: viewModel.formattedMonthlyRate,
                        label: "Monthly",
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                }
            }

            // General Information
            CardSection(delay: 0.1) {
                ExpandableSection(isExpanded: $isGeneralInfoExpanded) {
                    AnimatedSectionHeader(title: "General Information", icon: "info.circle.fill")
                } content: {
                    VStack(spacing: 12) {
                        AnimatedInfoRow(label: "Name", value: community.name, icon: "building", delay: 0.15)
                        Divider()
                        AnimatedInfoRow(label: "Units", value: "\(community.serviceDetails.unitCount)", icon: "house", delay: 0.2)
                        if community.serviceDetails.buildingCount > 0 {
                            Divider()
                            AnimatedInfoRow(label: "Buildings", value: "\(community.serviceDetails.buildingCount)", icon: "building.2", delay: 0.25)
                        }
                    }
                    .padding(.top, 8)
                }
            }

            // Address Section
            CardSection(delay: 0.2) {
                ExpandableSection(isExpanded: $isAddressExpanded) {
                    AnimatedSectionHeader(title: "Address", icon: "mappin.circle.fill")
                } content: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Constants.Colors.adminPrimary.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "map.fill")
                                    .foregroundColor(Constants.Colors.adminPrimary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(community.address.street)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("\(community.address.city), \(community.address.state) \(community.address.zip)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .padding(.top, 8)
                    .staggeredAppear(index: 3, baseDelay: 0.1)
                }
            }

            // Property Manager Section
            CardSection(delay: 0.3) {
                ExpandableSection(isExpanded: $isPropertyManagerExpanded) {
                    AnimatedSectionHeader(title: "Property Manager", icon: "person.circle.fill")
                } content: {
                    VStack(spacing: 12) {
                        AnimatedInfoRow(label: "Name", value: community.propertyManagerContact.name, icon: "person", delay: 0.35)

                        if !community.propertyManagerContact.email.isEmpty {
                            Divider()
                            contactRow(
                                label: "Email",
                                value: community.propertyManagerContact.email,
                                icon: "envelope.fill",
                                urlScheme: "mailto:",
                                delay: 0.4
                            )
                        }

                        if !community.propertyManagerContact.phone.isEmpty {
                            Divider()
                            contactRow(
                                label: "Phone",
                                value: community.propertyManagerContact.phone,
                                icon: "phone.fill",
                                urlScheme: "tel:",
                                delay: 0.45
                            )
                        }
                    }
                    .padding(.top, 8)
                }
            }

            // Service Schedule Section
            CardSection(delay: 0.4) {
                ExpandableSection(isExpanded: $isServiceScheduleExpanded) {
                    AnimatedSectionHeader(title: "Service Schedule", icon: "calendar.circle.fill")
                } content: {
                    VStack(spacing: 16) {
                        // Service days pills
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Service Days")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            serviceDaysPills
                        }
                        .staggeredAppear(index: 5, baseDelay: 0.1)

                        Divider()

                        AnimatedInfoRow(label: "Service Time", value: viewModel.formattedServiceTime, icon: "clock", delay: 0.5)
                    }
                    .padding(.top, 8)
                }
            }

            // Access Information Section
            CardSection(delay: 0.5) {
                ExpandableSection(isExpanded: $isAccessInfoExpanded) {
                    AnimatedSectionHeader(title: "Access Information", icon: "key.fill")
                } content: {
                    VStack(spacing: 12) {
                        if let gateCode = community.gateCode, !gateCode.isEmpty {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Constants.Colors.adminPrimary.opacity(0.15))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: "lock.shield.fill")
                                        .foregroundColor(Constants.Colors.adminPrimary)
                                }

                                Text("Gate Code")
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(gateCode)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                    )
                            }
                            .staggeredAppear(index: 6, baseDelay: 0.1)
                        }

                        if let accessInstructions = community.accessInstructions, !accessInstructions.isEmpty {
                            instructionsCard(
                                title: "Access Instructions",
                                content: accessInstructions,
                                icon: "doc.text.fill",
                                delay: 0.55
                            )
                        }

                        if let specialInstructions = community.specialInstructions, !specialInstructions.isEmpty {
                            instructionsCard(
                                title: "Special Instructions",
                                content: specialInstructions,
                                icon: "exclamationmark.bubble.fill",
                                delay: 0.6
                            )
                        }

                        if community.gateCode == nil && community.accessInstructions == nil && community.specialInstructions == nil {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                Text("No access information provided")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 8)
                }
            }

            // Contract Information Section
            CardSection(delay: 0.6) {
                ExpandableSection(isExpanded: $isContractInfoExpanded) {
                    AnimatedSectionHeader(title: "Contract Information", icon: "doc.text.fill")
                } content: {
                    VStack(spacing: 12) {
                        AnimatedInfoRow(label: "Monthly Rate", value: viewModel.formattedMonthlyRate, icon: "dollarsign.circle", delay: 0.65)
                        Divider()
                        AnimatedInfoRow(label: "Start Date", value: formatDate(community.contractInfo.startDate), icon: "calendar", delay: 0.7)
                        if !community.contractInfo.billingContact.isEmpty {
                            Divider()
                            AnimatedInfoRow(label: "Billing Contact", value: community.contractInfo.billingContact, icon: "envelope", delay: 0.75)
                        }
                    }
                    .padding(.top, 8)
                }
            }

            // Actions Section
            CardSection(delay: 0.7) {
                VStack(spacing: 12) {
                    AnimatedSectionHeader(title: "Actions", icon: "gearshape.fill")

                    // Toggle status button
                    Button {
                        Task {
                            await toggleCommunityStatus()
                        }
                    } label: {
                        HStack {
                            Image(systemName: community.isActive ? "pause.circle.fill" : "play.circle.fill")
                                .font(.body)
                            Text(community.isActive ? "Deactivate Community" : "Activate Community")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(community.isActive ? .orange : .green)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill((community.isActive ? Color.orange : Color.green).opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)

                    // Delete button
                    AnimatedDeleteButton(
                        title: "Delete Community",
                        isDeleting: viewModel.isDeleting
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
            // Status Section
            CardSection(delay: 0.05) {
                VStack(spacing: 12) {
                    AnimatedSectionHeader(title: "Status", icon: "checkmark.circle.fill")

                    AnimatedToggle(
                        title: "Active Community",
                        isOn: $viewModel.isActive,
                        icon: "building.2.fill"
                    )
                    .padding(.vertical, 4)
                }
            }

            // General Information Section
            CardSection(delay: 0.1) {
                VStack(spacing: 16) {
                    AnimatedSectionHeader(title: "General Information", icon: "info.circle.fill")

                    VStack(spacing: 20) {
                        FloatingLabelTextField(
                            title: "Community Name",
                            text: $viewModel.name
                        )
                        .focused($focusedField, equals: .name)

                        HStack(spacing: 16) {
                            FloatingLabelTextField(
                                title: "Units",
                                text: $viewModel.unitCount,
                                keyboardType: .numberPad
                            )
                            .focused($focusedField, equals: .unitCount)

                            FloatingLabelTextField(
                                title: "Buildings",
                                text: $viewModel.buildingCount,
                                keyboardType: .numberPad
                            )
                            .focused($focusedField, equals: .buildingCount)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .shake(trigger: shakeError)

            // Address Section
            CardSection(delay: 0.2) {
                VStack(spacing: 16) {
                    AnimatedSectionHeader(title: "Address", icon: "mappin.circle.fill")

                    VStack(spacing: 20) {
                        FloatingLabelTextField(
                            title: "Street Address",
                            text: $viewModel.street,
                            textContentType: .streetAddressLine1
                        )
                        .focused($focusedField, equals: .street)

                        HStack(spacing: 16) {
                            FloatingLabelTextField(
                                title: "City",
                                text: $viewModel.city,
                                textContentType: .addressCity
                            )
                            .focused($focusedField, equals: .city)

                            FloatingLabelTextField(
                                title: "State",
                                text: $viewModel.state,
                                textContentType: .addressState
                            )
                            .frame(width: 80)
                            .focused($focusedField, equals: .state)
                        }

                        FloatingLabelTextField(
                            title: "ZIP Code",
                            text: $viewModel.zip,
                            keyboardType: .numberPad,
                            textContentType: .postalCode
                        )
                        .frame(width: 120)
                        .focused($focusedField, equals: .zip)
                    }
                    .padding(.top, 8)
                }
            }

            // Property Manager Section
            CardSection(delay: 0.3) {
                VStack(spacing: 16) {
                    AnimatedSectionHeader(title: "Property Manager", icon: "person.circle.fill")

                    VStack(spacing: 20) {
                        FloatingLabelTextField(
                            title: "Manager Name",
                            text: $viewModel.managerName,
                            textContentType: .name
                        )
                        .focused($focusedField, equals: .managerName)

                        FloatingLabelTextField(
                            title: "Email",
                            text: $viewModel.managerEmail,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            autocapitalization: .never
                        )
                        .focused($focusedField, equals: .managerEmail)

                        FloatingLabelTextField(
                            title: "Phone",
                            text: $viewModel.managerPhone,
                            keyboardType: .phonePad,
                            textContentType: .telephoneNumber
                        )
                        .focused($focusedField, equals: .managerPhone)
                    }
                    .padding(.top, 8)
                }
            }

            // Service Schedule Section
            CardSection(delay: 0.4) {
                VStack(spacing: 16) {
                    AnimatedSectionHeader(title: "Service Schedule", icon: "calendar.circle.fill")

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Service Days")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        serviceDaysSelector
                    }

                    Divider()

                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Constants.Colors.adminPrimary)
                        DatePicker("Service Time", selection: $viewModel.serviceTime, displayedComponents: .hourAndMinute)
                    }
                }
            }

            // Access Information Section
            CardSection(delay: 0.5) {
                VStack(spacing: 16) {
                    AnimatedSectionHeader(title: "Access Information", icon: "key.fill")

                    VStack(spacing: 20) {
                        FloatingLabelTextField(
                            title: "Gate Code",
                            text: $viewModel.gateCode
                        )
                        .focused($focusedField, equals: .gateCode)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Access Instructions")
                                .font(.caption)
                                .foregroundColor(Constants.Colors.adminPrimary)

                            TextEditor(text: $viewModel.accessInstructions)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                                .focused($focusedField, equals: .accessInstructions)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Special Instructions")
                                .font(.caption)
                                .foregroundColor(Constants.Colors.adminPrimary)

                            TextEditor(text: $viewModel.specialInstructions)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                                .focused($focusedField, equals: .specialInstructions)
                        }
                    }
                    .padding(.top, 8)
                }
            }

            // Contract Information Section
            CardSection(delay: 0.6) {
                VStack(spacing: 16) {
                    AnimatedSectionHeader(title: "Contract Information", icon: "doc.text.fill")

                    VStack(spacing: 20) {
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("$")
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)

                            FloatingLabelTextField(
                                title: "Monthly Rate",
                                text: $viewModel.monthlyRate,
                                keyboardType: .decimalPad
                            )
                            .focused($focusedField, equals: .monthlyRate)
                        }

                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Constants.Colors.adminPrimary)
                            DatePicker("Contract Start Date", selection: $viewModel.contractStartDate, displayedComponents: .date)
                        }

                        FloatingLabelTextField(
                            title: "Billing Contact Email",
                            text: $viewModel.billingContact,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            autocapitalization: .never
                        )
                        .focused($focusedField, equals: .billingContact)
                    }
                    .padding(.top, 8)
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
            .disabled(!viewModel.hasUnsavedChanges)
            .opacity(viewModel.hasUnsavedChanges ? 1 : 0.6)
            .padding(.top, 8)
            .staggeredAppear(index: 7, baseDelay: 0.3)
        }
    }

    // MARK: - Helper Views

    private func quickStatItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
            }

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func contactRow(label: String, value: String, icon: String, urlScheme: String, delay: Double) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Constants.Colors.adminPrimary.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.adminPrimary)
            }

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            if let url = URL(string: "\(urlScheme)\(value)") {
                Link(destination: url) {
                    Text(value)
                        .foregroundColor(Constants.Colors.adminPrimary)
                        .fontWeight(.medium)
                }
            }
        }
        .staggeredAppear(index: Int(delay * 20), baseDelay: 0.1)
    }

    private func instructionsCard(title: String, content: String, icon: String, delay: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.adminPrimary)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            Text(content)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
        .staggeredAppear(index: Int(delay * 20), baseDelay: 0.1)
    }

    private var serviceDaysPills: some View {
        let allDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let serviceDays = viewModel.community?.serviceDetails.serviceDays ?? []

        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
            ForEach(allDays, id: \.self) { day in
                Text(String(day.prefix(3)))
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(serviceDays.contains(day) ? Constants.Colors.adminPrimary : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(serviceDays.contains(day) ? .white : .secondary)
            }
        }
    }

    private var serviceDaysSelector: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
            ForEach(viewModel.allWeekdays, id: \.self) { day in
                Button {
                    withAnimation(AnimationConstants.quickSpring) {
                        viewModel.toggleServiceDay(day)
                    }
                } label: {
                    Text(String(day.prefix(3)))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.serviceDays.contains(day) ? Constants.Colors.adminPrimary : Color.gray.opacity(0.15))
                        )
                        .foregroundColor(viewModel.serviceDays.contains(day) ? .white : .primary)
                        .scaleEffect(viewModel.serviceDays.contains(day) ? 1.02 : 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Toolbar Content

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if viewModel.isEditMode {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    withAnimation(AnimationConstants.standardSpring) {
                        viewModel.cancelEdit()
                        focusedField = nil
                    }
                } label: {
                    Text("Cancel")
                }
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
                .disabled(!viewModel.hasUnsavedChanges || viewModel.isSaving)
            }
        } else if viewModel.community != nil {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(AnimationConstants.standardSpring) {
                        viewModel.enterEditMode()
                    }
                } label: {
                    Text("Edit")
                        .fontWeight(.medium)
                }
            }
        }
    }

    // MARK: - Actions

    private func saveChanges() async {
        focusedField = nil
        saveButtonState = .loading

        await viewModel.saveCommunity()

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

    private func toggleCommunityStatus() async {
        // Toggle the status
        viewModel.isActive.toggle()
        await viewModel.saveCommunity()

        if !viewModel.showError {
            showSuccessToast(viewModel.isActive ? "Community activated" : "Community deactivated")
        }
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

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CommunityDetailView(community: Community(
            id: "1",
            companyId: "company1",
            name: "Oak Ridge Apartments",
            address: Address(
                street: "123 Oak Street",
                city: "Austin",
                state: "TX",
                zip: "78701",
                coordinates: Coordinates(lat: 30.2672, lng: -97.7431)
            ),
            propertyManagerContact: PropertyManagerContact(
                name: "John Smith",
                email: "john@oakridge.com",
                phone: "512-555-1234"
            ),
            serviceDetails: ServiceDetails(
                serviceDays: ["Monday", "Wednesday", "Friday"],
                serviceTime: "18:00",
                unitCount: 150,
                buildingCount: 5
            ),
            accessInstructions: "Enter through the main gate on Oak Street. Turn right and proceed to the service entrance.",
            gateCode: "1234",
            specialInstructions: "Do not enter after 9 PM. Leave bins at the designated area.",
            contractInfo: ContractInfo(
                startDate: Date(),
                monthlyRate: 2500.0,
                billingContact: "billing@oakridge.com"
            ),
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
