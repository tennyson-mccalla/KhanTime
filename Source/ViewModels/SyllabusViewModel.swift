import Foundation
import Combine

@MainActor
class SyllabusViewModel: ObservableObject {

    @Published var syllabus: Syllabus?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let courseService: CourseService
    let course: Course

    init(course: Course, courseService: CourseService = CourseService()) {
        self.course = course
        self.courseService = courseService
    }

    func loadSyllabus() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                print("Fetching syllabus for course: \(course.title) (ID: \(course.sourcedId))")
                self.syllabus = try await courseService.fetchSyllabus(for: course.sourcedId)

                if let syllabus = self.syllabus {
                    print("Syllabus loaded successfully")
                    print("Components count: \(syllabus.components?.count ?? 0)")
                    if let components = syllabus.components {
                        for component in components {
                            print("  - Component: \(component.title)")
                            print("    Sub-components: \(component.subComponents?.count ?? 0)")
                            print("    Resources: \(component.componentResources?.count ?? 0)")
                        }
                    }
                } else {
                    print("Syllabus is nil")
                }
            } catch {
                print("Failed to fetch syllabus: \(error)")
                self.errorMessage = "Failed to load syllabus. Please try again. \nError: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
}
