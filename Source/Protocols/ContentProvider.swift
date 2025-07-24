import Foundation

/// Protocol defining the contract for all content providers
/// This allows us to swap between TimeBack, GitHub, or any other content source
protocol ContentProvider {
    /// Fetch all available courses
    func fetchCourses() async throws -> [Course]

    /// Fetch a specific course by ID
    func fetchCourse(id: String) async throws -> Course?

    /// Fetch the lesson/syllabus content for a course
    func fetchLesson(courseId: String) async throws -> Lesson

    /// Fetch available resources for a course component
    func fetchResources(for componentId: String) async throws -> [LessonComponent]

    /// Check if provider supports offline mode
    var supportsOffline: Bool { get }

    /// Provider name for debugging/logging
    var providerName: String { get }
}
