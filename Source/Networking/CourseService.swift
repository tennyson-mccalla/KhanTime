import Foundation

class CourseService {

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    /// Fetches all courses from the OneRoster API.
    func fetchAllCourses() async throws -> [Course] {
        let endpoint = "/ims/oneroster/rostering/v1p2/courses?limit=3000"

        do {
            let response: CourseListResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: endpoint,
                method: "GET"
            )
            return response.courses
        } catch {
            print("Error fetching courses: \(error)")
            throw error
        }
    }

    /// Fetches a specific course by ID from the OneRoster API.
    func fetchCourse(by courseId: String) async throws -> Course? {
        let endpoint = "/ims/oneroster/rostering/v1p2/courses/\(courseId)"

        do {
            struct SingleCourseResponse: Decodable {
                let course: Course
            }
            let response: SingleCourseResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: endpoint,
                method: "GET"
            )
            print("✅ Found course via direct fetch: \(response.course.title)")
            return response.course
        } catch {
            print("❌ Failed to fetch course \(courseId) directly: \(error)")
            return nil
        }
    }

    /// Fetches the detailed syllabus for a specific course.
    func fetchSyllabus(for courseId: String) async throws -> Syllabus {
        let endpoint = "/powerpath/syllabus/\(courseId)"

        do {
            let response: SyllabusResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: endpoint,
                method: "GET"
            )
            return response.syllabus
        } catch {
            print("Error fetching syllabus for course \(courseId): \(error)")
            throw error
        }
    }

    /// Fetches all components for a specific course from OneRoster API
    func fetchCourseComponents(courseId: String) async throws -> [CourseComponent] {
        let endpoint = "/ims/oneroster/rostering/v1p2/courses/\(courseId)/components"

        do {
            struct ComponentsResponse: Decodable {
                let courseComponents: [CourseComponent]
            }
            let response: ComponentsResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: endpoint,
                method: "GET"
            )
            print("📦 Found \(response.courseComponents.count) components via OneRoster direct fetch")
            return response.courseComponents
        } catch {
            print("Error fetching course components: \(error)")
            throw error
        }
    }
}
