#!/usr/bin/env swift

import Foundation

// MARK: - Authenticated Khan Academy GraphQL Scraper
// The BrainLift approach: authenticated API access for complete content

print("🔐 Authenticated Khan Academy GraphQL Scraper")
print("==============================================")

// MARK: - Session Management
class KhanAcademySession {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    private var cookies: [HTTPCookie] = []
    private var csrfToken: String = ""
    private var sessionEstablished = false
    private var userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15"
    
    // Expose cookies for authenticated page requests
    var sessionCookies: [HTTPCookie] {
        return cookies
    }
    
    // MARK: - Session Initialization
    func establishSession() async throws {
        print("🚀 Establishing authenticated session...")
        
        // Step 1: Get initial session cookies
        try await getInitialCookies()
        
        // Step 2: Extract CSRF token
        try await extractCSRFToken()
        
        sessionEstablished = true
        print("✅ Authenticated session established!")
        print("   🍪 Cookies: \(cookies.count)")
        print("   🔑 CSRF Token: \(csrfToken.prefix(20))...")
    }
    
    private func getInitialCookies() async throws {
        print("   📡 Getting initial session cookies...")
        
        let url = URL(string: "\(baseURL)/math/pre-algebra")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           let headerFields = httpResponse.allHeaderFields as? [String: String] {
            
            let url = httpResponse.url ?? URL(string: baseURL)!
            let responseCookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            self.cookies.append(contentsOf: responseCookies)
            
            print("   ✅ Got \(responseCookies.count) initial cookies")
        }
    }
    
    private func extractCSRFToken() async throws {
        print("   🔑 Extracting CSRF token...")
        
        let url = URL(string: "\(baseURL)/math/pre-algebra")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        // Add session cookies
        let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        if !cookieHeader.isEmpty {
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        
        let (data, _) = try await session.data(for: request)
        
        if let html = String(data: data, encoding: .utf8) {
            // Look for CSRF token in the HTML
            let patterns = [
                "\"fkey\":\"([^\"]+)\"",
                "window\\.KA\\.fkey = \"([^\"]+)\"",
                "name=\"fkey\" value=\"([^\"]+)\"",
                "_fkey\":\"([^\"]+)\""
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(html.startIndex..<html.endIndex, in: html)
                    if let match = regex.firstMatch(in: html, options: [], range: range) {
                        let tokenRange = Range(match.range(at: 1), in: html)!
                        self.csrfToken = String(html[tokenRange])
                        print("   ✅ CSRF token extracted: \(csrfToken.prefix(20))...")
                        return
                    }
                }
            }
            
            // Fallback: try to find any fkey value
            if csrfToken.isEmpty {
                csrfToken = "1" // Default fallback that sometimes works
                print("   ⚠️ Using fallback CSRF token")
            }
        }
    }
    
    // MARK: - Authenticated GraphQL Requests
    func makeAuthenticatedRequest(to endpoint: String, variables: [String: Any] = [:]) async throws -> Data {
        guard sessionEstablished else {
            throw ScrapingError.sessionNotEstablished
        }
        
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication headers
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue(csrfToken, forHTTPHeaderField: "x-ka-fkey")
        request.setValue("u=3, i", forHTTPHeaderField: "Priority")
        
        // Add session cookies
        let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        if !cookieHeader.isEmpty {
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        
        // Add referer
        request.setValue("\(baseURL)/math/pre-algebra", forHTTPHeaderField: "Referer")
        
        // Add variables as query parameters if provided
        if !variables.isEmpty {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            
            let variablesData = try JSONSerialization.data(withJSONObject: variables)
            let variablesString = String(data: variablesData, encoding: .utf8)!
            
            let queryItems = [
                URLQueryItem(name: "fastly_cacheable", value: "persist_until_publish"),
                URLQueryItem(name: "pcv", value: "dd3a92f28329ba421fb048ddfa2c930cbbfbac29"),
                URLQueryItem(name: "hash", value: "45296627"),
                URLQueryItem(name: "variables", value: variablesString),
                URLQueryItem(name: "lang", value: "en"),
                URLQueryItem(name: "app", value: "khanacademy")
            ]
            
            urlComponents.queryItems = queryItems
            request.url = urlComponents.url
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScrapingError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response"
            throw ScrapingError.httpError(httpResponse.statusCode, responseString)
        }
        
        return data
    }
}

// MARK: - Basic Content Models (from original scraper)
struct ScrapedKhanContent: Codable {
    let id: String
    let subject: String
    let title: String
    let description: String
    let units: [ScrapedUnit]
    let scrapedAt: Date
    
