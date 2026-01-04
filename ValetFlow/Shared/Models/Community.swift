import Foundation
import FirebaseFirestore

struct Address: Codable {
    var street: String
    var city: String
    var state: String
    var zip: String
    var coordinates: Coordinates
}

struct Coordinates: Codable {
    var lat: Double
    var lng: Double
}

struct PropertyManagerContact: Codable {
    var name: String
    var email: String
    var phone: String
}

struct ServiceDetails: Codable {
    var serviceDays: [String]
    var serviceTime: String
    var unitCount: Int
    var buildingCount: Int
}

struct ContractInfo: Codable {
    var startDate: Date
    var monthlyRate: Double
    var billingContact: String
}

struct Community: Identifiable, Codable {
    @DocumentID var id: String?
    var companyId: String
    var name: String
    var address: Address
    var propertyManagerContact: PropertyManagerContact
    var serviceDetails: ServiceDetails
    var accessInstructions: String?
    var gateCode: String?
    var specialInstructions: String?
    var contractInfo: ContractInfo
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case companyId
        case name
        case address
        case propertyManagerContact
        case serviceDetails
        case accessInstructions
        case gateCode
        case specialInstructions
        case contractInfo
        case isActive
        case createdAt
        case updatedAt
    }
}
