import Foundation
import Combine

enum SortOption: String, CaseIterable, Identifiable {
    case alphabetical = "Alphabetical"
    case byDate = "By Date (Newest)"
    var id: Self { self }
}

@MainActor
class DashboardViewModel: ObservableObject {

    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sortOption: SortOption = .alphabetical
    @Published var showAPIExplorer = false
    @Published var showContentCreator = false

    private var allCourses: [Course] = []
    private var cancellables = Set<AnyCancellable>()

    private let courseService: CourseService
    private let creationService: ContentCreationService

    init(courseService: CourseService = CourseService(), creationService: ContentCreationService = ContentCreationService()) {
        self.courseService = courseService
        self.creationService = creationService

        $sortOption
            .sink { [weak self] _ in
                self?.sortCourses()
            }
            .store(in: &cancellables)
    }

    func loadCourses() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await courseService.fetchAllCourses()
                print("--- Fetched Courses ---")
                response.forEach { course in
                    print("Title: \(course.title), Org ID: \(course.org.sourcedId)")
                }
                print("-----------------------")

                // Check if we have any "Arcane Studies" courses
                let arcaneCourses = response.filter { $0.title.contains("Arcane") }
                if !arcaneCourses.isEmpty {
                    print("Found \(arcaneCourses.count) Arcane Studies course(s):")
                    arcaneCourses.forEach { course in
                        print("  - ID: \(course.sourcedId), Title: \(course.title)")
                    }
                }

                self.allCourses = response
                self.sortCourses()
            } catch {
                print("❌ Failed to load courses: \(error)")

                // Provide more helpful error message for known issues
                if let apiError = error as? APIError,
                   case .custom(let message) = apiError {
                    self.errorMessage = message
                } else if error.localizedDescription.contains("Invalid enum value") {
                    self.errorMessage = "The course data contains invalid grade formats. Try creating a new test course instead."
                } else {
                    self.errorMessage = "Failed to load courses. Please try again. \nError: \(error.localizedDescription)"
                }

                // Show empty state
                self.allCourses = []
                self.sortCourses()
            }
            self.isLoading = false
        }
    }

    private func sortCourses() {
        switch sortOption {
        case .alphabetical:
            courses = allCourses.sorted { $0.title.lowercased() < $1.title.lowercased() }
        case .byDate:
            let formatter = ISO8601DateFormatter()
            courses = allCourses.sorted {
                let date1 = formatter.date(from: $0.dateLastModified) ?? Date.distantPast
                let date2 = formatter.date(from: $1.dateLastModified) ?? Date.distantPast
                return date1 > date2 // Descending for newest first
            }
        }
    }

    func createTestCourse() {
        // Try to find a suitable course or use the first available one
        let targetCourse = courses.first(where: {
            $0.org.sourcedId == "827d69dc-1312-4b07-89e3-c2e2d9822fb1" &&
            ($0.title == "Math" || $0.title == "Chemistry" || $0.title == "Test Course")
        }) ?? courses.first // Use any course if no specific match

        guard let course = targetCourse else {
            errorMessage = "No courses available. Please ensure courses are loaded first."
            return
        }

        print("📚 Creating test content for course: \(course.title) (ID: \(course.sourcedId))")

        isLoading = true
        errorMessage = nil

        Task {
            do {
                print("🎯 Selected existing course: \(course.title) (ID: \(course.sourcedId))")
                try await creationService.addContentToExistingCourse(
                    courseId: course.sourcedId,
                    courseTitle: course.title
                )

                // Refresh to see if the content appears
                await MainActor.run {
                    print("Content addition successful, refreshing course list...")
                }

                // Small delay to ensure the API has processed the new content
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                self.loadCourses()

                // Check if the course now has content
                await verifySpecificCourseContent(courseId: course.sourcedId, courseTitle: course.title)
            } catch {
                self.errorMessage = "Failed to add content to course: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func verifySpecificCourseContent(courseId: String, courseTitle: String) async {
        print("\n🔍 Verifying content for course: \(courseTitle)")
        do {
            let syllabus = try await courseService.fetchSyllabus(for: courseId)
            if let components = syllabus.components, !components.isEmpty {
                print("✅ Course now has \(components.count) component(s)")
                for component in components {
                    print("  - Component: \(component.title)")
                    print("    Resources: \(component.componentResources?.count ?? 0)")
                    if let resources = component.componentResources {
                        for resource in resources {
                            print("      - \(resource.title)")
                        }
                    }
                }
            } else {
                print("⚠️  Course syllabus still has no components")
                print("  This suggests PowerPath is not recognizing our component structure")
            }
        } catch {
            print("❌ Failed to fetch syllabus: \(error)")
        }
    }
}
