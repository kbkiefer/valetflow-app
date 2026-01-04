import Foundation
import FirebaseFirestore

struct EmployeeDocument: Codable {
    var url: String
    var expiryDate: Date?
    var completedDate: Date?
}

struct EmployeeAvailability: Codable {
    var available: Bool
    var startTime: String?
    var endTime: String?
}

struct EmployeePerformance: Codable {
    var completionRate: Double
    var averageTimePerRoute: Double
    var issueReportCount: Int
}

struct Employee: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var companyId: String
    var employeeNumber: String
    var hireDate: Date
    var position: String
    var payRate: Double
    var vehicleAssigned: String?
    var driversLicense: EmployeeDocument?
    var backgroundCheck: EmployeeDocument?
    var availability: [String: EmployeeAvailability]
    var performance: EmployeePerformance
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case companyId
        case employeeNumber
        case hireDate
        case position
        case payRate
        case vehicleAssigned
        case driversLicense
        case backgroundCheck
        case availability
        case performance
        case isActive
        case createdAt
        case updatedAt
    }
}
