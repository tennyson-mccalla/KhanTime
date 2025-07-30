#!/usr/bin/env swift

import Foundation

// Simple structure for the output
struct SimpleKhanContent: Codable {
    let id: String
    let subject: String
    let title: String
    let description: String
    let units: [SimpleUnit]
    let scrapedAt: String
    
    struct SimpleUnit: Codable {
        let id: String
        let title: String
        let description: String
        let lessons: [SimpleLesson]
        let exercises: [SimpleExercise]
        
        struct SimpleLesson: Codable {
            let id: String
            let title: String
            let description: String
            let contentKind: String
            let duration: Int?
            let lessonSteps: [LessonStep]?
            
            struct LessonStep: Codable {
                let id: String
                let title: String
                let description: String
                let type: String
                let youtubeUrl: String?
            }
        }
        
        struct SimpleExercise: Codable {
            let id: String
            let title: String
            let description: String
        }
    }
}

class SimpleKhanScraper {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    func scrapePreAlgebra() async throws -> SimpleKhanContent {
        print("🎯 Scraping pre-algebra structure...")
        
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
        
        var units: [SimpleKhanContent.SimpleUnit] = []
        
        for (index, unitData) in unitChildren.enumerated() {
            let unitTitle = unitData["translatedTitle"] as? String ?? "Unit \(index + 1)"
            let unitDescription = unitData["translatedDescription"] as? String ?? ""
            let unitId = unitData["id"] as? String ?? "unit_\(index)"
            
            print("  📁 Unit \(index + 1): \(unitTitle)")
            
            var lessons: [SimpleKhanContent.SimpleUnit.SimpleLesson] = []
            var exercises: [SimpleKhanContent.SimpleUnit.SimpleExercise] = []
            
            if let children = unitData["allOrderedChildren"] as? [[String: Any]] {
                for child in children {
                    let childTitle = child["translatedTitle"] as? String ?? ""
                    let childDescription = child["translatedDescription"] as? String ?? ""
                    let childId = child["id"] as? String ?? ""
                    let contentKind = child["contentKind"] as? String ?? "unknown"
                    
                    if contentKind == "lesson" {
                        let lesson = SimpleKhanContent.SimpleUnit.SimpleLesson(
                            id: childId,
                            title: childTitle,
                            description: childDescription,
                            contentKind: contentKind,
                            duration: nil,
                            lessonSteps: nil
                        )
                        lessons.append(lesson)
                    } else if contentKind == "exercise" {
                        let exercise = SimpleKhanContent.SimpleUnit.SimpleExercise(
                            id: childId,
                            title: childTitle,
                            description: childDescription
                        )
                        exercises.append(exercise)
                    }
                }
            }
            
            print("    → \(lessons.count) lessons, \(exercises.count) exercises")
            
            let unit = SimpleKhanContent.SimpleUnit(
                id: unitId,
                title: unitTitle,
                description: unitDescription,
                lessons: lessons,
                exercises: exercises
            )
            units.append(unit)
        }
        
        let content = SimpleKhanContent(
            id: "pre-algebra",
            subject: "pre-algebra",
            title: courseTitle,
            description: courseDescription,
            units: units,
            scrapedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        return content
    }
}

// Main execution
print("🚀 Simple Khan Academy Pre-Algebra Scraper")
print("==========================================")

let scraper = SimpleKhanScraper()

Task {
    do {
        let content = try await scraper.scrapePreAlgebra()
        
        // Save to file
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let jsonData = try encoder.encode(content)
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "pre-algebra_complete_\(timestamp).json"
        let url = URL(fileURLWithPath: "./brainlift_output/\(filename)")
        
        // Create directory if needed
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        try jsonData.write(to: url)
        
        print("\n🎉 Success!")
        print("📁 Saved to: \(filename)")
        print("📊 Total units: \(content.units.count)")
        print("📊 Total lessons: \(content.units.reduce(0) { $0 + $1.lessons.count })")
        print("📊 Total exercises: \(content.units.reduce(0) { $0 + $1.exercises.count })")
        
        exit(0)
        
    } catch {
        print("❌ Error: \(error)")
        exit(1)
    }
}

RunLoop.main.run()