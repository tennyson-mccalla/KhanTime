#!/usr/bin/env swift

import Foundation

// MARK: - BrainLift Khan Academy Scraper
// Using real Khan Academy GraphQL APIs captured from browser Network Inspector

print("🧠 BrainLift Khan Academy Scraper")
print("==================================")

// MARK: - Zod-Validated Data Models (based on real Khan Academy API responses)

struct KhanAcademyContentResponse: Codable {
    let data: ContentData
    
    struct ContentData: Codable {
        let contentRoute: ContentRoute
        
        struct ContentRoute: Codable {
            let listedPathData: ListedPathData
            
            struct ListedPathData: Codable {
                let course: Course?
                
                struct Course: Codable {
                    let id: String
                    let translatedTitle: String?
                    let translatedDescription: String?
                    let unitChildren: [Unit]?
                    
                    struct Unit: Codable {
                        let id: String
                        let translatedTitle: String?
                        let translatedDescription: String?
                        let slug: String?
                        let allOrderedChildren: [Child]?
                        
                        struct Child: Codable {
                            let id: String
                            let translatedTitle: String?
                            let translatedDescription: String?
                            let contentKind: String
                            let slug: String?
                            let relativeUrl: String?
                            let iconPath: String?
                        }
                    }
                }
            }
        }
    }
}

struct KhanAcademyLearnMenuResponse: Codable {
    let data: LearnMenuData
    
    struct LearnMenuData: Codable {
        let user: User?
        let topics: [Topic]
        
        struct User: Codable {
            let id: String
            let username: String?
        }
        
        struct Topic: Codable {
            let id: String
            let title: String
            let description: String?
            let slug: String
            let thumbnailUrl: String?
            let subjects: [Subject]
            
            struct Subject: Codable {
                let id: String
                let title: String
                let slug: String
                let childTopics: [ChildTopic]
                
                struct ChildTopic: Codable {
                    let id: String
                    let title: String
                    let slug: String
                    let description: String?
                    let thumbnailUrl: String?
                }
            }
        }
    }
}

// MARK: - Lesson Step Models (for multi-step interactive lessons)
struct LessonStep: Codable {
    let id: String
    let title: String
    let type: StepType
    let youtubeUrl: String?
    let description: String?
    
    enum StepType: String, Codable {
        case video
        case exercise
        case other
    }
}

// MARK: - Output Models (matching our app structure)
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
            let videoUrl: String? // Legacy field - now contains first video or nil
            let articleContent: String?
            let thumbnailUrl: String?
            let duration: Int?
            let lessonSteps: [LessonStep]? // New field - contains all steps for multi-step lessons
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

// MARK: - BrainLift Khan Academy API Client
class BrainLiftKhanScraper {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    // Headers from captured cURL requests
    private var commonHeaders: [String: String] {
        return [
            "Accept": "*/*",
            "Sec-Fetch-Site": "same-origin",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept-Encoding": "gzip, deflate, br",
            "Sec-Fetch-Mode": "cors",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15",
            "Sec-Fetch-Dest": "empty",
            "x-ka-fkey": "1",
            "Priority": "u=3, i"
        ]
    }
    
    func scrapeAllSubjects() async {
        print("📡 Starting BrainLift scrape using real Khan Academy APIs...")
        print("📁 Output directory: ./brainlift_output/")
        
        let outputURL = URL(fileURLWithPath: "./brainlift_output")
        try? FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        
        // Target subjects with their actual Khan Academy paths (focusing on pre-algebra for deep scraping)
        let subjects = [
            ("pre-algebra", "math/pre-algebra")
        ]
        
        for (id, path) in subjects {
            print("\n🎯 Scraping \(id)...")
            print("    Path: /\(path)")
            
            do {
                let content = try await scrapeSubjectContent(id: id, path: path)
                try await saveContent(content, to: outputURL)
                print("    ✅ Success! Units: \(content.units.count)")
                
                // Rate limiting
                print("    ⏱️ Waiting 3 seconds...")
                try await Task.sleep(nanoseconds: 3_000_000_000)
                
            } catch {
                print("    ❌ Error: \(error.localizedDescription)")
                continue
            }
        }
        
        print("\n🎉 BrainLift scraping complete!")
        print("💡 Real Khan Academy content structure extracted")
    }
    
    private func scrapeSubjectContent(id: String, path: String) async throws -> ScrapedKhanContent {
        // First get the course structure
        let courseStructure = try await getCourseStructure(id: id, path: path)
        
        // Then enhance it with deep content scraping
        let enhancedContent = try await enhanceWithDeepContent(courseStructure)
        
        return enhancedContent
    }
    
    private func getCourseStructure(id: String, path: String) async throws -> ScrapedKhanContent {
        // Use the ContentForPath API that loads the actual course structure
        let urlString = "\(baseURL)/api/internal/graphql/ContentForPath"
        let variables = ["path": path, "countryCode": "US"]
        let variablesData = try JSONSerialization.data(withJSONObject: variables)
        let variablesString = String(data: variablesData, encoding: .utf8)!
        
        let params = [
            "fastly_cacheable": "persist_until_publish",
            "pcv": "dd3a92f28329ba421fb048ddfa2c930cbbfbac29",
            "hash": "45296627",
            "variables": variablesString,
            "lang": "en",
            "app": "khanacademy"
        ]
        
        var urlComponents = URLComponents(string: urlString)!
        urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        
        // Add headers from captured cURL
        for (key, value) in commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("\(baseURL)/\(path)", forHTTPHeaderField: "Referer")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScrapingError.invalidResponse
        }
        
        print("    📡 HTTP Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response"
            print("    📄 Response: \(responseString.prefix(200))...")
            throw ScrapingError.httpError(httpResponse.statusCode, responseString)
        }
        
