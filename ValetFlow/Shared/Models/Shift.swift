import Foundation
import FirebaseFirestore

enum ShiftStatus: String, Codable {
    case scheduled
    case started
    case completed
    case cancelled
    case noShow = "no_show"
}

struct Shift: Identifiable, Codable {
    @DocumentID var id: String?
    var companyId: String
    var employeeId: String
    var routeId: String
    var scheduledDate: Date
    var scheduledStartTime: Date
    var scheduledEndTime: Date
    var status: ShiftStatus
    var actualStartTime: Date?
    var actualEndTime: Date?
    var clockInLocation: Coordinates?
    var clockOutLocation: Coordinates?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case companyId
        case employeeId
        case routeId
        case scheduledDate
        case scheduledStartTime
        case scheduledEndTime
        case status
        case actualStartTime
        case actualEndTime
        case clockInLocation
        case clockOutLocation
        case createdAt
        case updatedAt
    }
}

struct RouteProgress: Codable {
    var currentCommunityId: String?
    var completedCommunityIds: [String]
    var totalCommunities: Int
    var completedPickups: Int
    var totalPickups: Int
}

struct ActiveShift: Identifiable, Codable {
    @DocumentID var id: String?
    var shiftId: String
    var employeeId: String
    var routeId: String
    var currentLocation: LocationUpdate
    var routeProgress: RouteProgress
    var startedAt: Date
    var lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case id
        case shiftId
        case employeeId
        case routeId
        case currentLocation
        case routeProgress
        case startedAt
        case lastUpdated
    }
}

struct LocationUpdate: Codable {
    var coordinates: Coordinates
    var timestamp: Date
    var speed: Double?
    var heading: Double?
}