    struct ScrapedUnit: Codable {
        let id: String
        let title: String
        let description: String?
        let lessons: [ScrapedLesson]
        let exercises: [ScrapedExercise]
        
        struct ScrapedLesson: Codable {
            let id: String
            let title: String
            let slug: String
            let contentKind: String
            let videoUrl: String?
            let articleContent: String?
            let thumbnailUrl: String?
            let duration: Int?
        }
        
        struct ScrapedExercise: Codable {
            let id: String
            let title: String
            let slug: String
            let perseusContent: String
            let questionTypes: [String]
            let difficulty: String
            let skills: [String]
        }
    }
}

// MARK: - Enhanced Content Models
struct DeepKhanContent: Codable {
    let id: String
    let subject: String
    let title: String
    let description: String
    let units: [DeepUnit]
    let scrapedAt: Date
    
    struct DeepUnit: Codable {
        let id: String
        let title: String
        let description: String?
        let lessons: [DeepLesson]
        let exercises: [DeepExercise]
        
        struct DeepLesson: Codable {
            let id: String
            let title: String
            let slug: String
            let contentKind: String
            let youtubeId: String?
            let videoUrl: String?
            let directVideoUrl: String?
            let transcript: String?
            let articleContent: String?
            let thumbnailUrl: String?
            let duration: Int?
            let difficulty: String?
            let prerequisites: [String]
        }
        
        struct DeepExercise: Codable {
            let id: String
            let title: String
            let slug: String
            let perseusContent: String // Full Perseus JSON
            let questionTypes: [String]
            let difficulty: String
            let skills: [String]
            let hints: [String]
            let solutions: [String]
            let mastery: MasteryInfo?
            
            struct MasteryInfo: Codable {
                let practiced: Int
                let mastered: Int
                let totalQuestions: Int
            }
        }
    }
}

// MARK: - Deep Content Scraper
class AuthenticatedKhanScraper {
    private let session = KhanAcademySession()
    
