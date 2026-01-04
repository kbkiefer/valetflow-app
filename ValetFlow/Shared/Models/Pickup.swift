import Foundation
import FirebaseFirestore

enum PickupStatus: String, Codable {
    case pending
    case completed
    case missed
    case issue
}

struct Pickup: Identifiable, Codable {
    @DocumentID var id: String?
    var shiftId: String
    var communityId: String
    var employeeId: String
    var scheduledDate: Date
    var completedAt: Date?
    var status: PickupStatus
    var location: Coordinates?
    var photoUrls: [String]
    var notes: String?
    var issueType: String?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case shiftId
        case communityId
        case employeeId
        case scheduledDate
        case completedAt
        case status
        case location
        case photoUrls
        case notes
        case issueType
        case createdAt
        case updatedAt
    }
}
