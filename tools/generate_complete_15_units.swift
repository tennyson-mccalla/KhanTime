#!/usr/bin/env swift

import Foundation

class Complete15UnitsGenerator {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    func generateComplete15Units() async {
        print("🎯 Generating complete 15-unit pre-algebra dataset...")
        print("==================================================")
        
        // Load existing Units 1-3 data
        guard let units13Data = loadUnits13Data() else {
            print("❌ Failed to load Units 1-3 data")
            return
        }
        
        // Load Units 4-15 YouTube mappings
        guard let units415YouTube = loadUnits415YouTube() else {
            print("❌ Failed to load Units 4-15 YouTube mappings")
            return
        }
        
        print("✅ Loaded Units 1-3 structure with \(countVideosInUnits13(units13Data)) videos")
        print("✅ Loaded \(units415YouTube.count) YouTube URLs for Units 4-15")
        
        // Get complete course structure
        let path = "math/pre-algebra"
        guard let json = await callContentForPath(path) else {
            print("❌ Failed to get course structure")
            return
        }
        
        // Generate complete dataset
        if let completeDataset = await generateCompleteDataset(units13Data: units13Data, units415YouTube: units415YouTube, courseJson: json) {
            await saveCompleteDataset(completeDataset)
        }
    }
    
    private func loadUnits13Data() -> [String: Any]? {
        let filePath = "Source/Resources/pre-algebra_units_1_3_complete.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
    
    private func loadUnits415YouTube() -> [String: String]? {
        let filePath = "tools/brainlift_output/pre-algebra_units_4_15_youtube_1753910955.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        return json
    }
    
    private func countVideosInUnits13(_ data: [String: Any]) -> Int {
        guard let units = data["units"] as? [[String: Any]] else { return 0 }
        var count = 0
        for unit in units {
            guard let lessons = unit["lessons"] as? [[String: Any]] else { continue }
            for lesson in lessons {
                guard let steps = lesson["lessonSteps"] as? [[String: Any]] else { continue }
                for step in steps {
                    if let type = step["type"] as? String, type == "video" {
                        count += 1
                    }
                }
            }
        }
        return count
    }
    
    private func generateCompleteDataset(units13Data: [String: Any], units415YouTube: [String: String], courseJson: [String: Any]) async -> [String: Any]? {
        guard let data = courseJson["data"] as? [String: Any],
              let contentRoute = data["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let course = listedPathData["course"] as? [String: Any],
              let unitChildren = course["unitChildren"] as? [[String: Any]] else {
            print("❌ Could not navigate to course structure")
            return nil
        }
        
        // Start with Units 1-3 data
        var completeData = units13Data
        guard var units = completeData["units"] as? [[String: Any]] else {
            print("❌ Could not access units array")
            return nil
        }
        
        // Add Units 4-15
        for unitIndex in 3..<min(15, unitChildren.count) {
            let unit = unitChildren[unitIndex]
            let unitTitle = unit["translatedTitle"] as? String ?? "Unknown Unit"
            let unitDescription = unit["translatedDescription"] as? String ?? ""
            let lessons = unit["allOrderedChildren"] as? [[String: Any]] ?? []
            
            print("\n📁 Processing Unit \(unitIndex + 1): \(unitTitle)")
            
            var newUnit: [String: Any] = [
                "id": "unit_\(unitIndex + 1)",
                "title": unitTitle,
                "description": unitDescription,
                "lessons": [],
                "exercises": []
            ]
            
            var newLessons: [[String: Any]] = []
            
            for lesson in lessons {
                let lessonTitle = lesson["translatedTitle"] as? String ?? "Unknown"
                let lessonDescription = lesson["translatedDescription"] as? String ?? ""
                let lessonTypename = lesson["__typename"] as? String ?? "Unknown"
                
                if lessonTypename == "Lesson",
                   let curatedChildren = lesson["curatedChildren"] as? [[String: Any]] {
                    
                    print("  📖 \(lessonTitle)")
                    
                    var lessonSteps: [[String: Any]] = []
                    
                    for child in curatedChildren {
                        let stepTitle = child["translatedTitle"] as? String ?? "Unknown"
                        let stepDescription = child["translatedDescription"] as? String ?? ""
                        let stepTypename = child["__typename"] as? String ?? "Unknown"
                        let stepId = child["id"] as? String ?? "unknown_\(UUID().uuidString)"
                        
                        var step: [String: Any] = [
                            "id": stepId,
                            "title": stepTitle,
                            "description": stepDescription
                        ]
                        
                        if stepTypename == "Video" {
                            step["type"] = "video"
                            if let youtubeUrl = units415YouTube[stepTitle] {
                                step["youtubeUrl"] = youtubeUrl
                                print("    ✅ \(stepTitle)")
                            } else {
                                step["youtubeUrl"] = ""
                                print("    ❌ Missing YouTube URL for: \(stepTitle)")
                            }
                        } else if stepTypename == "Exercise" {
                            step["type"] = "exercise"
                            print("    📝 \(stepTitle)")
                        } else {
                            step["type"] = "other"
                            print("    ❓ \(stepTitle) (type: \(stepTypename))")
                        }
                        
                        lessonSteps.append(step)
                    }
                    
                    let newLesson: [String: Any] = [
                        "id": "lesson_\(unitIndex + 1)_\(newLessons.count + 1)",
                        "title": lessonTitle,
                        "description": lessonDescription,
                        "contentKind": "lesson",
                        "duration": 1500,
                        "lessonSteps": lessonSteps
                    ]
                    
                    newLessons.append(newLesson)
                }
            }
            
            newUnit["lessons"] = newLessons
            units.append(newUnit)
        }
        
        completeData["units"] = units
        completeData["scrapedAt"] = ISO8601DateFormatter().string(from: Date())
        
        return completeData
    }
    
    private func saveCompleteDataset(_ data: [String: Any]) async {
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "tools/brainlift_output/pre-algebra_complete_15_units_\(timestamp).json"
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            try jsonData.write(to: URL(fileURLWithPath: filename))
            
            print("\n📊 GENERATION SUMMARY:")
            print("=====================")
            if let units = data["units"] as? [[String: Any]] {
                print("Total units: \(units.count)")
                
                var totalLessons = 0
                var totalVideos = 0
                var totalExercises = 0
                
                for unit in units {
                    if let lessons = unit["lessons"] as? [[String: Any]] {
                        totalLessons += lessons.count
                        
                        for lesson in lessons {
                            if let steps = lesson["lessonSteps"] as? [[String: Any]] {
                                for step in steps {
                                    if let type = step["type"] as? String {
                                        if type == "video" {
                                            totalVideos += 1
                                        } else if type == "exercise" {
                                            totalExercises += 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                print("Total lessons: \(totalLessons)")
                print("Total videos: \(totalVideos)")
                print("Total exercises: \(totalExercises)")
            }
            
            print("💾 Saved complete dataset to: \(filename)")
            print("\n🎯 Next steps:")
            print("1. Copy this file to Source/Resources/")
            print("2. Update KhanAcademyContentProvider to use this file")
            print("3. Test in iPad app")
            
        } catch {
            print("❌ Error saving complete dataset: \(error)")
        }
    }
    
    private func callContentForPath(_ path: String) async -> [String: Any]? {
        let urlString = "\(baseURL)/api/internal/graphql/ContentForPath"
        let variables = ["path": path, "countryCode": "US"]
        
        do {
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
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            
            return json
            
        } catch {
            print("❌ Error: \(error)")
            return nil
        }
    }
}

// Main execution
Task {
    let generator = Complete15UnitsGenerator()
    await generator.generateComplete15Units()
    exit(0)
}

RunLoop.main.run()