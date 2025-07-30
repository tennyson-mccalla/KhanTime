#!/usr/bin/env swift

import Foundation

// Extract ALL YouTube URLs for all pre-algebra units (Units 2-15)
class AllPreAlgebraYouTubeExtractor {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    func extractAllPreAlgebraYouTubeUrls() async {
        print("🚀 Extracting ALL YouTube URLs for Pre-Algebra Units 2-15")
        print("=======================================================")
        
        // Get the main structure
        let path = "math/pre-algebra"
        
        if let json = await callContentForPath(path) {
            await extractAllVideoPathsFromAllUnits(json)
        }
    }
    
    private func extractAllVideoPathsFromAllUnits(_ json: [String: Any]) async {
        guard let data = json["data"] as? [String: Any],
              let contentRoute = data["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let course = listedPathData["course"] as? [String: Any],
              let unitChildren = course["unitChildren"] as? [[String: Any]] else {
            print("❌ Could not navigate to unitChildren")
            return
        }
        
        print("📊 Total units found: \(unitChildren.count)")
        
        var allMappings: [String] = []
        var totalVideos = 0
        var successfulExtractions = 0
        
        // Process all units (including Unit 1 for completeness)
        for (unitIndex, unit) in unitChildren.enumerated() {
            let unitTitle = unit["translatedTitle"] as? String ?? "Unknown Unit"
            let lessons = unit["allOrderedChildren"] as? [[String: Any]] ?? []
            
            print("\n📁 Unit \(unitIndex + 1): \(unitTitle)")
            print("Found \(lessons.count) lessons")
            
            // Go through each lesson in the unit
            for (lessonIndex, lesson) in lessons.enumerated() {
                let lessonTitle = lesson["translatedTitle"] as? String ?? "Unknown Lesson"
                let lessonTypename = lesson["__typename"] as? String ?? "Unknown"
                
                if lessonTypename == "Lesson",
                   let curatedChildren = lesson["curatedChildren"] as? [[String: Any]] {
                    
                    print("  📖 Lesson \(lessonIndex + 1): \(lessonTitle)")
                    
                    // Go through each step in the lesson
                    for (stepIndex, child) in curatedChildren.enumerated() {
                        let stepTitle = child["translatedTitle"] as? String ?? "Unknown"
                        let stepTypename = child["__typename"] as? String ?? "Unknown"
                        
                        if stepTypename == "Video" {
                            totalVideos += 1
                            print("    🎥 Video \(stepIndex + 1): \(stepTitle)")
                            
                            // Look for the video path
                            if let videoPath = child["urlWithinCurationNode"] as? String {
                                print("      Path: \(videoPath)")
                                
                                // Extract YouTube URL using this path
                                if let youtubeUrl = await extractYouTubeFromPath(videoPath) {
                                    successfulExtractions += 1
                                    print("      ✅ YouTube: \(youtubeUrl)")
                                    
                                    // Create mapping code
                                    if let youtubePart = youtubeUrl.components(separatedBy: "/embed/").last {
                                        let youtubeId = youtubePart.components(separatedBy: "?").first ?? youtubePart
                                        let mapping = "if titleLower.contains(\"\(stepTitle.lowercased())\") { return \"https://www.youtube.com/embed/\(youtubeId)\" }"
                                        allMappings.append(mapping)
                                    }
                                } else {
                                    print("      ❌ Could not extract YouTube URL")
                                }
                                
                                // Rate limiting - be more aggressive with delays for large extraction
                                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                            } else {
                                print("      ❌ No urlWithinCurationNode found")
                            }
                        }
                    }
                }
            }
        }
        
        print("\n📝 ALL PRE-ALGEBRA YOUTUBE MAPPINGS:")
        print("===================================")
        for (index, mapping) in allMappings.enumerated() {
            print("// \(index + 1)")
            print(mapping)
        }
        
        print("\n📊 EXTRACTION SUMMARY:")
        print("=====================")
        print("Total videos found: \(totalVideos)")
        print("Successful extractions: \(successfulExtractions)")
        print("Success rate: \(successfulExtractions > 0 ? (successfulExtractions * 100 / totalVideos) : 0)%")
        print("Total mappings created: \(allMappings.count)")
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
            request.timeoutInterval = 60.0 // Longer timeout for stability
            
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
    
    private func extractYouTubeFromPath(_ path: String) async -> String? {
        // Clean the path
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        
        let urlString = "\(baseURL)/api/internal/graphql/ContentForPath"
        let variables = ["path": cleanPath, "countryCode": "US"]
        
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
            request.timeoutInterval = 60.0
            
            let headers = [
                "Accept": "*/*",
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15"
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
            
            return extractYouTubeFromGraphQL(json)
            
        } catch {
            return nil
        }
    }
    
    private func extractYouTubeFromGraphQL(_ json: [String: Any]) -> String? {
        guard let data = json["data"] as? [String: Any],
              let contentRoute = data["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let content = listedPathData["content"] as? [String: Any] else {
            return nil
        }
        
        if let downloadUrlsString = content["downloadUrls"] as? String,
           let downloadUrlsData = downloadUrlsString.data(using: .utf8),
           let downloadUrls = try? JSONSerialization.jsonObject(with: downloadUrlsData) as? [String: Any],
           let mp4Url = downloadUrls["mp4"] as? String {
            
            let youtubeIdPattern = "ka-youtube-converted/([a-zA-Z0-9_-]{11})\\."
            
            if let regex = try? NSRegularExpression(pattern: youtubeIdPattern, options: []) {
                let range = NSRange(mp4Url.startIndex..<mp4Url.endIndex, in: mp4Url)
                if let match = regex.firstMatch(in: mp4Url, options: [], range: range),
                   match.numberOfRanges > 1 {
                    let youtubeIdRange = Range(match.range(at: 1), in: mp4Url)!
                    let youtubeId = String(mp4Url[youtubeIdRange])
                    return "https://www.youtube.com/embed/\(youtubeId)"
                }
            }
        }
        
        return nil
    }
}

// Main execution
let extractor = AllPreAlgebraYouTubeExtractor()

Task {
    await extractor.extractAllPreAlgebraYouTubeUrls()
    print("\n🎉 All pre-algebra YouTube URL extraction complete!")
    exit(0)
}

RunLoop.main.run()