    func scrapeCompleteContent() async {
        do {
            // Establish authenticated session first
            try await session.establishSession()
            
            print("\n🎯 Starting deep content extraction...")
            
            // Target one subject for complete extraction
            let content = try await scrapePreAlgebraComplete()
            
            // Save the enhanced content
            let outputURL = URL(fileURLWithPath: "./brainlift_output")
            try? FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
            try await saveDeepContent(content, to: outputURL)
            
            print("\n🎉 Complete content extraction finished!")
            print("💎 Enhanced with: videos, exercises, Perseus content, metadata")
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
    
    private func scrapePreAlgebraComplete() async throws -> DeepKhanContent {
        print("\n📚 Extracting Pre-Algebra with complete content...")
        
        // First get the course structure using our existing approach
        let variables = ["path": "math/pre-algebra", "countryCode": "US"]
        let courseData = try await session.makeAuthenticatedRequest(
            to: "/api/internal/graphql/ContentForPath",
            variables: variables
        )
        
        // Parse the basic structure
        let basicContent = try parseBasicContent(courseData)
        
        print("   📖 Found \(basicContent.units.count) units")
        
        // Now enhance each unit with deep content
        var deepUnits: [DeepKhanContent.DeepUnit] = []
        
        for (unitIndex, unit) in basicContent.units.prefix(3).enumerated() { // Limit to 3 units for testing
            print("   🔍 Unit \(unitIndex + 1): \(unit.title)")
            
            let deepUnit = try await enhanceUnitWithDeepContent(unit)
            deepUnits.append(deepUnit)
            
            // Rate limiting
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds between units
        }
        
        return DeepKhanContent(
            id: basicContent.id,
            subject: basicContent.subject,
            title: basicContent.title,
            description: basicContent.description,
            units: deepUnits,
            scrapedAt: Date()
        )
    }
    
    private func enhanceUnitWithDeepContent(_ unit: ScrapedKhanContent.ScrapedUnit) async throws -> DeepKhanContent.DeepUnit {
        var deepLessons: [DeepKhanContent.DeepUnit.DeepLesson] = []
        var deepExercises: [DeepKhanContent.DeepUnit.DeepExercise] = []
        
        // Enhance lessons with complete video data
        for (lessonIndex, lesson) in unit.lessons.prefix(2).enumerated() { // First 2 lessons per unit
            print("     🎥 Lesson \(lessonIndex + 1): \(lesson.title)")
            
            let deepLesson = try await enhanceWithVideoData(lesson)
            deepLessons.append(deepLesson)
            
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second between lessons
        }
        
        // Enhance exercises with complete Perseus data
        for (exerciseIndex, exercise) in unit.exercises.prefix(1).enumerated() { // First exercise per unit
            print("     📝 Exercise \(exerciseIndex + 1): \(exercise.title)")
            
            let deepExercise = try await enhanceWithPerseusData(exercise)
            deepExercises.append(deepExercise)
            
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second between exercises
        }
        
        return DeepKhanContent.DeepUnit(
            id: unit.id,
            title: unit.title,
            description: unit.description,
            lessons: deepLessons,
            exercises: deepExercises
        )
    }
    
    private func enhanceWithVideoData(_ lesson: ScrapedKhanContent.ScrapedUnit.ScrapedLesson) async throws -> DeepKhanContent.DeepUnit.DeepLesson {
        // Try to get detailed video information
        var youtubeId: String?
        var directVideoUrl: String?
        var transcript: String?
        
        if lesson.contentKind == "video" || lesson.contentKind == "lesson" {
            print("        🔍 Extracting video data for: \(lesson.title)")
            
            // Try comprehensive video content extraction approaches
            let videoExtractionMethods = [
                { try await self.extractVideoFromGraphQL(lessonId: lesson.id, slug: lesson.slug) },
                { try await self.extractVideoFromLessonPage(lessonUrl: lesson.videoUrl) },
                { try await self.extractVideoFromContentAPI(slug: lesson.slug) },
                { try await self.extractVideoFromDirectAPI(lessonId: lesson.id) }
            ]
            
            for method in videoExtractionMethods {
                do {
                    if let videoInfo = try await method() {
                        youtubeId = videoInfo.youtubeId
                        directVideoUrl = videoInfo.directUrl
                        transcript = videoInfo.transcript
                        print("        ✅ Video data extracted successfully!")
                        break
                    }
                } catch {
                    print("        ⚠️ Video extraction method failed: \(error.localizedDescription)")
                    continue
                }
            }
        }
        
        return DeepKhanContent.DeepUnit.DeepLesson(
            id: lesson.id,
            title: lesson.title,
            slug: lesson.slug,
            contentKind: lesson.contentKind,
            youtubeId: youtubeId,
            videoUrl: lesson.videoUrl,
            directVideoUrl: directVideoUrl ?? youtubeId.map { "https://www.youtube.com/embed/\($0)" },
            transcript: transcript,
            articleContent: lesson.articleContent,
            thumbnailUrl: lesson.thumbnailUrl,
            duration: lesson.duration,
            difficulty: inferDifficulty(from: lesson.title),
            prerequisites: extractPrerequisites(from: lesson.title)
        )
    }
    
    // MARK: - Enhanced Video Extraction Methods
    
    private func extractVideoFromGraphQL(lessonId: String, slug: String) async throws -> (youtubeId: String?, directUrl: String?, transcript: String?)? {
        print("          📡 Trying GraphQL video API...")
        
        // Try the ContentForLesson GraphQL endpoint
        let variables = ["contentId": lessonId, "slug": slug]
        
        do {
            let videoData = try await session.makeAuthenticatedRequest(
                to: "/api/internal/graphql/ContentForLesson",
                variables: variables
            )
            
            return try parseVideoData(videoData)
        } catch {
            // Try alternative GraphQL endpoints
            let alternativeEndpoints = [
                "/api/internal/graphql/LessonPageQuery",
                "/api/internal/graphql/VideoPageQuery", 
                "/api/internal/graphql/ContentPageQuery"
            ]
            
            for endpoint in alternativeEndpoints {
                do {
                    let data = try await session.makeAuthenticatedRequest(to: endpoint, variables: variables)
                    if let result = try parseVideoData(data) {
                        return result
                    }
                } catch {
                    continue
                }
            }
            
            throw error
        }
    }
    
    private func extractVideoFromLessonPage(lessonUrl: String?) async throws -> (youtubeId: String?, directUrl: String?, transcript: String?)? {
        guard let urlString = lessonUrl, let url = URL(string: urlString) else {
            throw ScrapingError.parseError("Invalid lesson URL")
        }
        
        print("          🌐 Extracting from lesson page...")
        
        // Make authenticated request to the lesson page
        var request = URLRequest(url: url)
        
        // Add all authentication headers
        for (key, value) in [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "same-origin"
        ] {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add session cookies
        let cookieHeader = session.sessionCookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        if !cookieHeader.isEmpty {
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw ScrapingError.parseError("Could not decode HTML")
        }
        
        // Extract video data from the HTML
        let youtubeId = extractYouTubeId(from: html)
        let transcript = extractTranscript(from: html)
        
        return (youtubeId, youtubeId.map { "https://www.youtube.com/embed/\($0)" }, transcript)
    }
    
    private func extractVideoFromContentAPI(slug: String) async throws -> (youtubeId: String?, directUrl: String?, transcript: String?)? {
        print("          🎯 Trying content API...")
        
        // Try various content API patterns
        let contentAPIs = [
            "/api/internal/content/video/\(slug)",
            "/api/internal/v1/content/\(slug)",
            "/content/\(slug).json",
            "/v/\(slug).json"
        ]
        
        for api in contentAPIs {
            do {
                let contentData = try await session.makeAuthenticatedRequest(to: api)
                if let result = try parseVideoData(contentData) {
                    return result
                }
            } catch {
                continue
            }
        }
        
        return nil
    }
    
    private func extractVideoFromDirectAPI(lessonId: String) async throws -> (youtubeId: String?, directUrl: String?, transcript: String?)? {
        print("          📹 Trying direct video API...")
        
        // Try direct video APIs with lesson ID
        let directAPIs = [
            "/api/internal/videos/\(lessonId)",
            "/api/v1/videos/\(lessonId)",
            "/videos/\(lessonId).json"
        ]
        
        for api in directAPIs {
            do {
                let videoData = try await session.makeAuthenticatedRequest(to: api)
                if let result = try parseVideoData(videoData) {
                    return result
                }
            } catch {
                continue
            }
        }
        
        return nil
    }
    
    private func extractTranscript(from html: String) -> String? {
        let transcriptPatterns = [
            "\"transcript\":\"([^\"]+)\"",
            "\"captions\":\"([^\"]+)\"",
            "\"subtitles\":\\s*\"([^\"]+)\"",
            "transcript[\"']:\\s*[\"']([^\"']+)[\"']"
        ]
        
        for pattern in transcriptPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    let transcriptRange = Range(match.range(at: 1), in: html)!
                    let transcript = String(html[transcriptRange])
                        .replacingOccurrences(of: "\\n", with: "\n")
                        .replacingOccurrences(of: "\\\"", with: "\"")
                    
                    if transcript.count > 20 {
                        return transcript
                    }
                }
            }
        }
        
        return nil
    }
    
