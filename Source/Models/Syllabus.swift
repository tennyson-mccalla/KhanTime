import Foundation

// The main response from the /powerpath/syllabus/:courseSourcedId endpoint
struct SyllabusResponse: Decodable {
    let syllabus: Syllabus
}

// Represents the overall syllabus structure for a course
struct Syllabus: Decodable {
    let course: Course?
    let subComponents: [CourseComponent]?  // Changed from 'components' to 'subComponents'

    // Computed property for backward compatibility
    var components: [CourseComponent]? {
        return subComponents
    }
}

// Represents a component in the syllabus (e.g., a Unit, Module, or Lesson).
// It can contain other components and resources, creating a nested structure.
struct CourseComponent: Decodable, Identifiable {
    let sourcedId: String
    let title: String
    let sortOrder: Int
    let subComponents: [CourseComponent]
    let componentResources: [ComponentResource]

    var id: String { sourcedId }
}

// Represents a specific learning resource within a component (e.g., a video, article, or quiz).
struct ComponentResource: Decodable, Identifiable {
    let sourcedId: String
    let title: String
    let sortOrder: Int
    let resource: Resource

    var id: String { sourcedId }
}

// Represents the detailed metadata for a resource.
struct Resource: Decodable {
    let sourcedId: String
    let title: String
    let metadata: ResourceMetadata?
}

// Contains specific metadata about the resource type and location.
struct ResourceMetadata: Decodable {
    let type: String?      // e.g., "qti", "video", "text"
    let subType: String?   // e.g., "qti-stimulus", "qti-test"
    let url: String?
}
