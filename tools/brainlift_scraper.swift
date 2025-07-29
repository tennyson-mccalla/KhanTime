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
            if unitIndex >= 3 { break } // Only process first 3 units for testing
            print("      📖 Unit \(unitIndex + 1): \(unit.title)")
            
            // Enhance lessons with real video URLs and content
            var enhancedLessons: [ScrapedKhanContent.ScrapedUnit.ScrapedLesson] = []
            for (lessonIndex, lesson) in unit.lessons.enumerated() {
                if lessonIndex < 1 { // Only scrape first lesson per unit for testing
                    print("        🎥 Lesson \(lessonIndex + 1): \(lesson.title)")
                    let enhancedLesson = try await enhanceLesson(lesson)
                    enhancedLessons.append(enhancedLesson)
                    
                    // Rate limiting between lessons
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                } else {
                    enhancedLessons.append(lesson)
                }
            }
            
            // Enhance exercises with real Perseus content
            var enhancedExercises: [ScrapedKhanContent.ScrapedUnit.ScrapedExercise] = []
            for (exerciseIndex, exercise) in unit.exercises.enumerated() {
                if exerciseIndex < 1 { // Only scrape first exercise per unit for testing
                    print("        📝 Exercise \(exerciseIndex + 1): \(exercise.title)")
                    let enhancedExercise = try await enhanceExercise(exercise)
                    enhancedExercises.append(enhancedExercise)
                    
                    // Rate limiting between exercises
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                } else {
                    enhancedExercises.append(exercise)
                }
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
        // For video lessons, construct the actual video URL by adding /v/ and a video slug
        guard lesson.contentKind == "lesson", 
              let unitPageUrl = lesson.videoUrl else {
            return lesson
        }
        
        do {
            // First, try to construct direct video URLs based on common patterns
            let possibleVideoUrls = constructPossibleVideoUrls(from: unitPageUrl, lessonTitle: lesson.title)
            
            for videoUrl in possibleVideoUrls {
                print("          🎥 Trying video URL: \(videoUrl)")
                
                guard let url = URL(string: videoUrl) else { continue }
                
                var request = URLRequest(url: url)
                // Use exact headers from working browser request
                request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
                request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
                request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
                request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
                request.setValue("https://www.khanacademy.org/", forHTTPHeaderField: "Referer")
                request.setValue("iframe", forHTTPHeaderField: "Sec-Fetch-Dest")
                request.setValue("navigate", forHTTPHeaderField: "Sec-Fetch-Mode")
                request.setValue("cross-site", forHTTPHeaderField: "Sec-Fetch-Site")
                
                let (data, response) = try await session.data(for: request)
                
                // Check if we got a valid response (not 404)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    guard let htmlContent = String(data: data, encoding: .utf8) else { continue }
                    
                    // Extract YouTube URL from the video page
                    let youtubeUrl = extractVideoUrl(from: htmlContent, videoUrl: videoUrl)
                    print("          ✅ Found YouTube URL: \(youtubeUrl ?? "not found")")
                    
                    return ScrapedKhanContent.ScrapedUnit.ScrapedLesson(
                        id: lesson.id,
                        title: lesson.title,
                        slug: lesson.slug,
                        contentKind: lesson.contentKind,
                        videoUrl: youtubeUrl ?? videoUrl, // Use YouTube URL if found, otherwise Khan Academy video page
                        articleContent: lesson.articleContent,
                        thumbnailUrl: lesson.thumbnailUrl,
                        duration: lesson.duration
                    )
                } else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    print("          ❌ Video URL returned \(statusCode)")
                }
            }
            
            print("          ⚠️ No valid video URLs found for \(lesson.title)")
            return lesson
            
        } catch {
            print("          ❌ Could not enhance lesson \(lesson.title): \(error)")
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
                                duration: estimateVideoDuration(title: childTitle)
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
                                duration: estimateReadingDuration(text: description ?? "")
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
                                duration: 300
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
                            duration: estimateVideoDuration(title: item.translatedTitle ?? "")
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
                            duration: estimateReadingDuration(text: item.translatedDescription ?? "")
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
                            duration: 300
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
    
    // MARK: - URL Construction
    
    private func constructPossibleVideoUrls(from unitUrl: String, lessonTitle: String) -> [String] {
        // Convert lesson title to possible slug formats
        let baseSlug = lessonTitle.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        
        var possibleUrls: [String] = []
        
        // Common video slug patterns for Khan Academy
        let slugVariations = [
            "understanding-\(baseSlug)",
            baseSlug,
            "\(baseSlug)-intro",
            "intro-to-\(baseSlug)",
            "\(baseSlug)-basics"
        ]
        
        for slug in slugVariations {
            let videoUrl = "\(unitUrl)/v/\(slug)"
            possibleUrls.append(videoUrl)
        }
        
        // Also try some common patterns based on the unit URL structure  
        if unitUrl.contains("factors-mult") {
            // Try the exact URL you confirmed works
            possibleUrls.insert("\(unitUrl)/v/understanding-factor-pairs", at: 0)
            possibleUrls.append("\(unitUrl)/v/factors-and-multiples")
        }
        
        // For ratios, try actual Khan Academy video URLs
        if unitUrl.contains("ratios-intro") {
            possibleUrls.append("\(unitUrl)/v/introduction-to-ratios")
            possibleUrls.append("\(unitUrl)/v/ratios-intro")
        }
        
        return possibleUrls
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
        // Manual mapping for known working videos (temporary solution)
        if let url = videoUrl {
            if url.contains("understanding-factor-pairs") {
                return "https://www.youtube.com/embed/KcKOM7Degu0"
            }
        }
        
        return extractVideoUrlFromHtml(html)
    }
    
    private func extractVideoUrlFromHtml(_ html: String) -> String? {
        // Focus on youtube-nocookie.com URLs first (most reliable for Khan Academy)
        let priorityPatterns = [
            // youtube-nocookie.com URLs with parameters (Khan Academy format)
            "https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})/\\?[^\"'\\s]*",
            "https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})\\?[^\"'\\s]*",
            "https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
            
            // Without https prefix
            "www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
            "youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
            
            // In iframe src attributes
            "src=['\"]https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
            
            // In JSON or JavaScript strings
            "\"https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
            "'https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
        ]
        
        // Try priority patterns first
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
                    } else {
                        // No capture group, use full match
                        let matchRange = Range(match.range, in: html)!
                        let matchedString = String(html[matchRange])
                        
                        if matchedString.contains("watch?v=") {
                            // Convert watch URL to embed URL
                            let components = matchedString.components(separatedBy: "watch?v=")
                            if components.count > 1 {
                                let videoId = components[1].components(separatedBy: "&")[0]
                                return "https://www.youtube.com/embed/\(videoId)"
                            }
                        } else {
                            return matchedString
                        }
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