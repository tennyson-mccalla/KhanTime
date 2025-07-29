import Foundation

class CourseService {

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

            /// Fetches all courses from the OneRoster API.
    func fetchAllCourses() async throws -> [Course] {
        // Try to fetch all courses, starting with smaller batches
        var allCourses: [Course] = []
        let limits = [100, 500, 1000, 3000] // Try progressively larger limits

        for limit in limits {
            do {
                print("🔍 Trying to fetch \(limit) courses...")
                let endpoint = "/ims/oneroster/rostering/v1p2/courses?limit=\(limit)"

                // First, let's see what the raw response looks like
                let url = URL(string: APIConstants.apiBaseURL + endpoint)!
                var request = URLRequest(url: url)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                if let accessToken = try await AuthService.shared.getValidAccessToken() {
                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                }

                let (data, httpResponse) = try await URLSession.shared.data(for: request)

                guard let httpResponse = httpResponse as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("❌ HTTP error for limit \(limit)")
                    continue
                }

                // Try to decode, but handle errors gracefully
                let decoder = JSONDecoder()

                // First try normal decoding
                if let response = try? decoder.decode(CourseListResponse.self, from: data) {
                    print("✅ Successfully decoded \(response.courses.count) courses")
                    return response.courses
                } else {
                    // If that fails, log the error and try to parse what we can
                    print("⚠️ Decoding failed, attempting manual parsing...")

                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let coursesArray = json["courses"] as? [[String: Any]] {

                        // Manually parse courses, skipping ones with bad data
                        for courseDict in coursesArray {
                            if let sourcedId = courseDict["sourcedId"] as? String,
                               let title = courseDict["title"] as? String,
                               let dateLastModified = courseDict["dateLastModified"] as? String,
                               let orgDict = courseDict["org"] as? [String: String],
                               let orgSourcedId = orgDict["sourcedId"] {

                                // Create a minimal course object
                                let course = Course(
                                    sourcedId: sourcedId,
                                    title: title,
                                    courseCode: courseDict["courseCode"] as? String,
                                    grades: nil, // Skip grades to avoid validation issues
                                    dateLastModified: dateLastModified,
                                    org: OrgRef(sourcedId: orgSourcedId)
                                )
                                allCourses.append(course)
                            }
                        }

                        if !allCourses.isEmpty {
                            print("✅ Manually parsed \(allCourses.count) courses")
                            return allCourses
                        }
                    }
                }
            } catch {
                print("❌ Failed to fetch \(limit) courses: \(error)")
                if limit == 100 && allCourses.isEmpty {
                    // If even 100 fails, something is seriously wrong
                    throw error
                }
            }
        }

        // Return whatever we got, even if it's partial
        if !allCourses.isEmpty {
            return allCourses
        }

        // If we got nothing, throw an error
        throw APIError.custom("Unable to fetch courses. The API may have data validation issues.")
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
            // First try to get raw data to see what the API returns
            let url = URL(string: APIConstants.apiBaseURL + endpoint)!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            if let accessToken = try await AuthService.shared.getValidAccessToken() {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }

            let (data, _) = try await URLSession.shared.data(for: request)

            // Log the raw response to understand the structure
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📋 Raw syllabus response for \(courseId):")
                print(jsonString.prefix(500)) // Print first 500 chars
            }

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
    
    /// Searches for ae.studio 3rd grade language content in TimeBack
    func searchAEStudioLanguageContent() async throws -> [Course] {
        print("🔍 Searching for ae.studio 3rd grade language content...")
        
        // First, get all courses and filter for relevant content
        let allCourses = try await fetchAllCourses()
        
        // Filter for language/grade-related courses
        let languageCourses = allCourses.filter { course in
            let titleLower = course.title.lowercased()
            return titleLower.contains("language") ||
                   titleLower.contains("english") ||
                   titleLower.contains("reading") ||
                   titleLower.contains("grade") ||
                   titleLower.contains("3rd") ||
                   titleLower.contains("elementary")
        }
        
        print("📚 Found \(languageCourses.count) potentially relevant courses:")
        for course in languageCourses.prefix(10) {
            print("  - \(course.title) (ID: \(course.sourcedId))")
        }
        
        if languageCourses.isEmpty {
            print("⚠️ No language-related courses found. Sample course titles:")
            for course in allCourses.prefix(5) {
                print("  - \(course.title)")
            }
        }
        
        return languageCourses
    }
    
    /// Fetches organizations to find ae.studio
    func findAEStudioOrganization() async throws -> [String: Any]? {
        let endpoint = "/ims/oneroster/rostering/v1p2/orgs"
        
        do {
            let url = URL(string: APIConstants.apiBaseURL + endpoint)!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let accessToken = try await AuthService.shared.getValidAccessToken() {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let orgs = json["orgs"] as? [[String: Any]] {
                
                print("🏢 Found \(orgs.count) organizations:")
                for org in orgs {
                    if let name = org["name"] as? String,
                       let sourcedId = org["sourcedId"] as? String {
                        print("  - \(name) (ID: \(sourcedId))")
                        
                        if name.lowercased().contains("ae.studio") || 
                           name.lowercased().contains("aestudio") ||
                           name.lowercased().contains("ae studio") {
                            print("    ⭐ FOUND ae.studio organization!")
                            return org
                        }
                    }
                }
            }
        } catch {
            print("❌ Error fetching organizations: \(error)")
        }
        
        return nil
    }
}
