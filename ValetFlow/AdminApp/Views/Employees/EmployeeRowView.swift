import SwiftUI

struct EmployeeRowView: View {
    let employee: EmployeeDisplayItem

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(employee.isActive ? Color.green : Color.gray)
                .frame(width: 10, height: 10)

            // Employee info
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(employee.position)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Pay rate and hire date
            VStack(alignment: .trailing, spacing: 4) {
                Text(employee.formattedPayRate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("Hired: \(employee.formattedHireDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
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

    return List {
        EmployeeRowView(employee: displayItem)
    }
}
