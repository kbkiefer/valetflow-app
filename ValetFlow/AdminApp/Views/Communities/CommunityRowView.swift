import SwiftUI

struct CommunityRowView: View {
    let community: Community

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(community.isActive ? Constants.Colors.success : Constants.Colors.adminAccent)
                .frame(width: 10, height: 10)

            // Community info
            VStack(alignment: .leading, spacing: 4) {
                Text(community.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(formattedAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 16) {
                    Label("\(community.serviceDetails.unitCount) units", systemImage: "building.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if community.serviceDetails.buildingCount > 0 {
                        Label("\(community.serviceDetails.buildingCount) buildings", systemImage: "building.2.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Active badge
            if community.isActive {
                Text("Active")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Constants.Colors.success)
                    .cornerRadius(4)
            } else {
                Text("Inactive")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Constants.Colors.adminAccent)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }

    private var formattedAddress: String {
        "\(community.address.street), \(community.address.city), \(community.address.state)"
    }
}

#Preview {
    let sampleCommunity = Community(
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
        accessInstructions: "Use gate code",
        gateCode: "1234",
        specialInstructions: nil,
        contractInfo: ContractInfo(
            startDate: Date(),
            monthlyRate: 2500.0,
            billingContact: "billing@oakridge.com"
        ),
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    return List {
        CommunityRowView(community: sampleCommunity)
    }
}