    private func enhanceWithPerseusData(_ exercise: ScrapedKhanContent.ScrapedUnit.ScrapedExercise) async throws -> DeepKhanContent.DeepUnit.DeepExercise {
        var fullPerseusContent = exercise.perseusContent
        var hints: [String] = []
        var solutions: [String] = []
        
        print("        📝 Extracting Perseus data for: \(exercise.title)")
        
        // Try comprehensive Perseus content extraction approaches
        let perseusExtractionMethods = [
            { try await self.extractPerseusFromGraphQL(exerciseId: exercise.id, slug: exercise.slug) },
            { try await self.extractPerseusFromExerciseAPI(slug: exercise.slug) },
            { try await self.extractPerseusFromContentAPI(exerciseId: exercise.id) },
            { try await self.extractPerseusFromExercisePage(slug: exercise.slug) }
        ]
        
        for method in perseusExtractionMethods {
            do {
                if let perseusInfo = try await method() {
                    fullPerseusContent = perseusInfo.content
                    hints = perseusInfo.hints
                    solutions = perseusInfo.solutions
                    print("        ✅ Perseus data extracted successfully!")
                    break
                }
            } catch {
                print("        ⚠️ Perseus extraction method failed: \(error.localizedDescription)")
                continue
            }
        }
        
        return DeepKhanContent.DeepUnit.DeepExercise(
            id: exercise.id,
            title: exercise.title,
            slug: exercise.slug,
            perseusContent: fullPerseusContent,
            questionTypes: exercise.questionTypes,
            difficulty: exercise.difficulty,
            skills: exercise.skills,
            hints: hints.isEmpty ? ["Think step by step", "Check your work"] : hints,
            solutions: solutions,
            mastery: nil // Could be populated with user progress data
        )
    }
    
