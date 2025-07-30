#!/usr/bin/env swift

import Foundation

// Complete Khan Academy data structure
struct CompleteKhanContent: Codable {
    let id: String
    let subject: String
    let title: String
    let description: String
    let units: [KhanUnit]
    let scrapedAt: String
    
    struct KhanUnit: Codable {
        let id: String
        let title: String
        let description: String
        let lessons: [KhanLesson]
        let exercises: [KhanExercise]
        
        struct KhanLesson: Codable {
            let id: String
            let title: String
            let description: String
            let contentKind: String
            let duration: Int?
            let lessonSteps: [LessonStep]
            
            struct LessonStep: Codable {
                let id: String
                let title: String
                let description: String
                let type: String
                let youtubeUrl: String?
            }
        }
        
        struct KhanExercise: Codable {
            let id: String
            let title: String
            let description: String
        }
    }
}

class FinalKhanScraper {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    func scrapeCompletePreAlgebra() async throws -> CompleteKhanContent {
        print("🎯 Scraping complete pre-algebra structure...")
        
        let path = "math/pre-algebra"
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
        request.timeoutInterval = 30.0
        
        let headers = [
            "Accept": "*/*",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15",
            "Referer": "\(baseURL)/\(path)"
        ]
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "HTTP", code: 0, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let data = json["data"] as? [String: Any],
              let contentRoute = data["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let course = listedPathData["course"] as? [String: Any] else {
            throw NSError(domain: "Parse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse response"])
        }
        
        let courseTitle = course["translatedTitle"] as? String ?? "Pre-algebra"
        let courseDescription = course["translatedDescription"] as? String ?? "Learn pre-algebra—all of the basic arithmetic and geometry skills needed for algebra."
        
        guard let unitChildren = course["unitChildren"] as? [[String: Any]] else {
            throw NSError(domain: "Parse", code: 0, userInfo: [NSLocalizedDescriptionKey: "No units found"])
        }
        
        print("✅ Found \(unitChildren.count) units")
        
        var units: [CompleteKhanContent.KhanUnit] = []
        
        for (unitIndex, unitData) in unitChildren.enumerated() {
            let unitTitle = unitData["translatedTitle"] as? String ?? "Unit \(unitIndex + 1)"
            let unitDescription = unitData["translatedDescription"] as? String ?? ""
            let unitId = unitData["id"] as? String ?? "unit_\(unitIndex)"
            
            print("  📁 Unit \(unitIndex + 1): \(unitTitle)")
            
            var lessons: [CompleteKhanContent.KhanUnit.KhanLesson] = []
            var exercises: [CompleteKhanContent.KhanUnit.KhanExercise] = []
            
            if let children = unitData["allOrderedChildren"] as? [[String: Any]] {
                for child in children {
                    let childTitle = child["translatedTitle"] as? String ?? ""
                    let childDescription = child["translatedDescription"] as? String ?? ""
                    let childId = child["id"] as? String ?? ""
                    let childTypename = child["__typename"] as? String ?? "unknown"
                    
                    if childTypename == "Lesson" {
                        // Process lesson with all its curated children (videos, exercises, articles)
                        var lessonSteps: [CompleteKhanContent.KhanUnit.KhanLesson.LessonStep] = []
                        
                        if let curatedChildren = child["curatedChildren"] as? [[String: Any]] {
                            for curatedChild in curatedChildren {
                                let stepTitle = curatedChild["translatedTitle"] as? String ?? ""
                                let stepDescription = curatedChild["translatedDescription"] as? String ?? ""
                                let stepId = curatedChild["id"] as? String ?? ""
                                let stepTypename = curatedChild["__typename"] as? String ?? "unknown"
                                
                                // Convert typename to our format
                                let stepType: String
                                var youtubeUrl: String? = nil
                                
                                switch stepTypename {
                                case "Video":
                                    stepType = "video"
                                    // Map to actual YouTube URL using title-based mapping
                                    youtubeUrl = mapToYouTubeUrl(stepTitle)
                                case "Exercise":
                                    stepType = "exercise"
                                case "Article":
                                    stepType = "article"
                                default:
                                    stepType = stepTypename.lowercased()
                                }
                                
                                let step = CompleteKhanContent.KhanUnit.KhanLesson.LessonStep(
                                    id: stepId,
                                    title: stepTitle,
                                    description: stepDescription,
                                    type: stepType,
                                    youtubeUrl: youtubeUrl
                                )
                                lessonSteps.append(step)
                            }
                        }
                        
                        let lesson = CompleteKhanContent.KhanUnit.KhanLesson(
                            id: childId,
                            title: childTitle,
                            description: childDescription,
                            contentKind: "lesson",
                            duration: lessonSteps.filter { $0.type == "video" }.count * 300, // Estimate 5 min per video
                            lessonSteps: lessonSteps
                        )
                        lessons.append(lesson)
                        
                        print("    🎥 Lesson: \(childTitle) (\(lessonSteps.count) steps)")
                        
                    } else if childTypename == "Exercise" {
                        let exercise = CompleteKhanContent.KhanUnit.KhanExercise(
                            id: childId,
                            title: childTitle,
                            description: childDescription
                        )
                        exercises.append(exercise)
                        
                        print("    📝 Exercise: \(childTitle)")
                    }
                    // Skip TopicQuiz and TopicUnitTest for now
                }
            }
            
            print("    → \(lessons.count) lessons, \(exercises.count) exercises")
            
            let unit = CompleteKhanContent.KhanUnit(
                id: unitId,
                title: unitTitle,
                description: unitDescription,
                lessons: lessons,
                exercises: exercises
            )
            units.append(unit)
        }
        
