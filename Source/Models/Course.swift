import Foundation

// Represents a OneRoster Course.
// We will only decode the properties relevant for the dashboard view for now.
struct Course: Decodable, Identifiable {
    let sourcedId: String
    let title: String
    let courseCode: String?
    let grades: [String]?
    let dateLastModified: String
    let org: OrgRef

    // Using 'id' to conform to the Identifiable protocol for SwiftUI lists.
    var id: String { sourcedId }
}

// Represents the wrapper object that the OneRoster API returns for a list of courses.
struct CourseListResponse: Decodable {
    let courses: [Course]
}
