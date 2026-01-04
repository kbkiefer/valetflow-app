import Foundation
import FirebaseFirestore

struct Route: Identifiable, Codable {
    @DocumentID var id: String?
    var companyId: String
    var name: String
    var description: String
    var communityIds: [String]
    var assignedEmployeeId: String?
    var scheduledDays: [String]
    var startTime: String
    var estimatedDuration: Int
    var stopOrder: [String]
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case companyId
        case name
        case description
        case communityIds
        case assignedEmployeeId
        case scheduledDays
        case startTime
        case estimatedDuration
        case stopOrder
        case isActive
        case createdAt
        case updatedAt
    }
}