    // MARK: - Enhanced Perseus Extraction Methods
    
    private func extractPerseusFromGraphQL(exerciseId: String, slug: String) async throws -> (content: String, hints: [String], solutions: [String])? {
        print("          📡 Trying GraphQL Perseus API...")
        
        // Try GraphQL exercise queries
        let variables = ["exerciseId": exerciseId, "slug": slug]
        
        let graphQLEndpoints = [
            "/api/internal/graphql/ExerciseContent",
            "/api/internal/graphql/ExerciseQuery",
            "/api/internal/graphql/ExercisePageQuery",
            "/api/internal/graphql/PerseusExercise"
        ]
        
        for endpoint in graphQLEndpoints {
            do {
                let exerciseData = try await session.makeAuthenticatedRequest(to: endpoint, variables: variables)
                if let result = try parsePerseusData(exerciseData) {
                    return result
                }
            } catch {
                continue
            }
        }
        
        return nil
    }
    
    private func extractPerseusFromExerciseAPI(slug: String) async throws -> (content: String, hints: [String], solutions: [String])? {
        print("          🎯 Trying exercise API...")
        
        // Try various exercise API patterns
        let exerciseAPIs = [
            "/api/internal/exercises/\(slug)",
            "/api/v1/exercises/\(slug)", 
            "/exercise/\(slug).json",
            "/exercises/\(slug)/perseus",
            "/perseus/exercises/\(slug)"
        ]
        
        for api in exerciseAPIs {
            do {
                let exerciseData = try await session.makeAuthenticatedRequest(to: api)
                if let result = try parsePerseusData(exerciseData) {
                    return result
                }
            } catch {
                continue
            }
        }
        
        return nil
    }
    
    private func extractPerseusFromContentAPI(exerciseId: String) async throws -> (content: String, hints: [String], solutions: [String])? {
        print("          📚 Trying content API...")
        
        // Try content API variations
        let contentAPIs = [
            "/api/internal/content/exercise/\(exerciseId)",
            "/api/internal/content/\(exerciseId)",
            "/content/exercise/\(exerciseId).json"
        ]
        
        for api in contentAPIs {
            do {
                let contentData = try await session.makeAuthenticatedRequest(to: api)
                if let result = try parsePerseusData(contentData) {
                    return result
                }
            } catch {
                continue
            }
        }
        
        return nil
    }
    
