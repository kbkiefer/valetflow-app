import SwiftUI

struct EmployeeRowView: View {
    let employee: EmployeeDisplayItem
    let index: Int

    @State private var isVisible = false
    @State private var isPressed = false

    init(employee: EmployeeDisplayItem, index: Int = 0) {
        self.employee = employee
        self.index = index
    }

    private var animationDelay: Double {
        Double(index) * 0.05
    }

    var body: some View {
        HStack(spacing: 14) {
            // Animated status indicator
            PulsingStatusIndicator(
                isActive: employee.isActive,
                activeColor: Constants.Colors.success,
                inactiveColor: Constants.Colors.adminAccent
            )

            // Employee info with gradient accent
            VStack(alignment: .leading, spacing: 6) {
                Text(employee.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())

                HStack(spacing: 4) {
                    Image(systemName: "briefcase.fill")
                        .font(.caption2)
                        .foregroundColor(Constants.Colors.adminPrimary.opacity(0.7))

                    Text(employee.position)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Pay rate and hire date with refined styling
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Text(employee.formattedPayRate)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Constants.Colors.adminPrimary, Constants.Colors.adminPrimary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentTransition(.numericText())
                }

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))

                    Text(employee.formattedHireDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Animated status badge
            AnimatedStatusBadge(
                isActive: employee.isActive,
                activeColor: Constants.Colors.success,
                inactiveColor: Constants.Colors.adminAccent
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: employee.isActive
                        ? Constants.Colors.success.opacity(0.1)
                        : Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: employee.isActive
                            ? [Constants.Colors.success.opacity(0.3), Constants.Colors.success.opacity(0.1)]
                            : [Color.gray.opacity(0.2), Color.gray.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
}

// MARK: - Skeleton Loading for Employee Row

struct EmployeeRowSkeleton: View {
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
                    .frame(width: 140, height: 16)

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 12, height: 12)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 100, height: 12)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 80, height: 10)
            }

            // Badge placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 55, height: 24)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
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

#Preview("Employee Row") {
    let sampleEmployee = Employee(
        id: "emp-1",
        userId: "user-1",
        companyId: "company-1",
        employeeNumber: "EMP001",
        hireDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
        position: "Valet Driver",
        payRate: 18.50,
        vehicleAssigned: nil,
        driversLicense: nil,
        backgroundCheck: nil,
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
        phone: "555-1234",
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

    return ScrollView {
        VStack(spacing: 12) {
            EmployeeRowView(employee: displayItem, index: 0)
            EmployeeRowView(employee: displayItem, index: 1)
            EmployeeRowView(employee: displayItem, index: 2)
        }
        .padding()
    }
}

#Preview("Skeleton Loading") {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { index in
                EmployeeRowSkeleton(index: index)
            }
        }
        .padding()
    }
}
