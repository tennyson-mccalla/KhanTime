import Foundation

// Represents a OneRoster User.
struct User: Codable, Identifiable {
    let sourcedId: String
    let status: String
    let givenName: String
    let familyName: String
    let role: String // Simplified for this model, will be set to "student"

    var id: String { sourcedId }
}

// The API expects a specific nested structure for creating a user.
struct UserCreatePayload: Codable {
    let user: UserPayload
}

struct UserPayload: Codable {
    var status: String = "active"
    let givenName: String
    let familyName: String
    let roles: [UserRole]
    var enabledUser: Bool = true
}

struct UserRole: Codable {
    var roleType: String = "primary"
    var role: String = "student"
    let org: OrgRef
}

// Represents a OneRoster Enrollment.
struct Enrollment: Codable, Identifiable {
    let sourcedId: String
    let status: String
    let role: String
    let user: UserRef
    let `class`: ClassRef

    var id: String { sourcedId }
}

// The API expects a specific nested structure for creating an enrollment.
struct EnrollmentCreatePayload: Codable {
    let enrollment: EnrollmentPayload
}

struct EnrollmentPayload: Codable {
    var status: String = "active"
    var role: String = "student"
    var primary: Bool = true
    let user: UserRef
    let `class`: ClassRef
}
