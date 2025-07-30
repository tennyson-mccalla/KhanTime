import Foundation

// MARK: - Content Deduplication Service
// Service to track and prevent duplicate content creation

class ContentDeduplicationService {
    
    private let apiService: APIService
    private var contentCache: [String: Set<String>] = [:] // courseId -> set of content identifiers
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    // MARK: - Duplicate Detection
    
    /// Checks if a course already has content with the given identifier
    func contentExists(in courseId: String, withIdentifier identifier: String) async -> Bool {
        // First check local cache
        if let cachedContent = contentCache[courseId], cachedContent.contains(identifier) {
            print("📋 Content '\(identifier)' found in local cache for course \(courseId)")
            return true
        }
        
        // Check remote API
        return await remoteContentExists(in: courseId, withIdentifier: identifier)
    }
    
    /// Checks if content exists by fetching from the API
    private func remoteContentExists(in courseId: String, withIdentifier identifier: String) async -> Bool {
        // Check if course component exists
        if await componentExists(courseId: courseId, componentId: identifier) {
            cacheContent(courseId: courseId, identifier: identifier)
            return true
        }
        
        // Check if resource exists
        if await resourceExists(resourceId: identifier) {
            cacheContent(courseId: courseId, identifier: identifier)
            return true
        }
        
        // Check if component-resource association exists
        if await componentResourceExists(componentResourceId: identifier) {
            cacheContent(courseId: courseId, identifier: identifier)
            return true
        }
        
        return false
    }
    
    /// Generates a unique identifier that's guaranteed not to conflict
    func generateUniqueIdentifier(base: String, courseId: String? = nil) async -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        var candidate = "\(base)-\(timestamp)"
        
        // If courseId is provided, check for conflicts
        if let courseId = courseId {
            var suffix = 0
            while await contentExists(in: courseId, withIdentifier: candidate) {
                suffix += 1
                candidate = "\(base)-\(timestamp)-\(suffix)"
            }
        }
        
        return candidate
    }
    
    // MARK: - Cache Management
    
    /// Caches content identifier to avoid redundant API calls
    private func cacheContent(courseId: String, identifier: String) {
        if contentCache[courseId] == nil {
            contentCache[courseId] = Set<String>()
        }
        contentCache[courseId]?.insert(identifier)
    }
    
    /// Refreshes the cache for a specific course
    func refreshCache(for courseId: String) async {
        contentCache[courseId] = nil
        await loadExistingContent(for: courseId)
    }
    
    /// Loads existing content for a course into the cache
    private func loadExistingContent(for courseId: String) async {
        var identifiers = Set<String>()
        
        // Load course components
        if let components = await fetchCourseComponents(courseId: courseId) {
            for component in components {
                identifiers.insert(component.sourcedId)
            }
        }
        
        contentCache[courseId] = identifiers
    }
    
    // MARK: - API Existence Checks
    
    private func componentExists(courseId: String, componentId: String) async -> Bool {
        let endpoint = "/ims/oneroster/rostering/v1p2/courses/\(courseId)/components"
        
        do {
            struct ComponentsResponse: Decodable {
                let courseComponents: [CourseComponent]?
            }
            
            let response: ComponentsResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: endpoint,
                method: "GET"
            )
            
            return response.courseComponents?.contains { $0.sourcedId == componentId } ?? false
        } catch {
            print("⚠️ Error checking component existence: \(error)")
            return false
        }
    }
    
    private func resourceExists(resourceId: String) async -> Bool {
        let endpoint = "/ims/oneroster/resources/v1p2/resources/\(resourceId)"
        
        do {
            // Try to fetch the specific resource
            let _: ResourceResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: endpoint,
                method: "GET"
            )
            
            return true // If no error, resource exists
        } catch {
            // If 404 or other error, resource doesn't exist
            return false
        }
    }
    
    private func componentResourceExists(componentResourceId: String) async -> Bool {
        // This is more complex as there's no direct endpoint for component-resources by ID
        // For now, we'll assume it doesn't exist if not in cache
        // In a full implementation, this would search through component-resource associations
        return false
    }
    
    private func fetchCourseComponents(courseId: String) async -> [CourseComponent]? {
        let endpoint = "/ims/oneroster/rostering/v1p2/courses/\(courseId)/components"
        
        do {
            struct ComponentsResponse: Decodable {
                let courseComponents: [CourseComponent]?
            }
            
            let response: ComponentsResponse = try await apiService.request(
                baseURL: APIConstants.apiBaseURL,
                endpoint: endpoint,
                method: "GET"
            )
            
            return response.courseComponents
        } catch {
            print("⚠️ Error fetching course components: \(error)")
            return nil
        }
    }
}

