import Foundation
import FirebaseFirestore

enum UserRole: String, Codable {
    case admin
    case manager
    case employee
    case resident
    case propertyManager = "property_manager"
}

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var phone: String?
    var firstName: String
    var lastName: String
    var role: UserRole
    var companyId: String
    var communityId: String?
    var unitNumber: String?
    var profilePhotoUrl: String?
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    var fcmTokens: [String]

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case firstName
        case lastName
        case role
        case companyId
        case communityId
        case unitNumber
        case profilePhotoUrl
        case createdAt
        case updatedAt
        case isActive
        case fcmTokens
    }
}
