import SwiftUI

struct CommunityRowView: View {
    let community: Community
    let index: Int

    @State private var isVisible = false
    @State private var isPressed = false

    init(community: Community, index: Int = 0) {
        self.community = community
        self.index = index
    }

    private var animationDelay: Double {
        Double(index) * 0.05
    }

    var body: some View {
        HStack(spacing: 14) {
            // Animated status indicator
            PulsingStatusIndicator(
                isActive: community.isActive,
                activeColor: Constants.Colors.success,
                inactiveColor: Constants.Colors.adminAccent
            )

            // Community info with enhanced styling
            VStack(alignment: .leading, spacing: 6) {
                Text(community.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundColor(Constants.Colors.communityPrimary.opacity(0.7))

                    Text(formattedAddress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    StatLabel(
                        icon: "building.fill",
                        value: "\(community.serviceDetails.unitCount)",
                        label: "units",
                        color: Constants.Colors.adminPrimary
                    )

                    if community.serviceDetails.buildingCount > 0 {
                        StatLabel(
                            icon: "building.2.fill",
                            value: "\(community.serviceDetails.buildingCount)",
                            label: "buildings",
                            color: Constants.Colors.communityPrimary
                        )
                    }
                }
            }

            Spacer()

            // Animated status badge
            AnimatedStatusBadge(
                isActive: community.isActive,
                activeColor: Constants.Colors.success,
                inactiveColor: Constants.Colors.adminAccent
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(
                    color: community.isActive
                        ? Constants.Colors.success.opacity(0.08)
                        : Color.black.opacity(0.04),
                    radius: 10,
                    x: 0,
                    y: 3
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    LinearGradient(
                        colors: community.isActive
                            ? [Constants.Colors.success.opacity(0.25), Constants.Colors.success.opacity(0.05)]
                            : [Color.gray.opacity(0.15), Color.gray.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8)
            .delay(animationDelay),
            value: isVisible
        )
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    private var formattedAddress: String {
        "\(community.address.street), \(community.address.city), \(community.address.state)"
    }
}

// MARK: - Stat Label Component

private struct StatLabel: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    @State private var isAnimated = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color.opacity(0.7))
                .scaleEffect(isAnimated ? 1.0 : 0.8)

            Text("\(value) \(label)")
                .font(.caption)
                .foregroundColor(.secondary)
                .contentTransition(.numericText())
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) {
                isAnimated = true
            }
        }
    }
}

// MARK: - Skeleton Loading for Community Row

struct CommunityRowSkeleton: View {
    let index: Int

    @State private var isVisible = false

    private var animationDelay: Double {
        Double(index) * 0.08
    }

    var body: some View {
        HStack(spacing: 14) {
            // Status indicator placeholder
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 10, height: 10)

            // Content placeholders
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 160, height: 16)

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 12, height: 12)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 180, height: 12)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 10, height: 10)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 50, height: 10)
                    }

                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 10, height: 10)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 60, height: 10)
                    }
                }
            }

            Spacer()

            // Badge placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 55, height: 24)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .shimmer()
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 15)
        .animation(
            .easeOut(duration: 0.35)
            .delay(animationDelay),
            value: isVisible
        )
        .onAppear {
            isVisible = true
        }
    }
}

#Preview("Community Row") {
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

    return ScrollView {
        VStack(spacing: 12) {
            CommunityRowView(community: sampleCommunity, index: 0)
            CommunityRowView(community: sampleCommunity, index: 1)
            CommunityRowView(community: sampleCommunity, index: 2)
        }
        .padding()
    }
}

#Preview("Skeleton Loading") {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { index in
                CommunityRowSkeleton(index: index)
            }
        }
        .padding()
    }
}