        let content = CompleteKhanContent(
            id: "pre-algebra",
            subject: "pre-algebra", 
            title: courseTitle,
            description: courseDescription,
            units: units,
            scrapedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        return content
    }
    
    private func mapToYouTubeUrl(_ title: String) -> String? {
        // Map known Khan Academy lessons to their actual YouTube IDs
        let titleLower = title.lowercased()
        
        // Unit 1: Factors and multiples
        if titleLower.contains("understanding factor pairs") {
            return "https://www.youtube.com/embed/KcKOM7Degu0"
        }
        
        if titleLower.contains("finding factors of a number") {
            return "https://www.youtube.com/embed/vcn2ruTOwFo"
        }
        
        if titleLower.contains("reasoning about factors and multiples") {
            return "https://www.youtube.com/embed/g805f4HlV1Y"
        }
        
        if titleLower.contains("finding factors and multiples") {
            return "https://www.youtube.com/embed/5xe-6GPR_qQ"
        }
        
        if titleLower.contains("identifying multiples") {
            return "https://www.youtube.com/embed/U5L_aaQ6pYQ"
        }
        
        // Unit 1: Prime numbers and factorization
        if titleLower.contains("prime numbers") {
            return "https://www.youtube.com/embed/mIStB5X4U8M"
        }
        
        if titleLower.contains("recognizing prime and composite numbers") {
            return "https://www.youtube.com/embed/3h4UK62Qrbo"
        }
        
        if titleLower.contains("prime factorization exercise") {
            return "https://www.youtube.com/embed/XWq8bplP-_E"
        }
        
        if titleLower.contains("prime factorization") {
            return "https://www.youtube.com/embed/ZKKDTfHcsG0"
        }
        
        if titleLower.contains("common divisibility examples") {
            return "https://www.youtube.com/embed/zWcfVC-oCNw"
        }
        
        // Units 2-3: Patterns & Ratios/Rates
        if titleLower.contains("factors and multiples: days of the week") {
            return "https://www.youtube.com/embed/S7CLLRHe8ik"
        }
        
        if titleLower.contains("math patterns: table") {
            return "https://www.youtube.com/embed/KSrnZMAfwTM"
        }
        
        if titleLower.contains("math patterns: toothpicks") {
            return "https://www.youtube.com/embed/mFftY8Y_pyY"
        }
        
        if titleLower.contains("constructing numerical expressions") {
            return "https://www.youtube.com/embed/arY-EUZDNfk"
        }
        
        if titleLower.contains("evaluating expressions with & without parentheses") {
            return "https://www.youtube.com/embed/-rxUip6Ulnw"
        }
        
        if titleLower.contains("translating expressions with parentheses") {
            return "https://www.youtube.com/embed/ypxHVqE26gI"
        }
        
        if titleLower.contains("graphing patterns on coordinate plane") {
            return "https://www.youtube.com/embed/ayRpoJgph0E"
        }
        
        if titleLower.contains("interpreting patterns on coordinate plane") {
            return "https://www.youtube.com/embed/HXg_a9oJ5nA"
        }
        
        if titleLower.contains("interpreting relationships in ordered pairs") {
            return "https://www.youtube.com/embed/Muba9-W2FOQ"
        }
        
        if titleLower.contains("graphing sequence relationships") {
            return "https://www.youtube.com/embed/mqsIJucBn6c"
        }
        
        if titleLower.contains("intro to ratios") {
            return "https://www.youtube.com/embed/bIKmw0aTmYc"
        }
        
        if titleLower.contains("basic ratios") {
            return "https://www.youtube.com/embed/IjMn7f6bbLA"
        }
        
        if titleLower.contains("part:whole ratios") {
            return "https://www.youtube.com/embed/UK-_qEDtvYo"
        }
        
        if titleLower.contains("ratios with tape diagrams") {
            return "https://www.youtube.com/embed/suRIY3ULrQo"
        }
        
        if titleLower.contains("equivalent ratio word problems") {
            return "https://www.youtube.com/embed/WoZ7-wOy-0w"
        }
        
        if titleLower.contains("ratios and double number lines") {
            return "https://www.youtube.com/embed/-Dg9da1BGsM"
        }
        
        if titleLower.contains("solving ratio problems with tables") {
            return "https://www.youtube.com/embed/MaMk6-f3T9k"
        }
        
        if titleLower.contains("equivalent ratios: recipe") {
            return "https://www.youtube.com/embed/VWO1m0S-a9Y"
        }
        
        if titleLower.contains("understanding equivalent ratios") {
            return "https://www.youtube.com/embed/4S3Mbl0JrdY"
        }
        
        if titleLower.contains("ratios on coordinate plane") {
            return "https://www.youtube.com/embed/yVYJRT5hTSo"
        }
        
        if titleLower.contains("ratios and measurement") {
            return "https://www.youtube.com/embed/0qtIHdda19s"
        }
        
        if titleLower.contains("part to whole ratio word problem using tables") {
            return "https://www.youtube.com/embed/ZJ6y8OVJRw8"
        }
        
        if titleLower.contains("intro to rates") {
            return "https://www.youtube.com/embed/qGTYSAeLTOE"
        }
        
        if titleLower.contains("solving unit rate problem") {
            return "https://www.youtube.com/embed/Zm0KaIw-35k"
        }
        
        if titleLower.contains("solving unit price problem") {
            return "https://www.youtube.com/embed/rpGGMSFO6Ks"
        }
        
        if titleLower.contains("rate problems") {
            return "https://www.youtube.com/embed/fpjXtpg_isc"
        }
        
        if titleLower.contains("comparing rates example") {
            return "https://www.youtube.com/embed/C7bBZa52h-4"
        }
        
        // Handle duplicate "equivalent ratios" (generic one comes after specific ones)
        if titleLower.contains("equivalent ratios") && !titleLower.contains("recipe") && !titleLower.contains("understanding") {
            return "https://www.youtube.com/embed/eb-GHXCqkhQ"
        }
        
        // Add more mappings as we identify them
        print("⚠️ No YouTube mapping found for: '\(title)'")
        return nil
    }
}

// Main execution
print("🚀 Final Khan Academy Pre-Algebra Scraper")
print("=========================================")

let scraper = FinalKhanScraper()

Task {
    do {
        let content = try await scraper.scrapeCompletePreAlgebra()
        
        // Save to file
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let jsonData = try encoder.encode(content)
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "pre-algebra_final_complete_\(timestamp).json"
        let url = URL(fileURLWithPath: "./brainlift_output/\(filename)")
        
        // Create directory if needed
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        try jsonData.write(to: url)
        
        print("\n🎉 SUCCESS! Complete Pre-Algebra Dataset Generated!")
        print("📁 Saved to: \(filename)")
        print("📊 Total units: \(content.units.count)")
        print("📊 Total lessons: \(content.units.reduce(0) { $0 + $1.lessons.count })")
        print("📊 Total lesson steps: \(content.units.reduce(0) { $0 + $1.lessons.reduce(0) { $0 + $1.lessonSteps.count } })")
        print("📊 Total exercises: \(content.units.reduce(0) { $0 + $1.exercises.count })")
        
        exit(0)
        
    } catch {
        print("❌ Error: \(error)")
        exit(1)
    }
}

RunLoop.main.run()