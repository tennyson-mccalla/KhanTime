import Foundation

// This service is responsible for creating new content in the TimeBack platform.
// It orchestrates the multiple API calls required to build a new course with content.
class ContentCreationService {

    private let apiService: APIService

    // A known, valid org ID is required for course creation.
    // In a real app, this would likely be fetched or configured dynamically.
    // NOTE: If your courses aren't showing up, check if this org ID matches
    // what your authentication token has access to. You may need to use an
    // org ID from your fetched courses list (check the logs for valid org IDs).
    private let orgSourcedId = "827d69dc-1312-4b07-89e3-c2e2d9822fb1"

    // A known, valid QTI test URL.
    private let sampleQtiTestUrl = "https://qti.alpha-1edtech.com/api/assessment-tests/test-67aa14ec-3-PP.1"


    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    // This is the main function that chains all the creation steps together.
    func createTestCourseWithQTI() async throws {
        let timestamp = Int(Date().timeIntervalSince1970)
        let courseId = "test-arcane-course-\(timestamp)"
        let termId = "term-\(timestamp)"
        let classId = "class-\(timestamp)"
        let studentId = "student-\(timestamp)"
        let enrollmentId = "enrollment-\(timestamp)"
        let unitId = "unit-\(timestamp)"
        let resourceId = "resource-\(timestamp)"
        let componentResourceId = "comp-res-\(timestamp)"

        print("🚀 Starting course creation with ID: \(courseId)")

        // Step 1: Create the course
        print("1️⃣ Creating course...")
        try await createCourse(courseId: courseId)

        // Step 2: Create a term
        print("2️⃣ Creating term...")
        try await createTerm(termId: termId)

        // Step 3: Create a class associated with the course and term
        print("3️⃣ Creating class...")
        try await createClass(classId: classId, courseId: courseId, termId: termId)

        // Step 4: Create a student
        print("4️⃣ Creating student...")
        try await createStudent(studentId: studentId)

        // Step 5: Enroll the student in the class
        print("5️⃣ Enrolling student...")
        try await enrollStudent(enrollmentId: enrollmentId, studentId: studentId, classId: classId)

        // Step 6: Create a course component (e.g., a unit)
        print("6️⃣ Creating course component (unit)...")
        try await createComponent(unitId: unitId, courseId: courseId)

        // Step 7: Create a QTI resource (e.g., a quiz)
        print("7️⃣ Creating QTI resource...")
        try await createQtiResource(resourceId: resourceId)

        // Step 8: Associate the resource with the component
        print("8️⃣ Linking resource to component...")
        try await associateResourceToComponent(componentResourceId: componentResourceId, unitId: unitId, resourceId: resourceId)

        print("✅ Successfully created test course with QTI content!")
        print("📋 Course ID: \(courseId)")
        print("📚 Course Title: Advanced Arcane Studies")
        print("📝 Unit: Introduction to Incantations")
        print("🎯 QTI Resource: Quiz - Basic Levitation Spell")
        print("\n⚠️  NOTE: It may take a few seconds for the content to be available via the syllabus API")

        // Verify the creation immediately
        print("\n🔍 Verifying course creation...")
        await verifyContentCreation(courseId: courseId)
    }

