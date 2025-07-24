import Foundation

/// TimeBack implementation of ContentProvider
/// Integrates with Alpha 1EdTech APIs (OneRoster, PowerPath, QTI)
class TimeBackContentProvider: ContentProvider {

    private let courseService: CourseService
    private let graphQLService: GraphQLService
    private let apiService: APIService

    init(courseService: CourseService = CourseService(),
         graphQLService: GraphQLService = .shared,
         apiService: APIService = .shared) {
        self.courseService = courseService
        self.graphQLService = graphQLService
        self.apiService = apiService
    }

    // MARK: - ContentProvider Implementation

    var providerName: String {
        "TimeBack 1EdTech Provider"
    }

    var supportsOffline: Bool {
        false // TimeBack requires online connection
    }

    func fetchCourses() async throws -> [Course] {
        // Use existing OneRoster API
        return try await courseService.fetchAllCourses()
    }

    func fetchCourse(id: String) async throws -> Course? {
        return try await courseService.fetchCourse(by: id)
    }

    func fetchLesson(courseId: String) async throws -> Lesson {
        // Fetch syllabus and map to unified Lesson model
        let syllabus = try await courseService.fetchSyllabus(for: courseId)
        return try mapSyllabusToLesson(syllabus, courseId: courseId)
    }

    func fetchResources(for componentId: String) async throws -> [LessonComponent] {
        // Fetch component resources and map to lesson components
        let resources = try await fetchComponentResources(componentId: componentId)
        return try resources.map { try mapResourceToLessonComponent($0) }
    }

    // MARK: - Private Mapping Functions