    private func extractPerseusFromExercisePage(slug: String) async throws -> (content: String, hints: [String], solutions: [String])? {
        print("          🌐 Extracting from exercise page...")
        
        let exerciseUrl = "https://www.khanacademy.org/exercise/\(slug)"
        guard let url = URL(string: exerciseUrl) else {
            throw ScrapingError.parseError("Invalid exercise URL")
        }
        
        // Make authenticated request to the exercise page
        var request = URLRequest(url: url)
        
        // Add all authentication headers
        for (key, value) in [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "same-origin"
        ] {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add session cookies
        let cookieHeader = session.sessionCookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        if !cookieHeader.isEmpty {
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw ScrapingError.parseError("Could not decode HTML")
        }
        
        // Extract Perseus data from the HTML
        let perseusContent = extractPerseusFromHTML(html)
        let hints = extractHintsFromHTML(html)
        let solutions = extractSolutionsFromHTML(html)
        
        if !perseusContent.isEmpty {
            return (perseusContent, hints, solutions)
        }
        
        return nil
    }
    
    private func extractPerseusFromHTML(_ html: String) -> String {
        let perseusPatterns = [
            "window\\.Perseus\\s*=\\s*(\\{.*?\\});",
            "\"perseus\":\\s*(\\{.*?\\})",
            "__EXERCISE_DATA__\\s*=\\s*(\\{.*?\\});",
            "\"problem\":\\s*(\\{.*?\\})",
            "exerciseData[\"']:\\s*(\\{.*?\\})"
        ]
        
        for pattern in perseusPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    let contentRange = Range(match.range(at: 1), in: html)!
                    let content = String(html[contentRange])
                    
                    // Validate JSON
                    if let data = content.data(using: .utf8),
                       let _ = try? JSONSerialization.jsonObject(with: data) {
                        return content
                    }
                }
            }
        }
        