    // New method to add content to an existing course
    func addContentToExistingCourse(courseId: String, courseTitle: String) async throws {
        let timestamp = Int(Date().timeIntervalSince1970)
        let unitId = "unit-existing-\(timestamp)"
        let resourceId = "resource-existing-\(timestamp)"
        let componentResourceId = "comp-res-existing-\(timestamp)"

        print("🚀 Adding content to existing course: \(courseTitle)")
        print("📋 Course ID: \(courseId)")

        // Step 1: Create a course component (unit) for the existing course
        print("1️⃣ Creating course component (unit)...")
        try await createComponent(unitId: unitId, courseId: courseId)

        // Step 2: Create a QTI resource
        print("2️⃣ Creating QTI resource...")
        try await createQtiResource(resourceId: resourceId)

        // Step 3: Associate the resource with the component
        print("3️⃣ Linking resource to component...")
        try await associateResourceToComponent(componentResourceId: componentResourceId, unitId: unitId, resourceId: resourceId)

        print("✅ Successfully added content to existing course!")
        print("📝 New Unit: Introduction to Incantations")
        print("🎯 QTI Resource: Quiz - Basic Levitation Spell")

        // Verify the content was added
        print("\n🔍 Verifying content addition...")
        await verifyContentCreation(courseId: courseId)

        // Also check the syllabus directly
        let syllabusEndpoint = "/powerpath/syllabus/\(courseId)"
        do {
            let response: SyllabusResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: syllabusEndpoint,
                method: "GET"
            )

            if let components = response.syllabus.components {
                print("📚 Syllabus now has \(components.count) component(s)")
                for component in components {
                    print("  - \(component.title)")
                }
            } else {
                print("⚠️  Syllabus still has no components")
            }
        } catch {
            print("❌ Failed to fetch syllabus: \(error)")
        }
    }

    private func verifyContentCreation(courseId: String) async {
        // Check OneRoster direct fetch
        let endpoint = "/ims/oneroster/rostering/v1p2/courses/\(courseId)"
        do {
            struct SingleCourseResponse: Decodable {
                let course: Course
            }
            let _: SingleCourseResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: endpoint,
                method: "GET"
            )
            print("✅ Course exists in OneRoster")
        } catch {
            print("❌ Course NOT found in OneRoster: \(error)")
        }

        // Check OneRoster components
        let componentsEndpoint = "/ims/oneroster/rostering/v1p2/courses/\(courseId)/components"
        do {
            struct ComponentsResponse: Decodable {
                let courseComponents: [CourseComponent]?
            }
            let response: ComponentsResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: componentsEndpoint,
                method: "GET"
            )
            if let components = response.courseComponents {
                print("✅ OneRoster reports \(components.count) component(s)")
                for comp in components {
                    print("   - \(comp.title)")
                }
            } else {
                print("⚠️  OneRoster reports no components")
            }
        } catch {
            print("❌ Failed to fetch OneRoster components: \(error)")
        }

        // Check PowerPath syllabus
        let syllabusEndpoint = "/powerpath/syllabus/\(courseId)"
        do {
            let _: SyllabusResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: syllabusEndpoint,
                method: "GET"
            )
            print("✅ Syllabus available in PowerPath")
        } catch {
            print("❌ Syllabus NOT available in PowerPath: \(error)")
            print("   This might indicate a sync delay between OneRoster and PowerPath")
        }
    }

    // MARK: - Private Helper Functions

    private func createTerm(termId: String) async throws {
        let endpoint = "/ims/oneroster/rostering/v1p2/academicSessions"
        let payload = CreateAcademicSessionPayload(
            academicSession: CreateAcademicSession(
                sourcedId: termId,
                status: "active",
                title: "Test Term \(UUID().uuidString.prefix(4))",
                type: "term",
                startDate: "2025-01-01",
                endDate: "2025-12-31",
                schoolYear: "2025",
                org: OrgRef(sourcedId: orgSourcedId)
            )
        )
        try await makePostRequest(endpoint: endpoint, payload: payload, description: "Academic Session")
    }

    private func createStudent(studentId: String) async throws {
        let endpoint = "/ims/oneroster/rostering/v1p2/users"
        let payload = CreateUserPayload(
            user: CreateUser(
                sourcedId: studentId,
                status: "active",
                givenName: "Test",
                familyName: "Student-\(UUID().uuidString.prefix(4))",
                roles: [
                    UserRolePayload(
                        roleType: "primary",
                        role: "student",
                        org: OrgRef(sourcedId: orgSourcedId)
                    )
                ],
                enabledUser: true
            )
        )
        try await makePostRequest(endpoint: endpoint, payload: payload, description: "Student")
    }

    private func createCourse(courseId: String) async throws {
        let endpoint = "/ims/oneroster/rostering/v1p2/courses"
        let courseTitle = "Advanced Arcane Studies"
        print("Creating course with ID: \(courseId) and title: '\(courseTitle)'")

        let payload = CreateCoursePayload(
            course: CreateCourse(
                sourcedId: courseId,
                status: "active",
                title: courseTitle,
                courseCode: "ARCANE-101",
                grades: ["11", "12"],
                subjects: ["Magic"],
                org: OrgRef(sourcedId: orgSourcedId)
            )
        )
        try await makePostRequest(endpoint: endpoint, payload: payload, description: "Course")
    }

    private func createClass(classId: String, courseId: String, termId: String) async throws {
        let endpoint = "/ims/oneroster/rostering/v1p2/classes"
        let payload = CreateClassPayload(
            class: CreateClass(
                sourcedId: classId,
                status: "active",
                title: "Advanced Arcane Studies - Section 1",
                classCode: "ARC-101-S1",
                classType: "scheduled",
                location: "Room of Requirement",
                grades: ["11", "12"],
                subjects: ["Magic"],
                course: CourseRef(sourcedId: courseId),
                org: OrgRef(sourcedId: orgSourcedId),
                terms: [TermRef(sourcedId: termId)]
            )
        )
        try await makePostRequest(endpoint: endpoint, payload: payload, description: "Class")
    }

    private func enrollStudent(enrollmentId: String, studentId: String, classId: String) async throws {
        let endpoint = "/ims/oneroster/rostering/v1p2/enrollments"
        let payload = CreateEnrollmentPayload(
            enrollment: CreateEnrollment(
                sourcedId: enrollmentId,
                status: "active",
                role: "student",
                primary: true,
                beginDate: "2025-01-01",
                endDate: "2025-12-31",
                user: UserRef(sourcedId: studentId),
                class: ClassRef(sourcedId: classId)
            )
        )
        try await makePostRequest(endpoint: endpoint, payload: payload, description: "Enrollment")
    }

    private func createComponent(unitId: String, courseId: String) async throws {
        let endpoint = "/ims/oneroster/rostering/v1p2/courses/components"
        let payload = CreateComponentPayload(
            courseComponent: CreateComponent(
                sourcedId: unitId,
                status: "active",
                title: "Unit 1: Introduction to Incantations",
                sortOrder: 1,
                courseSourcedId: courseId,
                course: ResourceRef(sourcedId: courseId),
                parentComponent: nil // This is a top-level component
            )
        )
        try await makePostRequest(endpoint: endpoint, payload: payload, description: "Component")
    }

    private func createQtiResource(resourceId: String) async throws {
        let endpoint = "/ims/oneroster/resources/v1p2/resources"
        let payload = CreateResourcePayload(
            resource: CreateResource(
                sourcedId: resourceId,
                status: "active",
                title: "Quiz: Basic Levitation Spell",
                vendorResourceId: "qti-test-levitation-1",
                metadata: ResourceMetadataPayload(
                    type: "qti",
                    subType: "qti-test",
                    url: sampleQtiTestUrl
                )
            )
        )
        try await makePostRequest(endpoint: endpoint, payload: payload, description: "Resource")
    }

    private func associateResourceToComponent(componentResourceId: String, unitId: String, resourceId: String) async throws {
        let endpoint = "/ims/oneroster/rostering/v1p2/courses/component-resources"
        let payload = CreateComponentResourcePayload(
            componentResource: CreateComponentResource(
                sourcedId: componentResourceId,
                status: "active",
                title: "Levitation Quiz",
                sortOrder: 1,
                courseComponent: CourseComponentRef(sourcedId: unitId),
                resource: ResourceRef(sourcedId: resourceId)
            )
        )
        try await makePostRequest(endpoint: endpoint, payload: payload, description: "Component-Resource Association")
    }

    // Generic helper to make a POST request with an Encodable payload
    private func makePostRequest<T: Encodable>(endpoint: String, payload: T, description: String) async throws {
        do {
            let body = try JSONEncoder().encode(payload)
            // The response to these POSTs is often not needed, so we decode to a dummy type
            let _: EmptyResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: endpoint,
                method: "POST",
                body: body
            )
            print("Successfully created \(description).")
        } catch {
            print("Failed to create \(description): \(error)")
            throw error
        }
    }
}

// A helper struct to decode empty JSON responses, like "{}"
struct EmptyResponse: Decodable {}
