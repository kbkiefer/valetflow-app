import Foundation
import FirebaseFirestore

enum IssueType: String, Codable {
    case missedPickup = "missed_pickup"
    case contamination
    case damage
    case access
    case other
}

enum IssueReportedBy: String, Codable {
    case employee
    case resident
    case admin
}

enum IssueStatus: String, Codable {
    case open
    case investigating
    case resolved
    case closed
}

enum IssuePriority: String, Codable {
    case low
    case medium
    case high
}

struct Issue: Identifiable, Codable {
    @DocumentID var id: String?
    var type: IssueType
    var reportedBy: IssueReportedBy
    var reportedById: String
    var communityId: String
    var unitNumber: String?
    var description: String
    var photoUrls: [String]
    var status: IssueStatus
    var priority: IssuePriority
    var assignedToId: String?
    var resolution: String?
    var createdAt: Date
    var resolvedAt: Date?
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case reportedBy
        case reportedById
        case communityId
        case unitNumber
        case description
        case photoUrls
        case status
        case priority
        case assignedToId
        case resolution
        case createdAt
        case resolvedAt
        case updatedAt
    }
}