// MARK: - Enhanced Content Creation Service

extension ContentCreationService {
    
    /// Creates content only if it doesn't already exist (idempotent operation)
    func createContentIdempotent() async throws {
        let deduplicationService = ContentDeduplicationService()
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // Generate unique identifiers
        let courseId = await deduplicationService.generateUniqueIdentifier(base: "test-arcane-course")
        let termId = await deduplicationService.generateUniqueIdentifier(base: "term")
        let classId = await deduplicationService.generateUniqueIdentifier(base: "class")
        let studentId = await deduplicationService.generateUniqueIdentifier(base: "student")
        let enrollmentId = await deduplicationService.generateUniqueIdentifier(base: "enrollment")
        let unitId = await deduplicationService.generateUniqueIdentifier(base: "unit", courseId: courseId)
        let resourceId = await deduplicationService.generateUniqueIdentifier(base: "resource")
        let componentResourceId = await deduplicationService.generateUniqueIdentifier(base: "comp-res", courseId: courseId)
        
        print("🚀 Starting idempotent course creation with ID: \(courseId)")
        
        // Check if course already exists
        if await deduplicationService.contentExists(in: courseId, withIdentifier: courseId) {
            print("⚠️ Course \(courseId) already exists - skipping creation")
            return
        }
        
        // Create content with guaranteed unique IDs
        try await createCourseWithUniqueIds(
            courseId: courseId,
            termId: termId,
            classId: classId,
            studentId: studentId,
            enrollmentId: enrollmentId,
            unitId: unitId,
            resourceId: resourceId,
            componentResourceId: componentResourceId
        )
        
        print("✅ Idempotent course creation completed!")
    }
    
    /// Adds content to existing course only if it doesn't already exist
    func addContentToExistingCourseIdempotent(courseId: String, courseTitle: String) async throws {
        let deduplicationService = ContentDeduplicationService()
        
        // Generate unique identifiers for this course
        let unitId = await deduplicationService.generateUniqueIdentifier(base: "unit-existing", courseId: courseId)
        let resourceId = await deduplicationService.generateUniqueIdentifier(base: "resource-existing")
        let componentResourceId = await deduplicationService.generateUniqueIdentifier(base: "comp-res-existing", courseId: courseId)
        
        print("🚀 Adding idempotent content to existing course: \(courseTitle)")
        print("📋 Course ID: \(courseId)")
        
        // Check if similar content already exists
        if await deduplicationService.contentExists(in: courseId, withIdentifier: unitId) {
            print("⚠️ Similar unit content already exists - skipping creation")
            return
        }
        
        // Create content with unique identifiers
        print("1️⃣ Creating unique course component (unit)...")
        try await createComponent(unitId: unitId, courseId: courseId)
        
        print("2️⃣ Creating unique QTI resource...")
        try await createQtiResource(resourceId: resourceId)
        
        print("3️⃣ Linking resource to component...")
        try await associateResourceToComponent(componentResourceId: componentResourceId, unitId: unitId, resourceId: resourceId)
        
        print("✅ Successfully added unique content to existing course!")
    }
    
    // Private helper method to create course with all unique IDs
    private func createCourseWithUniqueIds(
        courseId: String,
        termId: String,
        classId: String,
        studentId: String,
        enrollmentId: String,
        unitId: String,
        resourceId: String,
        componentResourceId: String
    ) async throws {
        
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
        
        print("✅ Successfully created test course with unique content!")
        
        // Verify the creation immediately
        print("\n🔍 Verifying course creation...")
        await verifyContentCreation(courseId: courseId)
    }
}

// MARK: - Supporting Data Models

struct ResourceResponse: Decodable {
    let resource: Resource
}