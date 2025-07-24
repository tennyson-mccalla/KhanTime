import Foundation

// The main response from the /powerpath/syllabus/:courseSourcedId endpoint
struct SyllabusResponse: Decodable {
    let syllabus: Syllabus
}

// Represents the overall syllabus structure for a course
struct Syllabus: Decodable {
    let course: Course?  // The syllabus contains a course object
    let subComponents: [CourseComponent]?  // Changed from 'components' to 'subComponents'

    // Computed properties for backward compatibility
    var components: [CourseComponent]? {
        return subComponents
    }

    var courseSourcedId: String? {
        return course?.sourcedId
    }

    var courseTitle: String {
        return course?.title ?? "Unknown Course"
    }

    var courseGrades: [String]? {
        return course?.grades
    }
}

// Represents a component in the syllabus (e.g., a Unit, Module, or Lesson).
// It can contain other components and resources, creating a nested structure.
struct CourseComponent: Decodable, Identifiable {
    let sourcedId: String
    let title: String
    let sortOrder: Int
    let subComponents: [CourseComponent]?  // Made optional - not all components have sub-components
    let componentResources: [ComponentResource]?  // Made optional

    var id: String { sourcedId }

    // Computed property for backward compatibility
    var resources: [ComponentResource]? {
        return componentResources
    }

    // Custom decoder to handle optional fields
    enum CodingKeys: String, CodingKey {
        case sourcedId
        case title
        case sortOrder
        case subComponents
        case componentResources
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sourcedId = try container.decode(String.self, forKey: .sourcedId)
        self.title = try container.decode(String.self, forKey: .title)
        self.sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        self.subComponents = try container.decodeIfPresent([CourseComponent].self, forKey: .subComponents)
        self.componentResources = try container.decodeIfPresent([ComponentResource].self, forKey: .componentResources)
    }
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
    let status: String?
    let title: String
    let vendorResourceId: String?
    let metadata: ResourceMetadata?
}

// Contains specific metadata about the resource type and location.
struct ResourceMetadata: Decodable {
    let type: String?      // e.g., "qti", "video", "text"
    let subType: String?   // e.g., "qti-stimulus", "qti-test"
    let url: String?
}
