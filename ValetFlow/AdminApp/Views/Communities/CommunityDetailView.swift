import SwiftUI

struct CommunityDetailView: View {
    @StateObject private var viewModel: CommunityDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(community: Community) {
        _viewModel = StateObject(wrappedValue: CommunityDetailViewModel(community: community))
    }

    init(communityId: String) {
        _viewModel = StateObject(wrappedValue: CommunityDetailViewModel(communityId: communityId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let community = viewModel.community {
                if viewModel.isEditMode {
                    editModeContent(community: community)
                } else {
                    viewModeContent(community: community)
                }
            } else {
                errorView
            }
        }
        .navigationTitle(viewModel.community?.name ?? "Community Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isEditMode {
                    Button("Cancel") {
                        viewModel.cancelEdit()
                    }
                } else if viewModel.community != nil {
                    Button("Edit") {
                        viewModel.enterEditMode()
                    }
                }
            }
        }
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

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading community details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.error)

            Text("Unable to Load Community")
                .font(.title2)
                .fontWeight(.semibold)

            Text(viewModel.errorMessage ?? "Something went wrong")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Try Again") {
                Task {
                    await viewModel.loadCommunity()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.Colors.adminPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - View Mode Content

    private func viewModeContent(community: Community) -> some View {
        List {
            // Status Section
            statusSection(community: community)

            // General Information
            generalInfoSection(community: community)

            // Address Section
            addressSection(community: community)

            // Property Manager Section
            propertyManagerSection(community: community)

            // Service Schedule Section
            serviceScheduleSection(community: community)

            // Access Information Section
            accessInfoSection(community: community)

            // Contract Information Section
            contractInfoSection(community: community)

            // Delete Section
            deleteSection
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Edit Mode Content

    private func editModeContent(community: Community) -> some View {
        List {
            // Status Toggle
            editStatusSection

            // General Information
            editGeneralInfoSection

            // Address Section
            editAddressSection

            // Property Manager Section
            editPropertyManagerSection

            // Service Schedule Section
            editServiceScheduleSection

            // Access Information Section
            editAccessInfoSection

            // Contract Information Section
            editContractInfoSection

            // Save Button
            saveSection
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - View Mode Sections

    private func statusSection(community: Community) -> some View {
        Section {
            HStack {
                Text("Status")
                Spacer()
                Text(community.isActive ? "Active" : "Inactive")
                    .foregroundColor(community.isActive ? Constants.Colors.success : Constants.Colors.adminAccent)
                    .fontWeight(.medium)
            }
        }
    }

    private func generalInfoSection(community: Community) -> some View {
        Section("General Information") {
            DetailRow(label: "Name", value: community.name)
            DetailRow(label: "Units", value: "\(community.serviceDetails.unitCount)")
            if community.serviceDetails.buildingCount > 0 {
                DetailRow(label: "Buildings", value: "\(community.serviceDetails.buildingCount)")
            }
        }
    }

    private func addressSection(community: Community) -> some View {
        Section("Address") {
            VStack(alignment: .leading, spacing: 4) {
                Text(community.address.street)
                    .font(.body)
                Text("\(community.address.city), \(community.address.state) \(community.address.zip)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func propertyManagerSection(community: Community) -> some View {
        Section("Property Manager") {
            DetailRow(label: "Name", value: community.propertyManagerContact.name)

            if !community.propertyManagerContact.email.isEmpty {
                HStack {
                    Text("Email")
                        .foregroundColor(.secondary)
                    Spacer()
                    Link(community.propertyManagerContact.email, destination: URL(string: "mailto:\(community.propertyManagerContact.email)")!)
                        .foregroundColor(Constants.Colors.adminPrimary)
                }
            }

            if !community.propertyManagerContact.phone.isEmpty {
                HStack {
                    Text("Phone")
                        .foregroundColor(.secondary)
                    Spacer()
                    Link(community.propertyManagerContact.phone, destination: URL(string: "tel:\(community.propertyManagerContact.phone)")!)
                        .foregroundColor(Constants.Colors.adminPrimary)
                }
            }
        }
    }

    private func serviceScheduleSection(community: Community) -> some View {
        Section("Service Schedule") {
            DetailRow(label: "Days", value: viewModel.formattedServiceDays)
            DetailRow(label: "Time", value: viewModel.formattedServiceTime)
        }
    }

    private func accessInfoSection(community: Community) -> some View {
        Section("Access Information") {
            if let gateCode = community.gateCode, !gateCode.isEmpty {
                DetailRow(label: "Gate Code", value: gateCode)
            }

            if let accessInstructions = community.accessInstructions, !accessInstructions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Access Instructions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(accessInstructions)
                        .font(.body)
                }
                .padding(.vertical, 4)
            }

            if let specialInstructions = community.specialInstructions, !specialInstructions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Special Instructions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(specialInstructions)
                        .font(.body)
                }
                .padding(.vertical, 4)
            }

            if community.gateCode == nil && community.accessInstructions == nil && community.specialInstructions == nil {
                Text("No access information provided")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }

    private func contractInfoSection(community: Community) -> some View {
        Section("Contract Information") {
            DetailRow(label: "Monthly Rate", value: viewModel.formattedMonthlyRate)
            DetailRow(label: "Start Date", value: formatDate(community.contractInfo.startDate))
            if !community.contractInfo.billingContact.isEmpty {
                DetailRow(label: "Billing Contact", value: community.contractInfo.billingContact)
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.showDeleteConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isDeleting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Delete Community", systemImage: "trash")
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isDeleting)
        }
    }

    // MARK: - Edit Mode Sections

    private var editStatusSection: some View {
        Section {
            Toggle("Active", isOn: $viewModel.isActive)
        }
    }

    private var editGeneralInfoSection: some View {
        Section("General Information") {
            TextField("Community Name", text: $viewModel.name)
            TextField("Unit Count", text: $viewModel.unitCount)
                .keyboardType(.numberPad)
            TextField("Building Count", text: $viewModel.buildingCount)
                .keyboardType(.numberPad)
        }
    }

    private var editAddressSection: some View {
        Section("Address") {
            TextField("Street", text: $viewModel.street)
            TextField("City", text: $viewModel.city)
            TextField("State", text: $viewModel.state)
            TextField("ZIP Code", text: $viewModel.zip)
                .keyboardType(.numberPad)
        }
    }

    private var editPropertyManagerSection: some View {
        Section("Property Manager") {
            TextField("Name", text: $viewModel.managerName)
            TextField("Email", text: $viewModel.managerEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            TextField("Phone", text: $viewModel.managerPhone)
                .keyboardType(.phonePad)
        }
    }

    private var editServiceScheduleSection: some View {
        Section("Service Schedule") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Service Days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(viewModel.allWeekdays, id: \.self) { day in
                        Button {
                            viewModel.toggleServiceDay(day)
                        } label: {
                            Text(day.prefix(3))
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(viewModel.serviceDays.contains(day) ? Constants.Colors.adminPrimary : Color.gray.opacity(0.2))
                                .foregroundColor(viewModel.serviceDays.contains(day) ? .white : .primary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)

            DatePicker("Service Time", selection: $viewModel.serviceTime, displayedComponents: .hourAndMinute)
        }
    }

    private var editAccessInfoSection: some View {
        Section("Access Information") {
            TextField("Gate Code", text: $viewModel.gateCode)

            VStack(alignment: .leading, spacing: 4) {
                Text("Access Instructions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $viewModel.accessInstructions)
                    .frame(minHeight: 80)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Special Instructions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $viewModel.specialInstructions)
                    .frame(minHeight: 80)
            }
        }
    }

    private var editContractInfoSection: some View {
        Section("Contract Information") {
            TextField("Monthly Rate", text: $viewModel.monthlyRate)
                .keyboardType(.decimalPad)
            DatePicker("Contract Start Date", selection: $viewModel.contractStartDate, displayedComponents: .date)
            TextField("Billing Contact", text: $viewModel.billingContact)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.saveCommunity()
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Save Changes")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isSaving)
            .listRowBackground(Constants.Colors.adminPrimary)
            .foregroundColor(.white)
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Detail Row Component

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
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
