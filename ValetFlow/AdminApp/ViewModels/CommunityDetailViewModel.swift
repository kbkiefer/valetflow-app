import Foundation
import SwiftUI

@MainActor
class CommunityDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var community: Community?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isDeleting = false
    @Published var isEditMode = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showDeleteConfirmation = false
    @Published var didDeleteCommunity = false

    // MARK: - Editable Fields

    @Published var name = ""
    @Published var street = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zip = ""
    @Published var latitude = ""
    @Published var longitude = ""

    @Published var managerName = ""
    @Published var managerEmail = ""
    @Published var managerPhone = ""

    @Published var serviceDays: Set<String> = []
    @Published var serviceTime = Date()
    @Published var unitCount = ""
    @Published var buildingCount = ""

    @Published var accessInstructions = ""
    @Published var gateCode = ""
    @Published var specialInstructions = ""

    @Published var contractStartDate = Date()
    @Published var monthlyRate = ""
    @Published var billingContact = ""

    @Published var isActive = true

    // MARK: - Private Properties

    private let firebaseService = FirebaseService.shared
    private let communityId: String?

    // MARK: - Computed Properties

    var hasUnsavedChanges: Bool {
        guard let community = community else { return false }
        return name != community.name ||
            street != community.address.street ||
            city != community.address.city ||
            state != community.address.state ||
            zip != community.address.zip ||
            managerName != community.propertyManagerContact.name ||
            managerEmail != community.propertyManagerContact.email ||
            managerPhone != community.propertyManagerContact.phone ||
            serviceDays != Set(community.serviceDetails.serviceDays) ||
            unitCount != String(community.serviceDetails.unitCount) ||
            buildingCount != String(community.serviceDetails.buildingCount) ||
            accessInstructions != (community.accessInstructions ?? "") ||
            gateCode != (community.gateCode ?? "") ||
            specialInstructions != (community.specialInstructions ?? "") ||
            monthlyRate != String(format: "%.2f", community.contractInfo.monthlyRate) ||
            billingContact != community.contractInfo.billingContact ||
            isActive != community.isActive
    }

    var formattedAddress: String {
        guard let community = community else { return "" }
        return "\(community.address.street)\n\(community.address.city), \(community.address.state) \(community.address.zip)"
    }

    var formattedServiceDays: String {
        guard let community = community else { return "" }
        return community.serviceDetails.serviceDays.joined(separator: ", ")
    }

    var formattedServiceTime: String {
        guard let community = community else { return "" }
        return community.serviceDetails.serviceTime
    }

    var formattedMonthlyRate: String {
        guard let community = community else { return "" }
        return String(format: "$%.2f", community.contractInfo.monthlyRate)
    }

    var allWeekdays: [String] {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    }

    // MARK: - Initialization

    init(communityId: String) {
        self.communityId = communityId
        self.community = nil
    }

    init(community: Community) {
        self.communityId = community.id
        self.community = community
        populateFields(from: community)
    }

    // MARK: - Public Methods

    func loadCommunity() async {
        guard let communityId = communityId else {
            errorMessage = "Invalid community ID"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let fetchedCommunity: Community = try await firebaseService.fetch(
                collection: Constants.Collections.communities,
                documentId: communityId
            )
            community = fetchedCommunity
            populateFields(from: fetchedCommunity)
        } catch {
            errorMessage = "Failed to load community: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func saveCommunity() async {
        guard validateFields() else { return }
        guard let communityId = community?.id else {
            errorMessage = "Cannot save: missing community ID"
            showError = true
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let updatedCommunity = buildCommunity()
            try await firebaseService.update(
                collection: Constants.Collections.communities,
                documentId: communityId,
                data: updatedCommunity
            )
            community = updatedCommunity
            isEditMode = false
        } catch {
            errorMessage = "Failed to save community: \(error.localizedDescription)"
            showError = true
        }

        isSaving = false
    }

    func deleteCommunity() async {
        guard let communityId = community?.id else {
            errorMessage = "Cannot delete: missing community ID"
            showError = true
            return
        }

        isDeleting = true
        errorMessage = nil

        do {
            try await firebaseService.delete(
                collection: Constants.Collections.communities,
                documentId: communityId
            )
            didDeleteCommunity = true
        } catch {
            errorMessage = "Failed to delete community: \(error.localizedDescription)"
            showError = true
        }

        isDeleting = false
    }

    func enterEditMode() {
        guard let community = community else { return }
        populateFields(from: community)
        isEditMode = true
    }

    func cancelEdit() {
        guard let community = community else { return }
        populateFields(from: community)
        isEditMode = false
    }

    func toggleServiceDay(_ day: String) {
        if serviceDays.contains(day) {
            serviceDays.remove(day)
        } else {
            serviceDays.insert(day)
        }
    }

    // MARK: - Private Methods

    private func populateFields(from community: Community) {
        name = community.name
        street = community.address.street
        city = community.address.city
        state = community.address.state
        zip = community.address.zip
        latitude = String(community.address.coordinates.lat)
        longitude = String(community.address.coordinates.lng)

        managerName = community.propertyManagerContact.name
        managerEmail = community.propertyManagerContact.email
        managerPhone = community.propertyManagerContact.phone

        serviceDays = Set(community.serviceDetails.serviceDays)
        if let time = parseServiceTime(community.serviceDetails.serviceTime) {
            serviceTime = time
        }
        unitCount = String(community.serviceDetails.unitCount)
        buildingCount = String(community.serviceDetails.buildingCount)

        accessInstructions = community.accessInstructions ?? ""
        gateCode = community.gateCode ?? ""
        specialInstructions = community.specialInstructions ?? ""

        contractStartDate = community.contractInfo.startDate
        monthlyRate = String(format: "%.2f", community.contractInfo.monthlyRate)
        billingContact = community.contractInfo.billingContact

        isActive = community.isActive
    }

    private func parseServiceTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }

    private func formatServiceTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func validateFields() -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Community name is required"
            showError = true
            return false
        }

        if street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Street address is required"
            showError = true
            return false
        }

        if city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "City is required"
            showError = true
            return false
        }

        if state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "State is required"
            showError = true
            return false
        }

        if serviceDays.isEmpty {
            errorMessage = "At least one service day is required"
            showError = true
            return false
        }

        guard let _ = Int(unitCount) else {
            errorMessage = "Unit count must be a valid number"
            showError = true
            return false
        }

        guard let _ = Double(monthlyRate) else {
            errorMessage = "Monthly rate must be a valid number"
            showError = true
            return false
        }

        return true
    }

    private func buildCommunity() -> Community {
        let address = Address(
            street: street.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            state: state.trimmingCharacters(in: .whitespacesAndNewlines),
            zip: zip.trimmingCharacters(in: .whitespacesAndNewlines),
            coordinates: Coordinates(
                lat: Double(latitude) ?? community?.address.coordinates.lat ?? 0,
                lng: Double(longitude) ?? community?.address.coordinates.lng ?? 0
            )
        )

        let propertyManagerContact = PropertyManagerContact(
            name: managerName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: managerEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: managerPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        let sortedServiceDays = allWeekdays.filter { serviceDays.contains($0) }
        let serviceDetails = ServiceDetails(
            serviceDays: sortedServiceDays,
            serviceTime: formatServiceTime(serviceTime),
            unitCount: Int(unitCount) ?? 0,
            buildingCount: Int(buildingCount) ?? 0
        )

        let contractInfo = ContractInfo(
            startDate: contractStartDate,
            monthlyRate: Double(monthlyRate) ?? 0,
            billingContact: billingContact.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        return Community(
            id: community?.id,
            companyId: community?.companyId ?? "",
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address,
            propertyManagerContact: propertyManagerContact,
            serviceDetails: serviceDetails,
            accessInstructions: accessInstructions.isEmpty ? nil : accessInstructions,
            gateCode: gateCode.isEmpty ? nil : gateCode,
            specialInstructions: specialInstructions.isEmpty ? nil : specialInstructions,
            contractInfo: contractInfo,
            isActive: isActive,
            createdAt: community?.createdAt ?? Date(),
            updatedAt: Date()
        )
    }
}