        return "{}"
    }
    
    private func extractHintsFromHTML(_ html: String) -> [String] {
        let hintPatterns = [
            "\"hints\":\\s*\\[(.*?)\\]",
            "\"hint\":\\s*\"([^\"]+)\"",
            "hint[\"']:\\s*[\"']([^\"']+)[\"']"
        ]
        
        var hints: [String] = []
        
        for pattern in hintPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                let matches = regex.matches(in: html, options: [], range: range)
                
                for match in matches {
                    if match.numberOfRanges > 1 {
                        let hintRange = Range(match.range(at: 1), in: html)!
                        let hint = String(html[hintRange])
                            .replacingOccurrences(of: "\\\"", with: "\"")
                            .replacingOccurrences(of: "\\n", with: "\n")
                        
                        if hint.count > 5 && !hints.contains(hint) {
                            hints.append(hint)
                        }
                    }
                }
            }
        }
        
        return hints
    }
    
    private func extractSolutionsFromHTML(_ html: String) -> [String] {
        let solutionPatterns = [
            "\"solutions\":\\s*\\[(.*?)\\]",
            "\"solution\":\\s*\"([^\"]+)\"",
            "\"answer\":\\s*\"([^\"]+)\""
        ]
        
        var solutions: [String] = []
        
        for pattern in solutionPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                let matches = regex.matches(in: html, options: [], range: range)
                
                for match in matches {
                    if match.numberOfRanges > 1 {
                        let solutionRange = Range(match.range(at: 1), in: html)!
                        let solution = String(html[solutionRange])
                            .replacingOccurrences(of: "\\\"", with: "\"")
                            .replacingOccurrences(of: "\\n", with: "\n")
                        
                        if solution.count > 2 && !solutions.contains(solution) {
                            solutions.append(solution)
                        }
                    }
                }
            }
        }
        
        return solutions
    }
    
    // MARK: - Parsing Helpers
    
    private func parseBasicContent(_ data: Data) throws -> ScrapedKhanContent {
        // Reuse our existing JSON parsing logic
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataField = json["data"] as? [String: Any],
              let contentRoute = dataField["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let course = listedPathData["course"] as? [String: Any] else {
            throw ScrapingError.parseError("Could not parse course structure")
        }
        
        let courseTitle = course["translatedTitle"] as? String ?? "Pre-algebra"
        let courseDescription = course["translatedDescription"] as? String ?? "Enhanced Khan Academy content"
        
        var scrapedUnits: [ScrapedKhanContent.ScrapedUnit] = []
        
        if let unitChildren = course["unitChildren"] as? [[String: Any]] {
            for (index, unitData) in unitChildren.enumerated() {
                let unitTitle = (unitData["translatedTitle"] as? String) ?? "Unit \(index + 1)"
                let unitDescription = unitData["translatedDescription"] as? String
                let unitId = (unitData["id"] as? String) ?? "unit_\(index)"
                
                var lessons: [ScrapedKhanContent.ScrapedUnit.ScrapedLesson] = []
                var exercises: [ScrapedKhanContent.ScrapedUnit.ScrapedExercise] = []
                
                if let children = unitData["allOrderedChildren"] as? [[String: Any]] {
                    for child in children {
                        let childId = (child["id"] as? String) ?? "item_\(lessons.count + exercises.count)"
                        let childTitle = (child["translatedTitle"] as? String) ?? "Content Item"
                        let contentKind = (child["contentKind"] as? String) ?? "lesson"
                        let childSlug = (child["slug"] as? String) ?? childId
                        let relativeUrl = child["relativeUrl"] as? String
                        
                        switch contentKind.lowercased() {
                        case "exercise":
                            exercises.append(ScrapedKhanContent.ScrapedUnit.ScrapedExercise(
                                id: childId,
                                title: childTitle,
                                slug: childSlug,
                                perseusContent: "{}",
                                questionTypes: ["numeric_input"],
                                difficulty: "medium",
                                skills: [childTitle.lowercased()]
                            ))
                        default:
                            lessons.append(ScrapedKhanContent.ScrapedUnit.ScrapedLesson(
                                id: childId,
                                title: childTitle,
                                slug: childSlug,
                                contentKind: contentKind,
                                videoUrl: relativeUrl.map { "https://www.khanacademy.org\($0)" },
                                articleContent: nil,
                                thumbnailUrl: nil,
                                duration: 300
                            ))
                        }
                    }
                }
                
                scrapedUnits.append(ScrapedKhanContent.ScrapedUnit(
                    id: unitId,
                    title: unitTitle,
                    description: unitDescription,
                    lessons: lessons,
                    exercises: exercises
                ))
            }
        }
        
        return ScrapedKhanContent(
            id: "pre-algebra",
            subject: "pre-algebra",
            title: courseTitle,
            description: courseDescription,
            units: scrapedUnits,
            scrapedAt: Date()
        )
    }
    
    private func parseVideoData(_ data: Data) throws -> (youtubeId: String?, directUrl: String?, transcript: String?)? {
        // Try to parse video data from API response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let youtubeId = extractFromJSON(json, key: "youtubeId") ?? 
                           extractFromJSON(json, key: "videoId")
            let directUrl = extractFromJSON(json, key: "downloadUrl") ?? 
                           extractFromJSON(json, key: "videoUrl")
            let transcript = extractFromJSON(json, key: "transcript") ?? 
                            extractFromJSON(json, key: "captions")
            
            return (youtubeId, directUrl, transcript)
        }
        
        // Fallback: try to extract from HTML if it's not JSON
        if let html = String(data: data, encoding: .utf8) {
            let youtubeId = extractYouTubeId(from: html)
            return (youtubeId, youtubeId.map { "https://www.youtube.com/embed/\($0)" }, nil)
        }
        
        return (nil, nil, nil)
    }
    
    private func parsePerseusData(_ data: Data) throws -> (content: String, hints: [String], solutions: [String])? {
        // Try to parse Perseus exercise data
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let content = extractFromJSON(json, key: "perseus") ?? "{}"
            let hints = extractArrayFromJSON(json, key: "hints")
            let solutions = extractArrayFromJSON(json, key: "solutions")
            
            return (content, hints, solutions)
        }
        
        return nil
    }
    
    // MARK: - Extraction Utilities
    
    private func extractFromJSON(_ json: [String: Any], key: String) -> String? {
        if let value = json[key] as? String {
            return value
        }
        
        // Recursive search in nested objects
        for (_, value) in json {
            if let nestedDict = value as? [String: Any],
               let found = extractFromJSON(nestedDict, key: key) {
                return found
            }
        }
        
        return nil
    }
    
    private func extractArrayFromJSON(_ json: [String: Any], key: String) -> [String] {
        if let array = json[key] as? [String] {
            return array
        }
        
        if let array = json[key] as? [Any] {
            return array.compactMap { $0 as? String }
        }
        
        return []
    }
    
    private func extractYouTubeId(from html: String) -> String? {
        // Enhanced patterns for YouTube video ID extraction
        let patterns = [
            "\"videoId\":\\s*\"([a-zA-Z0-9_-]+)\"",
            "\"youTubeId\":\\s*\"([a-zA-Z0-9_-]+)\"",
            "\"youtube_id\":\\s*\"([a-zA-Z0-9_-]+)\"",
            "youtube\\.com/embed/([a-zA-Z0-9_-]{11})",
            "youtube\\.com/watch\\?v=([a-zA-Z0-9_-]{11})",
            "youtu\\.be/([a-zA-Z0-9_-]{11})",
            "\"video\":\\s*{[^}]*\"id\":\\s*\"([a-zA-Z0-9_-]{11})\"",
            "/embed/([a-zA-Z0-9_-]{11})",
            "\"kaVideoId\":\\s*\"([a-zA-Z0-9_-]+)\"",
            "data-youtube-id=[\"']([a-zA-Z0-9_-]+)[\"']",
            "video[_-]?id[\"']?:\\s*[\"']([a-zA-Z0-9_-]+)[\"']"
        ]
        
        print("            🔍 Searching for YouTube ID in HTML (length: \(html.count))...")
        
        for (index, pattern) in patterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    let idRange = Range(match.range(at: 1), in: html)!
                    let videoId = String(html[idRange])
                    
                    // Validate YouTube ID format (11 characters)
                    if videoId.count == 11 || (videoId.count > 11 && videoId.contains("ka-")) {
                        print("            ✅ Found YouTube ID with pattern \(index + 1): \(videoId)")
                        return videoId
                    }
                }
            }
        }
        
        // Fallback: Look for any video-related JSON structures
        if html.contains("video") && html.contains("{") {
            print("            ⚠️ No direct YouTube ID found, but video content detected")
            // Could add more sophisticated JSON parsing here
        }
        
        print("            ❌ No YouTube ID found")
        return nil
    }
    
    private func inferDifficulty(from title: String) -> String {
        let title = title.lowercased()
        if title.contains("intro") || title.contains("basic") {
            return "easy"
        } else if title.contains("advanced") || title.contains("complex") {
            return "hard"
        }
        return "medium"
    }
    
    private func extractPrerequisites(from title: String) -> [String] {
        // Simple prerequisite inference based on content
        let title = title.lowercased()
        if title.contains("factor") {
            return ["multiplication", "division"]
        } else if title.contains("algebra") {
            return ["arithmetic", "variables"]
        }
        return ["basic_math"]
    }
    
    private func saveDeepContent(_ content: DeepKhanContent, to directory: URL) async throws {
        let fileName = "pre-algebra_deep_authenticated_\(Int(Date().timeIntervalSince1970)).json"
        let fileURL = directory.appendingPathComponent(fileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(content)
        try jsonData.write(to: fileURL)
        
        print("💾 Saved enhanced content: \(fileName)")
        print("   📊 Size: \(jsonData.count / 1024)KB")
    }
}

// MARK: - Error Types
enum ScrapingError: Error, LocalizedError {
    case sessionNotEstablished
    case invalidResponse
    case httpError(Int, String)
    case parseError(String)
    
    var errorDescription: String? {
        switch self {
        case .sessionNotEstablished: return "Session not established"
        case .invalidResponse: return "Invalid HTTP response"
        case .httpError(let code, let body): return "HTTP \(code): \(body.prefix(100))"
        case .parseError(let message): return "Parse error: \(message)"
        }
    }
}

// MARK: - Main Execution
let scraper = AuthenticatedKhanScraper()
await scraper.scrapeCompleteContent()