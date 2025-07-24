import Foundation

// These models are shared across both request payloads and response data.
// They represent common reference objects in the OneRoster API.

struct OrgRef: Codable {
    let sourcedId: String
}

struct UserRef: Codable {
    let sourcedId: String
}

struct ClassRef: Codable {
    let sourcedId: String
}