    private func mapSyllabusToLesson(_ syllabus: Syllabus, courseId: String) throws -> Lesson {
        // Map PowerPath syllabus to unified Lesson model
        var components: [LessonComponent] = []

        // Process syllabus components
        if let syllabusComponents = syllabus.components {
            for component in syllabusComponents {
                if let resources = component.resources {
                    for resource in resources {
                        if let lessonComponent = try? mapComponentResourceToLessonComponent(resource) {
                            components.append(lessonComponent)
                        }
                    }
                }
                // Also process sub-components recursively
                if let subComponents = component.subComponents {
                    for subComponent in subComponents {
                        if let resources = subComponent.resources {
                            for resource in resources {
                                if let lessonComponent = try? mapComponentResourceToLessonComponent(resource) {
                                    components.append(lessonComponent)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Determine age group from grades
        let ageGroup = determineAgeGroup(from: syllabus.courseGrades ?? [])

        return Lesson(
            id: syllabus.courseSourcedId ?? courseId,
            title: syllabus.courseTitle,
            duration: estimateDuration(for: components),
            ageGroup: ageGroup,
            components: components,
            courseId: courseId
        )
    }

    private func mapComponentResourceToLessonComponent(_ resource: ComponentResource) throws -> LessonComponent? {
        guard let metadata = resource.resource.metadata else { return nil }

        switch metadata.type {
        case "qti":
            return try mapQTIResource(resource)
        case "video":
            return try mapVideoResource(resource)
        case "article", "text":
            return try mapArticleResource(resource)
        case "exercise":
            return try mapExerciseResource(resource)
        default:
            print("Unknown resource type: \(metadata.type ?? "nil")")
            return nil
        }
    }

    private func mapResourceToLessonComponent(_ resource: Resource) throws -> LessonComponent {
        guard let metadata = resource.metadata else {
            throw ContentProviderError.invalidResourceMetadata
        }

        switch metadata.type {
        case "qti":
            return .quiz(QuizContent(
                id: resource.sourcedId,
                title: resource.title,
                qtiUrl: URL(string: metadata.url ?? "")!,
                timeLimit: nil,
                attempts: 3
            ))
        case "video":
            return .video(VideoContent(
                id: resource.sourcedId,
                title: resource.title,
                url: URL(string: metadata.url ?? "")!,
                duration: 600, // Default 10 minutes
                transcript: nil
            ))
        case "article", "text":
            return .article(ArticleContent(
                id: resource.sourcedId,
                title: resource.title,
                markdownContent: "Content from \(metadata.url ?? "unknown")",
                estimatedReadTime: 300 // Default 5 minutes
            ))
        default:
            throw ContentProviderError.unsupportedResourceType(metadata.type ?? "unknown")
        }
    }

    private func mapQTIResource(_ resource: ComponentResource) throws -> LessonComponent {
        guard let url = resource.resource.metadata?.url,
              let qtiUrl = URL(string: url) else {
            throw ContentProviderError.invalidQTIUrl
        }

        return .quiz(QuizContent(
            id: resource.resource.sourcedId,
            title: resource.title,
            qtiUrl: qtiUrl,
            timeLimit: nil,
            attempts: 3
        ))
    }

    private func mapVideoResource(_ resource: ComponentResource) throws -> LessonComponent {
        guard let url = resource.resource.metadata?.url,
              let videoUrl = URL(string: url) else {
            throw ContentProviderError.invalidVideoUrl
        }

        return .video(VideoContent(
            id: resource.resource.sourcedId,
            title: resource.title,
            url: videoUrl,
            duration: 600, // TODO: Fetch actual duration
            transcript: nil
        ))
    }

    private func mapArticleResource(_ resource: ComponentResource) throws -> LessonComponent {
        return .article(ArticleContent(
            id: resource.resource.sourcedId,
            title: resource.title,
            markdownContent: "Article content would be fetched here",
            estimatedReadTime: 300
        ))
    }

    private func mapExerciseResource(_ resource: ComponentResource) throws -> LessonComponent {
        return .exercise(ExerciseContent(
            id: resource.resource.sourcedId,
            title: resource.title,
            instructions: "Complete the following exercises",
            problemSets: []
        ))
    }

    // MARK: - Helper Functions

    private func fetchComponentResources(componentId: String) async throws -> [Resource] {
        // Fetch resources for a specific component
        let endpoint = "/ims/oneroster/rostering/v1p2/courses/components/\(componentId)/resources"

        struct ResourcesResponse: Decodable {
            let resources: [Resource]
        }

        let response: ResourcesResponse = try await apiService.request(
            baseURL: APIConstants.apiBaseURL,
            endpoint: endpoint,
            method: "GET"
        )

        return response.resources
    }

    private func determineAgeGroup(from grades: [String]) -> AgeGroup {
        // Map grade strings to age groups
        let gradeNumbers = grades.compactMap { grade -> Int? in
            if grade == "K" { return 0 }
            return Int(grade)
        }

        guard let minGrade = gradeNumbers.min() else { return .g912 }

        switch minGrade {
        case 0...2: return .k2
        case 3...5: return .g35
        case 6...8: return .g68
        default: return .g912
        }
    }

    private func estimateDuration(for components: [LessonComponent]) -> TimeInterval {
        // Estimate total duration based on component types
        var totalDuration: TimeInterval = 0

        for component in components {
            switch component {
            case .video(let content):
                totalDuration += content.duration
            case .article(let content):
                totalDuration += content.estimatedReadTime
            case .exercise:
                totalDuration += 900 // 15 minutes per exercise
            case .quiz:
                totalDuration += 1200 // 20 minutes per quiz
            }
        }

        return totalDuration
    }
}

// MARK: - Error Types

enum ContentProviderError: LocalizedError {
    case invalidResourceMetadata
    case unsupportedResourceType(String)
    case invalidQTIUrl
    case invalidVideoUrl
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResourceMetadata:
            return "Resource is missing required metadata"
        case .unsupportedResourceType(let type):
            return "Unsupported resource type: \(type)"
        case .invalidQTIUrl:
            return "Invalid QTI assessment URL"
        case .invalidVideoUrl:
            return "Invalid video URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