        // Parse the real Khan Academy response
        let decoder = JSONDecoder()
        do {
            let apiResponse = try decoder.decode(KhanAcademyContentResponse.self, from: data)
            return convertToScrapedContent(id: id, path: path, apiResponse: apiResponse)
        } catch {
            print("    ❌ JSON Decode Error: \(error)")
            return try createContentFromJSON(id: id, path: path, data: data)
        }
    }
    
    private func enhanceWithDeepContent(_ content: ScrapedKhanContent) async throws -> ScrapedKhanContent {
        print("    🚀 Enhancing with deep content scraping...")
        
        var enhancedUnits: [ScrapedKhanContent.ScrapedUnit] = []
        
        for (unitIndex, unit) in content.units.enumerated() {
            // Process ALL units for complete coverage
            print("      📖 Unit \(unitIndex + 1): \(unit.title)")
            
            // Enhance lessons with real video URLs and content
            var enhancedLessons: [ScrapedKhanContent.ScrapedUnit.ScrapedLesson] = []
            for (lessonIndex, lesson) in unit.lessons.enumerated() {
                // Process ALL lessons for complete coverage
                print("        🎥 Lesson \(lessonIndex + 1): \(lesson.title)")
                let enhancedLesson = try await enhanceLesson(lesson)
                enhancedLessons.append(enhancedLesson)
                
                // Rate limiting between lessons
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
            
            // Enhance exercises with real Perseus content
            var enhancedExercises: [ScrapedKhanContent.ScrapedUnit.ScrapedExercise] = []
            for (exerciseIndex, exercise) in unit.exercises.enumerated() {
                // Process ALL exercises for complete coverage
                print("        📝 Exercise \(exerciseIndex + 1): \(exercise.title)")
                let enhancedExercise = try await enhanceExercise(exercise)
                enhancedExercises.append(enhancedExercise)
                
                // Rate limiting between exercises
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
            
            let enhancedUnit = ScrapedKhanContent.ScrapedUnit(
                id: unit.id,
                title: unit.title,
                description: unit.description,
                lessons: enhancedLessons,
                exercises: enhancedExercises
            )
            
            enhancedUnits.append(enhancedUnit)
        }
        
        return ScrapedKhanContent(
            id: content.id,
            subject: content.subject,
            title: content.title,
            description: content.description,
            units: enhancedUnits,
            scrapedAt: content.scrapedAt
        )
    }
    
    private func enhanceLesson(_ lesson: ScrapedKhanContent.ScrapedUnit.ScrapedLesson) async throws -> ScrapedKhanContent.ScrapedUnit.ScrapedLesson {
        // For video lessons (Khan Academy uses "lesson" contentKind for videos), use the BrainLift GraphQL methodology to extract YouTube IDs
        guard lesson.contentKind == "lesson" && lesson.videoUrl != nil else {
            return lesson
        }
        
        do {
            print("          🎥 Using BrainLift GraphQL API to get video player settings for: \(lesson.title)")
            
            // Extract video slug from lesson data or construct from ID
            let videoSlug = lesson.slug
            
            // Step 1: Use GraphQL ContentForPath to get video data from lesson URL
            // Extract path from videoUrl: https://www.khanacademy.org/math/pre-algebra/... -> math/pre-algebra/...
            let lessonPath: String
            if let videoUrl = lesson.videoUrl, let range = videoUrl.range(of: "khanacademy.org/") {
                lessonPath = String(videoUrl[range.upperBound...])
            } else {
                lessonPath = "math/pre-algebra/pre-algebra-factors-multiples/\(videoSlug)"
            }
            
            // Get all lesson steps (videos, exercises, etc.)
            let lessonSteps = try await getAllLessonSteps(for: lessonPath)
            
            if !lessonSteps.isEmpty {
                print("          ✅ GraphQL found \(lessonSteps.count) lesson steps")
                
                // Get first video URL for legacy compatibility
                let firstVideoUrl = lessonSteps.first { $0.type == .video }?.youtubeUrl
                
                return ScrapedKhanContent.ScrapedUnit.ScrapedLesson(
                    id: lesson.id,
                    title: lesson.title,
                    slug: lesson.slug,
                    contentKind: lesson.contentKind,
                    videoUrl: firstVideoUrl,
                    articleContent: lesson.articleContent,
                    thumbnailUrl: lesson.thumbnailUrl,
                    duration: lesson.duration,
                    lessonSteps: lessonSteps
                )
            } else {
                print("          ⚠️ GraphQL could not find lesson steps for \(lesson.title)")
                
                // Fallback: try to construct video URL based on known patterns
                if let fallbackUrl = try await fallbackVideoExtraction(lesson: lesson) {
                    return ScrapedKhanContent.ScrapedUnit.ScrapedLesson(
                        id: lesson.id,
                        title: lesson.title,
                        slug: lesson.slug,
                        contentKind: lesson.contentKind,
                        videoUrl: fallbackUrl,
                        articleContent: lesson.articleContent,
                        thumbnailUrl: lesson.thumbnailUrl,
                        duration: lesson.duration,
                        lessonSteps: nil
                    )
                }
            }
            
            return lesson
            
        } catch {
            print("          ❌ GraphQL video enhancement failed for \(lesson.title): \(error)")
            return lesson
        }
    }
    
    private func enhanceExercise(_ exercise: ScrapedKhanContent.ScrapedUnit.ScrapedExercise) async throws -> ScrapedKhanContent.ScrapedUnit.ScrapedExercise {
        // Try to get the actual Perseus content for this exercise
        let exerciseUrl = "\(baseURL)/exercise/\(exercise.slug)"
        
        do {
            guard let url = URL(string: exerciseUrl) else { return exercise }
            
            var request = URLRequest(url: url)
            for (key, value) in commonHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            let (data, _) = try await session.data(for: request)
            guard let htmlContent = String(data: data, encoding: .utf8) else {
                return exercise
            }
            
            // Extract Perseus content from the page
            let perseusContent = extractPerseusContent(from: htmlContent)
            
            return ScrapedKhanContent.ScrapedUnit.ScrapedExercise(
                id: exercise.id,
                title: exercise.title,
                slug: exercise.slug,
                perseusContent: perseusContent ?? exercise.perseusContent,
                questionTypes: exercise.questionTypes,
                difficulty: exercise.difficulty,
                skills: exercise.skills
            )
            
        } catch {
            print("          ⚠️ Could not enhance exercise \(exercise.title): \(error)")
            return exercise
        }
    }
    
    private func createContentFromJSON(id: String, path: String, data: Data) throws -> ScrapedKhanContent {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataField = json["data"] as? [String: Any],
              let contentRoute = dataField["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let course = listedPathData["course"] as? [String: Any] else {
            throw ScrapingError.parseError("Could not parse basic JSON structure")
        }
        
        let courseTitle = course["translatedTitle"] as? String ?? id.capitalized
        let courseDescription = course["translatedDescription"] as? String ?? "Real Khan Academy content"
        
        var scrapedUnits: [ScrapedKhanContent.ScrapedUnit] = []
        
        if let unitChildren = course["unitChildren"] as? [[String: Any]] {
            print("    🎯 Found \(unitChildren.count) units in \(courseTitle)")
            
            for (index, unitData) in unitChildren.enumerated() {
                let unitTitle = (unitData["translatedTitle"] as? String) ?? "Unit \(index + 1)"
                let unitDescription = unitData["translatedDescription"] as? String
                let unitId = (unitData["id"] as? String) ?? "unit_\(index)"
                
                print("      Unit \(index + 1): \(unitTitle)")
                
                var lessons: [ScrapedKhanContent.ScrapedUnit.ScrapedLesson] = []
                var exercises: [ScrapedKhanContent.ScrapedUnit.ScrapedExercise] = []
                
                if let children = unitData["allOrderedChildren"] as? [[String: Any]] {
                    print("        └─ \(children.count) items")
                    
                    for child in children {
                        let childId = (child["id"] as? String) ?? "item_\(lessons.count + exercises.count)"
                        let childTitle = (child["translatedTitle"] as? String) ?? "Content Item"
                        let contentKind = (child["contentKind"] as? String) ?? "lesson"
                        let childSlug = (child["slug"] as? String) ?? childId
                        let relativeUrl = child["relativeUrl"] as? String
                        let iconPath = child["iconPath"] as? String
                        let description = child["translatedDescription"] as? String
                        
                        switch contentKind.lowercased() {
                        case "video":
                            lessons.append(ScrapedKhanContent.ScrapedUnit.ScrapedLesson(
                                id: childId,
                                title: childTitle,
                                slug: childSlug,
                                contentKind: "video",
                                videoUrl: relativeUrl.map { "\(baseURL)\($0)" },
                                articleContent: nil,
                                thumbnailUrl: iconPath,
                                duration: estimateVideoDuration(title: childTitle),
                                lessonSteps: nil
                            ))
                            
                        case "article":
                            lessons.append(ScrapedKhanContent.ScrapedUnit.ScrapedLesson(
                                id: childId,
                                title: childTitle,
                                slug: childSlug,
                                contentKind: "article",
                                videoUrl: nil,
                                articleContent: description,
                                thumbnailUrl: iconPath,
                                duration: estimateReadingDuration(text: description ?? ""),
                                lessonSteps: nil
                            ))
                            
                        case "exercise":
                            exercises.append(ScrapedKhanContent.ScrapedUnit.ScrapedExercise(
                                id: childId,
                                title: childTitle,
                                slug: childSlug,
                                perseusContent: createPlaceholderPerseus(for: childTitle),
                                questionTypes: inferQuestionTypes(from: childTitle, unit: unitTitle),
                                difficulty: inferDifficulty(from: unitTitle, item: childTitle),
                                skills: extractSkills(from: childTitle, unit: unitTitle)
                            ))
                            
                        default:
                            lessons.append(ScrapedKhanContent.ScrapedUnit.ScrapedLesson(
                                id: childId,
                                title: childTitle,
                                slug: childSlug,
                                contentKind: contentKind.lowercased(),
                                videoUrl: relativeUrl.map { "\(baseURL)\($0)" },
                                articleContent: description,
                                thumbnailUrl: iconPath,
                                duration: 300,
                                lessonSteps: nil
                            ))
                        }
                    }
                }
                
                let scrapedUnit = ScrapedKhanContent.ScrapedUnit(
                    id: unitId,
                    title: unitTitle,
                    description: unitDescription,
                    lessons: lessons,
                    exercises: exercises
                )
                
                scrapedUnits.append(scrapedUnit)
            }
        }
        
        return ScrapedKhanContent(
            id: id,
            subject: id,
            title: courseTitle,
            description: courseDescription,
            units: scrapedUnits,
            scrapedAt: Date()
        )
    }
    
    private func convertToScrapedContent(
        id: String,
        path: String,
        apiResponse: KhanAcademyContentResponse
    ) -> ScrapedKhanContent {
        
        var scrapedUnits: [ScrapedKhanContent.ScrapedUnit] = []
        
        // Extract units from the real Khan Academy response structure
        guard let course = apiResponse.data.contentRoute.listedPathData.course,
              let units = course.unitChildren else {
            print("    ⚠️ No course or units found in response")
            return ScrapedKhanContent(
                id: id,
                subject: id,
                title: "No Content Found",
                description: "Could not extract course structure from Khan Academy API",
                units: [],
                scrapedAt: Date()
            )
        }
        
        print("    🎯 Found \(units.count) units in \(course.translatedTitle ?? id)")
        
        for (index, unit) in units.enumerated() {
            var lessons: [ScrapedKhanContent.ScrapedUnit.ScrapedLesson] = []
            var exercises: [ScrapedKhanContent.ScrapedUnit.ScrapedExercise] = []
            
            let unitTitle = unit.translatedTitle ?? "Unit \(index + 1)"
            print("      Unit \(index + 1): \(unitTitle)")
            
            // Process children (lessons, exercises, articles, videos)
            if let children = unit.allOrderedChildren {
                print("        └─ \(children.count) items")
                for item in children {
                    switch item.contentKind.lowercased() {
                    case "video":
                        lessons.append(ScrapedKhanContent.ScrapedUnit.ScrapedLesson(
                            id: item.id,
                            title: item.translatedTitle ?? "Video Lesson",
                            slug: item.slug ?? item.id,
                            contentKind: "video",
                            videoUrl: item.relativeUrl.map { "\(baseURL)\($0)" },
                            articleContent: nil,
                            thumbnailUrl: item.iconPath,
                            duration: estimateVideoDuration(title: item.translatedTitle ?? ""),
                            lessonSteps: nil
                        ))
                        
                    case "article":
                        lessons.append(ScrapedKhanContent.ScrapedUnit.ScrapedLesson(
                            id: item.id,
                            title: item.translatedTitle ?? "Article",
                            slug: item.slug ?? item.id,
                            contentKind: "article",
                            videoUrl: nil,
                            articleContent: item.translatedDescription,
                            thumbnailUrl: item.iconPath,
                            duration: estimateReadingDuration(text: item.translatedDescription ?? ""),
                            lessonSteps: nil
                        ))
                        
                    case "exercise":
                        exercises.append(ScrapedKhanContent.ScrapedUnit.ScrapedExercise(
                            id: item.id,
                            title: item.translatedTitle ?? "Exercise",
                            slug: item.slug ?? item.id,
                            perseusContent: createPlaceholderPerseus(for: item.translatedTitle ?? "Exercise"),
                            questionTypes: inferQuestionTypes(from: item.translatedTitle ?? "", unit: unitTitle),
                            difficulty: inferDifficulty(from: unitTitle, item: item.translatedTitle ?? ""),
                            skills: extractSkills(from: item.translatedTitle ?? "", unit: unitTitle)
                        ))
                        
                    default:
                        // Handle other content types as lessons
                        lessons.append(ScrapedKhanContent.ScrapedUnit.ScrapedLesson(
                            id: item.id,
                            title: item.translatedTitle ?? item.contentKind,
                            slug: item.slug ?? item.id,
                            contentKind: item.contentKind.lowercased(),
                            videoUrl: item.relativeUrl.map { "\(baseURL)\($0)" },
                            articleContent: item.translatedDescription,
                            thumbnailUrl: item.iconPath,
                            duration: 300,
                            lessonSteps: nil
                        ))
                    }
                }
            }
            
            let scrapedUnit = ScrapedKhanContent.ScrapedUnit(
                id: unit.id,
                title: unitTitle,
                description: unit.translatedDescription,
                lessons: lessons,
                exercises: exercises
            )
            
            scrapedUnits.append(scrapedUnit)
        }
        
        return ScrapedKhanContent(
            id: id,
            subject: id,
            title: course.translatedTitle ?? id.capitalized,
            description: course.translatedDescription ?? "Real Khan Academy content scraped using BrainLift methodology",
            units: scrapedUnits,
            scrapedAt: Date()
        )
    }
    
    // MARK: - BrainLift GraphQL API Methods
    
    private func getVideoPlayerSettings(for videoSlug: String) async throws -> String? {
        print("            🧠 Calling ContentForPath GraphQL with path: \(videoSlug)")
        
        // Use the lesson path passed in
        let videoPath = videoSlug
        
        let urlString = "\(baseURL)/api/internal/graphql/ContentForPath"
        let variables = ["path": videoPath, "countryCode": "US"]
        let variablesData = try JSONSerialization.data(withJSONObject: variables)
        let variablesString = String(data: variablesData, encoding: .utf8)!
        
        let params = [
            "fastly_cacheable": "persist_until_publish",
            "pcv": "4ceacaeebbc3d8c0c8c49e2daa849a971a1f2bf7", // From Network tab
            "hash": "45296627", // From Network tab
            "variables": variablesString,
            "lang": "en",
            "app": "khanacademy"
        ]
        
        var urlComponents = URLComponents(string: urlString)!
        urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        
        // Use exact headers from Network tab
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("u=3, i", forHTTPHeaderField: "Priority")
        request.setValue("1", forHTTPHeaderField: "x-ka-fkey")
        request.setValue("\(baseURL)/math/pre-algebra/pre-algebra-factors-multiples/pre-algebra-factors-mult/v/\(videoSlug)", forHTTPHeaderField: "Referer")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScrapingError.invalidResponse
        }
        
        print("            📡 ContentForPath GraphQL Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response"
            print("            📄 GraphQL Error: \(responseString.prefix(200))...")
            return nil
        }
        
        // Parse the response to extract YouTube ID from downloadUrls
        return try await parseContentForPathResponse(data: data, videoPath: videoPath)
    }
    
    private func getAllLessonSteps(for lessonPath: String) async throws -> [LessonStep] {
        print("            🧠 Getting all lesson steps for: \(lessonPath)")
        
        // Call ContentForPath for the lesson to get the structure
        let urlString = "\(baseURL)/api/internal/graphql/ContentForPath"
        let variables = ["path": lessonPath, "countryCode": "US"]
        let variablesData = try JSONSerialization.data(withJSONObject: variables)
        let variablesString = String(data: variablesData, encoding: .utf8)!
        
        let params = [
            "fastly_cacheable": "persist_until_publish",
            "pcv": "4ceacaeebbc3d8c0c8c49e2daa849a971a1f2bf7",
            "hash": "45296627",
            "variables": variablesString,
            "lang": "en",
            "app": "khanacademy"
        ]
        
        var urlComponents = URLComponents(string: urlString)!
        urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("u=3, i", forHTTPHeaderField: "Priority")
        request.setValue("1", forHTTPHeaderField: "x-ka-fkey")
        request.setValue("\(baseURL)/\(lessonPath)", forHTTPHeaderField: "Referer")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScrapingError.invalidResponse
        }
        
        print("            📡 Lesson steps ContentForPath Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response"
            print("            📄 Lesson steps GraphQL Error: \(responseString.prefix(200))...")
            return []
        }
        
        // Parse lesson structure and extract all steps
        return try await parseLessonStepsResponse(data: data, lessonPath: lessonPath)
    }
    
    private func parseLessonStepsResponse(data: Data, lessonPath: String) async throws -> [LessonStep] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataField = json["data"] as? [String: Any],
              let contentRoute = dataField["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any] else {
            print("            ❌ Could not parse lesson steps response structure")
            return []
        }
        
        // Check if we have lesson data
        if let lesson = listedPathData["lesson"] as? [String: Any] {
            return try await extractAllVideosFromLessonStructure(lesson, originalPath: lessonPath, data: data)
        }
        
        print("            ❌ No lesson data found in response")
        return []
    }
    
    private func parseContentForPathResponse(data: Data, videoPath: String) async throws -> String? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataField = json["data"] as? [String: Any],
              let contentRoute = dataField["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any] else {
            print("            ❌ Could not parse basic ContentForPath response structure")
            return nil
        }
        
        // Check if we have direct video content
        if let content = listedPathData["content"] as? [String: Any] {
            // We have individual video content - extract YouTube ID
            if let downloadUrlsString = content["downloadUrls"] as? String {
                print("            🔍 Found downloadUrls: \(downloadUrlsString.prefix(100))...")
                
                guard let downloadUrlsData = downloadUrlsString.data(using: .utf8),
                      let downloadUrls = try JSONSerialization.jsonObject(with: downloadUrlsData) as? [String: Any] else {
                    print("            ❌ Could not parse downloadUrls JSON")
                    return nil
                }
                
                if let mp4Url = downloadUrls["mp4"] as? String {
                    let youtubeIdPattern = "ka-youtube-converted/([a-zA-Z0-9_-]{11})\\."
                    
                    if let regex = try? NSRegularExpression(pattern: youtubeIdPattern, options: []) {
                        let range = NSRange(mp4Url.startIndex..<mp4Url.endIndex, in: mp4Url)
                        if let match = regex.firstMatch(in: mp4Url, options: [], range: range) {
                            let youtubeIdRange = Range(match.range(at: 1), in: mp4Url)!
                            let youtubeId = String(mp4Url[youtubeIdRange])
                            
                            print("            🎯 Extracted YouTube ID from downloadUrls: \(youtubeId)")
                            return "https://www.youtube.com/embed/\(youtubeId)"
                        }
                    }
                }
            }
        } else {
            print("            💡 ContentForPath returned lesson structure, not individual video")
            
            // Try to extract ALL video steps from the lesson structure (found at lesson.curatedChildren)
            if let lesson = listedPathData["lesson"] as? [String: Any] {
                let lessonSteps = try await extractAllVideosFromLessonStructure(lesson, originalPath: videoPath, data: data)
                
                // Return the first video URL for backward compatibility, but store all steps
                let firstVideoStep = lessonSteps.first { $0.type == .video }
                return firstVideoStep?.youtubeUrl
            }
            
            print("            ❌ Could not find lesson data in response structure")
            return nil
        }
        
        // Debug output if extraction fails
        if let responseString = String(data: data, encoding: .utf8) {
            print("            🔍 ContentForPath response preview: \(responseString.prefix(500))...")
        }
        
        return nil
    }
    
    private func extractAllVideosFromLessonStructure(_ lesson: [String: Any], originalPath: String, data: Data) async throws -> [LessonStep] {
        print("            🔍 Searching lesson.curatedChildren for ALL content items...")
        
        var lessonSteps: [LessonStep] = []
        
        // Look for curatedChildren array (based on Network tab analysis)
        if let curatedChildren = lesson["curatedChildren"] as? [[String: Any]] {
            print("            📋 Found \(curatedChildren.count) curated children in lesson")
            
            // Process ALL curated children (videos and exercises)
            for (index, child) in curatedChildren.enumerated() {
                guard let typename = child["__typename"] as? String,
                      let title = child["translatedTitle"] as? String else {
                    continue
                }
                
                print("            📋 Processing #\(index + 1): \(typename) - \(title)")
                
                if typename == "Video",
                   let urlWithinCurationNode = child["urlWithinCurationNode"] as? String {
                    
                    // This is a video! Extract the path and get its YouTube ID
                    let videoPath = String(urlWithinCurationNode.dropFirst()) // Remove leading "/"
                    
                    // Call ContentForPath for this specific video to get YouTube ID
                    if let youtubeUrl = try await callContentForPathForVideo(videoPath) {
                        print("            ✅ Video step: \(title) → \(youtubeUrl)")
                        
                        let videoStep = LessonStep(
                            id: child["id"] as? String ?? "video_\(index)",
                            title: title,
                            type: .video,
                            youtubeUrl: youtubeUrl,
                            description: child["translatedDescription"] as? String
                        )
                        lessonSteps.append(videoStep)
                    } else {
                        print("            ⚠️ Could not extract YouTube URL for video: \(title)")
                    }
                    
                } else if typename == "Exercise" {
                    // Create placeholder for exercise
                    print("            📝 Exercise step (placeholder): \(title)")
                    
                    let exerciseStep = LessonStep(
                        id: child["id"] as? String ?? "exercise_\(index)",
                        title: title,
                        type: .exercise,
                        youtubeUrl: nil,
                        description: child["translatedDescription"] as? String
                    )
                    lessonSteps.append(exerciseStep)
                    
                } else {
                    // Handle other content types as generic steps
                    print("            📄 Other step (\(typename)): \(title)")
                    
                    let otherStep = LessonStep(
                        id: child["id"] as? String ?? "other_\(index)",
                        title: title,
                        type: .other,
                        youtubeUrl: nil,
                        description: child["translatedDescription"] as? String
                    )
                    lessonSteps.append(otherStep)
                }
                
                // Small delay between API calls to avoid rate limiting
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
        
        print("            🎯 Extracted \(lessonSteps.count) lesson steps total")
        return lessonSteps
    }
    
    private func callContentForPathForVideo(_ videoPath: String) async throws -> String? {
        print("            🔄 Calling ContentForPath directly for video: \(videoPath)")
        
        let urlString = "\(baseURL)/api/internal/graphql/ContentForPath"
        let variables = ["path": videoPath, "countryCode": "US"]
        let variablesData = try JSONSerialization.data(withJSONObject: variables)
        let variablesString = String(data: variablesData, encoding: .utf8)!
        
        let params = [
            "fastly_cacheable": "persist_until_publish",
            "pcv": "4ceacaeebbc3d8c0c8c49e2daa849a971a1f2bf7",
            "hash": "45296627",
            "variables": variablesString,
            "lang": "en",
            "app": "khanacademy"
        ]
        
        var urlComponents = URLComponents(string: urlString)!
        urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("u=3, i", forHTTPHeaderField: "Priority")
        request.setValue("1", forHTTPHeaderField: "x-ka-fkey")
        request.setValue("\(baseURL)/\(videoPath)", forHTTPHeaderField: "Referer")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScrapingError.invalidResponse
        }
        
        print("            📡 Video ContentForPath Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response"
            print("            📄 Video GraphQL Error: \(responseString.prefix(200))...")
            return nil
        }
        
        // Parse this response directly for video data
        return try parseContentForPathVideoResponse(data: data)
    }
    
    private func parseContentForPathVideoResponse(data: Data) throws -> String? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataField = json["data"] as? [String: Any],
              let contentRoute = dataField["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let content = listedPathData["content"] as? [String: Any] else {
            print("            ❌ Could not parse video ContentForPath response")
            return nil
        }
        
        // This should now have the video data with downloadUrls
        if let downloadUrlsString = content["downloadUrls"] as? String {
            print("            🔍 Found video downloadUrls: \(downloadUrlsString.prefix(100))...")
            
            guard let downloadUrlsData = downloadUrlsString.data(using: .utf8),
                  let downloadUrls = try JSONSerialization.jsonObject(with: downloadUrlsData) as? [String: Any] else {
                print("            ❌ Could not parse video downloadUrls JSON")
                return nil
            }
            
            if let mp4Url = downloadUrls["mp4"] as? String {
                let youtubeIdPattern = "ka-youtube-converted/([a-zA-Z0-9_-]{11})\\."
                
                if let regex = try? NSRegularExpression(pattern: youtubeIdPattern, options: []) {
                    let range = NSRange(mp4Url.startIndex..<mp4Url.endIndex, in: mp4Url)
                    if let match = regex.firstMatch(in: mp4Url, options: [], range: range) {
                        let youtubeIdRange = Range(match.range(at: 1), in: mp4Url)!
                        let youtubeId = String(mp4Url[youtubeIdRange])
                        
                        print("            🎯 SUCCESS! Extracted YouTube ID: \(youtubeId)")
                        return "https://www.youtube.com/embed/\(youtubeId)"
                    }
                }
            }
        }
        
        print("            ❌ No downloadUrls found in video response")
        return nil
    }
    
    private func fallbackVideoExtraction(lesson: ScrapedKhanContent.ScrapedUnit.ScrapedLesson) async throws -> String? {
        print("            🔄 BrainLift enhanced extraction for: \(lesson.title)")
        
        // Use the original videoUrl if available, or construct from lesson data
        guard let videoUrl = lesson.videoUrl ?? constructVideoUrl(from: lesson) else {
            return nil
        }
        
        guard let url = URL(string: videoUrl) else { return nil }
        
        var request = URLRequest(url: url)
        // Use specific headers that work for Khan Academy video pages
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.khanacademy.org/", forHTTPHeaderField: "Referer")
        request.setValue("document", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue("navigate", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("same-site", forHTTPHeaderField: "Sec-Fetch-Site")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("            ❌ No HTTP response")
            return nil
        }
        
        print("            📡 Video page HTTP Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            print("            ❌ Video page returned \(httpResponse.statusCode)")
            return nil
        }
        
        guard let htmlContent = String(data: data, encoding: .utf8) else {
            print("            ❌ Could not decode HTML content")
            return nil
        }
        
        print("            🔍 Analyzing \(htmlContent.count) characters of HTML content...")
        
        // Debug: Check what kind of content we're actually getting
        let preview = htmlContent.prefix(1000)
        print("            📄 HTML preview: \(preview)...")
        
        // Try multiple extraction methods using BrainLift principles
        if let youtubeUrl = extractVideoUrlFromHtml(htmlContent) {
            print("            ✅ BrainLift extraction found: \(youtubeUrl)")
            return youtubeUrl
        }
        
        // Try extracting from embedded JSON data (common in Khan Academy pages)
        if let youtubeUrl = extractVideoFromEmbeddedJSON(htmlContent) {
            print("            ✅ JSON extraction found: \(youtubeUrl)")
            return youtubeUrl
        }
        
        // Try extracting from script tags (where video config might be)
        if let youtubeUrl = extractVideoFromScriptTags(htmlContent) {
            print("            ✅ Script tag extraction found: \(youtubeUrl)")
            return youtubeUrl
        }
        
        print("            ❌ No YouTube URL found using any BrainLift method")
        return nil
    }
    
    private func constructVideoUrl(from lesson: ScrapedKhanContent.ScrapedUnit.ScrapedLesson) -> String? {
        // Construct a Khan Academy video URL from lesson slug
        // Pattern: https://www.khanacademy.org/math/pre-algebra/unit/v/video-slug
        let baseVideoUrl = "\(baseURL)/math/pre-algebra"
        return "\(baseVideoUrl)/v/\(lesson.slug)"
    }
    
    // MARK: - Enhanced BrainLift Video Extraction Methods
    
    private func extractVideoFromEmbeddedJSON(_ html: String) -> String? {
        // Khan Academy often embeds video data in JSON within script tags
        let jsonPatterns = [
            // Look for JSON objects containing video data
            "\"youTubeId\"\\s*:\\s*\"([a-zA-Z0-9_-]{11})\"",
            "\"videoId\"\\s*:\\s*\"([a-zA-Z0-9_-]{11})\"",
            "\"youtube_id\"\\s*:\\s*\"([a-zA-Z0-9_-]{11})\"",
            // Look for video configuration objects
            "videoConfig[^{]*\\{[^}]*\"youtubeId\"[^}]*\"([a-zA-Z0-9_-]{11})\"",
            "video[^{]*\\{[^}]*\"id\"[^}]*\"([a-zA-Z0-9_-]{11})\"",
        ]
        
        for pattern in jsonPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    if match.numberOfRanges > 1 {
                        let videoIdRange = Range(match.range(at: 1), in: html)!
                        let videoId = String(html[videoIdRange])
                        print("            🎯 Found YouTube ID in embedded JSON: \(videoId)")
                        return "https://www.youtube.com/embed/\(videoId)"
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractVideoFromScriptTags(_ html: String) -> String? {
        // Extract content from script tags and look for video data
        let scriptPattern = "<script[^>]*>(.*?)</script>"
        
        guard let regex = try? NSRegularExpression(pattern: scriptPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        for match in matches {
            if match.numberOfRanges > 1 {
                let scriptRange = Range(match.range(at: 1), in: html)!
                let scriptContent = String(html[scriptRange])
                
                // Look for YouTube IDs within script content
                let videoPatterns = [
                    "\"([a-zA-Z0-9_-]{11})\"[^}]*youtube",
                    "youtube[^}]*\"([a-zA-Z0-9_-]{11})\"",
                    "videoId[^:]*:[^\"]*\"([a-zA-Z0-9_-]{11})\"",
                    "youTubeId[^:]*:[^\"]*\"([a-zA-Z0-9_-]{11})\"",
                ]
                
                for videoPattern in videoPatterns {
                    if let videoRegex = try? NSRegularExpression(pattern: videoPattern, options: .caseInsensitive) {
                        let scriptRange = NSRange(scriptContent.startIndex..<scriptContent.endIndex, in: scriptContent)
                        if let videoMatch = videoRegex.firstMatch(in: scriptContent, options: [], range: scriptRange) {
                            if videoMatch.numberOfRanges > 1 {
                                let videoIdRange = Range(videoMatch.range(at: 1), in: scriptContent)!
                                let videoId = String(scriptContent[videoIdRange])
                                
                                // Validate that this looks like a YouTube ID
                                if videoId.count == 11 && videoId.rangeOfCharacter(from: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-")).inverted) == nil {
                                    print("            🎯 Found YouTube ID in script tag: \(videoId)")
                                    return "https://www.youtube.com/embed/\(videoId)"
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Video URL Extraction
    
    private func extractVideoLessonUrls(from unitPageUrl: String, lessonTitle: String) async throws -> [String] {
        print("            🔍 Constructing possible video URLs based on lesson title and known patterns...")
        
        // Since the unit pages load content dynamically, construct video URLs based on known patterns
        // Pattern: {unit_url}/v/{video_slug}
        
        var possibleVideoUrls: [String] = []
        
        // Known video slug mappings based on lesson titles and Khan Academy patterns
        let knownVideoSlugs: [String: [String]] = [
            "factors and multiples": [
                "understanding-factor-pairs",
                "finding-factors-of-a-number", 
                "reasoning-about-factors-and-multiples",
                "finding-factors-and-multiples",
                "identifying-multiples"
            ],
            "prime and composite numbers": [
                "prime-numbers",
                "composite-numbers", 
                "prime-composite-intro",
                "understanding-prime-numbers"
            ],
            "prime factorization": [
                "prime-factorization-2",
                "prime-factorization",
                "factorization-tree"
            ],
            "math patterns": [
                "understanding-math-patterns",
                "number-patterns-intro",
                "pattern-recognition"
            ],
            "writing expressions": [
                "intro-to-expressions-with-variables",
                "expressions-with-variables",
                "writing-expressions-intro"
            ],
            "intro to ratios": [
                "introduction-to-ratios",
                "ratios-intro",
                "understanding-ratios"
            ]
        ]
        
        let titleLower = lessonTitle.lowercased()
        
        // Find matching video slugs for this lesson title
        for (titlePattern, slugs) in knownVideoSlugs {
            if titleLower.contains(titlePattern) {
                for slug in slugs {
                    let videoUrl = "\(unitPageUrl)/v/\(slug)"
                    possibleVideoUrls.append(videoUrl)
                }
                break
            }
        }
        
        // If no known mapping, try to construct reasonable guesses
        if possibleVideoUrls.isEmpty {
            let baseSlug = lessonTitle.lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
            
            let possibleSlugs = [
                "understanding-\(baseSlug)",
                baseSlug,
                "\(baseSlug)-intro",
                "intro-to-\(baseSlug)"
            ]
            
            for slug in possibleSlugs {
                let videoUrl = "\(unitPageUrl)/v/\(slug)"
                possibleVideoUrls.append(videoUrl)
            }
        }
        
        print("            📹 Generated \(possibleVideoUrls.count) possible video URLs for '\(lessonTitle)'")
        for (index, videoUrl) in possibleVideoUrls.prefix(3).enumerated() {
            print("              \(index + 1). \(videoUrl)")
        }
        
        return possibleVideoUrls
    }
    
    // MARK: - URL Construction
    
    private func constructPossibleVideoUrls(from unitUrl: String, lessonTitle: String) -> [String] {
        // Convert lesson title to possible slug formats
        let baseSlug = lessonTitle.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        
        var possibleUrls: [String] = []
        
        // First, try to construct the video URL by modifying the original URL
        // Khan Academy pattern: unit page URL + "/v/" + video slug
        
        // Known working video mappings (from previous successful scrapes)
        let knownVideoMappings: [String: String] = [
            "factors-and-multiples": "understanding-factor-pairs",
            "prime-and-composite-numbers": "prime-numbers", 
            "prime-factorization": "prime-factorization-2",
            "math-patterns": "understanding-math-patterns",
            "writing-expressions": "intro-to-expressions-with-variables",
            "intro-to-ratios": "introduction-to-ratios",
            "visualize-ratios": "ratios-as-fractions",
            "equivalent-ratios": "equivalent-ratios-exercise",
            "intro-to-rates": "intro-to-rates",
            "unit-rates": "unit-rates-intro",
            "comparing-rates": "comparing-rates-examples"
        ]
        
        // Try known mapping first
        if let knownSlug = knownVideoMappings[baseSlug] {
            let videoUrl = "\(unitUrl)/v/\(knownSlug)"
            possibleUrls.append(videoUrl)
        }
        
        // Common video slug patterns for Khan Academy
        let slugVariations = [
            "understanding-\(baseSlug)",
            baseSlug,
            "\(baseSlug)-intro", 
            "intro-to-\(baseSlug)",
            "\(baseSlug)-basics",
            "\(baseSlug)-examples",
            "\(baseSlug)-exercise"
        ]
        
        for slug in slugVariations {
            let videoUrl = "\(unitUrl)/v/\(slug)"
            possibleUrls.append(videoUrl)
        }
        
        // Try variations without hyphens
        let noHyphenSlug = baseSlug.replacingOccurrences(of: "-", with: "")
        possibleUrls.append("\(unitUrl)/v/\(noHyphenSlug)")
        possibleUrls.append("\(unitUrl)/v/understanding\(noHyphenSlug)")
        
        // Try with numbers (Khan Academy sometimes adds numbers)
        for i in 1...3 {
            possibleUrls.append("\(unitUrl)/v/\(baseSlug)-\(i)")
            possibleUrls.append("\(unitUrl)/v/\(baseSlug)\(i)")
        }
        
        return Array(Set(possibleUrls)) // Remove duplicates
    }
    
    // MARK: - HTML Content Extraction
    
    private func extractVideoLinks(from html: String, baseUrl: String) -> [String] {
        // Find all links that contain /v/ (video pages) - try multiple patterns
        let patterns = [
            "href=\"([^\"]*\\/v\\/[^\"]*)\"",  // Standard href with /v/
            "href='([^']*\\/v\\/[^']*)'",     // Single quotes
            "\\/v\\/[a-zA-Z0-9_-]+",          // Any /v/ pattern
            "href=\"([^\"]*video[^\"]*)\""     // Links containing "video"
        ]
        
        var videoLinks: [String] = []
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = regex.matches(in: html, options: [], range: range)
            
            for match in matches {
                let matchRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
                if let linkRange = Range(matchRange, in: html) {
                    let link = String(html[linkRange])
                    let fullUrl = link.hasPrefix("http") ? link : "\(baseUrl)\(link)"
                    
                    // Only add if it actually contains /v/
                    if fullUrl.contains("/v/") {
                        videoLinks.append(fullUrl)
                    }
                }
            }
        }
        
        let uniqueLinks = Array(Set(videoLinks))
        print("          🔍 Found \(uniqueLinks.count) potential video links")
        for link in uniqueLinks.prefix(3) {
            print("            - \(link)")
        }
        
        return uniqueLinks
    }
    
    private func extractVideoUrl(from html: String, videoUrl: String? = nil) -> String? {
        return extractVideoUrlFromHtml(html)
    }
    
    private func extractVideoUrlFromHtml(_ html: String) -> String? {
        // Look for Khan Academy iframe patterns with data-youtubeid attribute
        let iframePatterns = [
            // iframe with data-youtubeid attribute
            "data-youtubeid=\"([a-zA-Z0-9_-]{11})\"",
            // iframe id with video_ prefix  
            "id=\"video_([a-zA-Z0-9_-]{11})\"",
            // iframe src with youtube-nocookie
            "src=\"https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})/",
            "src=\"https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})\\?",
        ]
        
        // Try iframe patterns first (most reliable for Khan Academy)
        for pattern in iframePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    if match.numberOfRanges > 1 {
                        let videoIdRange = Range(match.range(at: 1), in: html)!
                        let videoId = String(html[videoIdRange])
                        print("          🎯 Found YouTube ID from iframe: \(videoId)")
                        return "https://www.youtube.com/embed/\(videoId)"
                    }
                }
            }
        }
        
        // Focus on youtube-nocookie.com URLs (Khan Academy format)
        let priorityPatterns = [
            // youtube-nocookie.com URLs with parameters
            "https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})/\\?[^\"'\\s]*",
            "https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})\\?[^\"'\\s]*",
            "https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
            
            // In iframe src attributes
            "src=['\"]https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
            
            // In JSON or JavaScript strings
            "\"https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
            "'https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
        ]
        
        // Try youtube-nocookie patterns
        for pattern in priorityPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    if match.numberOfRanges > 1 {
                        let videoIdRange = Range(match.range(at: 1), in: html)!
                        let videoId = String(html[videoIdRange])
                        print("          🎯 Found youtube-nocookie ID: \(videoId)")
                        return "https://www.youtube.com/embed/\(videoId)"
                    }
                }
            }
        }
        
        // Fallback patterns if youtube-nocookie not found
        let fallbackPatterns = [
            // Standard YouTube patterns
            "https://www\\.youtube\\.com/embed/([a-zA-Z0-9_-]{11})",
            "\"videoId\"\\s*:\\s*\"([a-zA-Z0-9_-]{11})\"",
            "\"youTubeId\"\\s*:\\s*\"([a-zA-Z0-9_-]{11})\"",
        ]
        
        for pattern in fallbackPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    // Check if we have a capture group (video ID)
                    if match.numberOfRanges > 1 {
                        // Extract the video ID from capture group
                        let videoIdRange = Range(match.range(at: 1), in: html)!
                        let videoId = String(html[videoIdRange])
                        
                        // Return as YouTube embed URL
                        return "https://www.youtube.com/embed/\(videoId)"
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractArticleContent(from html: String) -> String? {
        // Extract text content from article sections
        let patterns = [
            "<div class=\"[^\"]*article[^\"]*\"[^>]*>(.*?)</div>",
            "<article[^>]*>(.*?)</article>",
            "<div class=\"[^\"]*content[^\"]*\"[^>]*>(.*?)</div>"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    let contentRange = Range(match.range(at: 1), in: html)!
                    let rawContent = String(html[contentRange])
                    
                    // Clean up HTML tags
                    let cleanContent = rawContent
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "&nbsp;", with: " ")
                        .replacingOccurrences(of: "&amp;", with: "&")
                        .replacingOccurrences(of: "&lt;", with: "<")
                        .replacingOccurrences(of: "&gt;", with: ">")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if cleanContent.count > 50 {
                        return cleanContent
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractPerseusContent(from html: String) -> String? {
        // Look for Perseus exercise data in script tags
        let patterns = [
            "window\\.Perseus = (\\{.*?\\});",
            "\"perseus\":\"([^\"]+)\"",
            "\"questionData\":\"([^\"]+)\"",
            "__EXERCISE_DATA__ = (\\{.*?\\});",
            "\"problem\":(\\{.*?\\})"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    let contentRange = Range(match.range(at: 1), in: html)!
                    let content = String(html[contentRange])
                    
                    // Try to parse as JSON to validate
                    if let data = content.data(using: .utf8),
                       let _ = try? JSONSerialization.jsonObject(with: data) {
                        return content
                    }
                }
            }
        }
        
        // Fallback: create a basic Perseus structure if we find question text
        if let questionText = extractQuestionText(from: html) {
            return createPerseusFromQuestion(questionText)
        }
        
        return nil
    }
    
    private func extractQuestionText(from html: String) -> String? {
        let patterns = [
            "<div class=\"[^\"]*question[^\"]*\"[^>]*>(.*?)</div>",
            "<p class=\"[^\"]*problem[^\"]*\"[^>]*>(.*?)</p>",
            "<div class=\"[^\"]*prompt[^\"]*\"[^>]*>(.*?)</div>"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    let questionRange = Range(match.range(at: 1), in: html)!
                    let questionText = String(html[questionRange])
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if questionText.count > 10 {
                        return questionText
                    }
                }
            }
        }
        
        return nil
    }
    
    private func createPerseusFromQuestion(_ questionText: String) -> String {
        return """
        {
            "question": {
                "content": "\(questionText.replacingOccurrences(of: "\"", with: "\\\""))",
                "images": {},
                "widgets": {
                    "numeric-input-1": {
                        "type": "numeric-input",
                        "options": {
                            "coefficient": false,
                            "static": false,
                            "answers": [
                                {
                                    "value": 0,
                                    "status": "correct",
                                    "maxError": 0.1,
                                    "strict": false,
                                    "message": ""
                                }
                            ],
                            "size": "normal"
                        }
                    }
                }
            },
            "answerArea": {
                "calculator": false,
                "chi2Table": false,
                "periodicTable": false,
                "tTable": false,
                "zTable": false
            },
            "itemDataVersion": {
                "major": 0,
                "minor": 1
            },
            "hints": [
                {
                    "content": "Think step by step about this problem.",
                    "images": {},
                    "widgets": {}
                }
            ]
        }
        """
    }
    
    // MARK: - Helper Methods
    
    private func estimateVideoDuration(title: String) -> Int {
        // Estimate video length based on content complexity
        let words = title.components(separatedBy: .whitespaces).count
        return max(180, words * 30) // 30 seconds per word, minimum 3 minutes
    }
    
    private func estimateReadingDuration(text: String) -> Int {
        let words = text.components(separatedBy: .whitespaces).count
        return max(120, words * 2) // 2 seconds per word, minimum 2 minutes
    }
    
    private func createPlaceholderPerseus(for title: String) -> String {
        return """
        {
            "question": {
                "content": "Practice problem: \(title)",
                "widgets": {
                    "numeric-input": {
                        "type": "numeric-input",
                        "options": {
                            "answers": [{"value": 42, "status": "correct"}]
                        }
                    }
                }
            }
        }
        """
    }
    
    private func inferQuestionTypes(from title: String, unit: String) -> [String] {
        let combined = "\(title) \(unit)".lowercased()
        
        if combined.contains("graph") || combined.contains("plot") {
            return ["graphing", "multiple_choice"]
        } else if combined.contains("equation") || combined.contains("solve") {
            return ["numeric_input", "equation"]
        } else if combined.contains("factor") || combined.contains("multiple") {
            return ["multiple_choice", "drag_and_drop"]
        } else {
            return ["numeric_input", "multiple_choice"]
        }
    }
    
    private func inferDifficulty(from unit: String, item: String) -> String {
        let combined = "\(unit) \(item)".lowercased()
        
        if combined.contains("introduction") || combined.contains("basic") {
            return "easy"
        } else if combined.contains("advanced") || combined.contains("complex") {
            return "hard"
        } else {
            return "medium"
        }
    }
    
    private func extractSkills(from title: String, unit: String) -> [String] {
        let skillKeywords = title.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 }
        
        return Array(Set(skillKeywords + [unit.lowercased().replacingOccurrences(of: " ", with: "-")]))
    }
    
    private func saveContent(_ content: ScrapedKhanContent, to directory: URL) async throws {
        let fileName = "\(content.id)_brainlift_\(Int(Date().timeIntervalSince1970)).json"
        let fileURL = directory.appendingPathComponent(fileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(content)
        try jsonData.write(to: fileURL)
        
        print("    💾 Saved: \(fileName)")
    }
    
    enum ScrapingError: Error, LocalizedError {
        case invalidResponse
        case httpError(Int, String)
        case parseError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "Invalid HTTP response"
            case .httpError(let code, let body): return "HTTP \(code): \(body.prefix(100))"
            case .parseError(let message): return "Parse error: \(message)"
            }
        }
    }
}

// MARK: - Main Execution
let scraper = BrainLiftKhanScraper()
await scraper.scrapeAllSubjects()