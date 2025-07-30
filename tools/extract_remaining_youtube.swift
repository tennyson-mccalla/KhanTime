#!/usr/bin/env swift

import Foundation

class RemainingYouTubeExtractor {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    func extractRemainingUnits() async {
        print("🎯 Extracting YouTube URLs for Units 4-15...")
        print("============================================")
        
        let path = "math/pre-algebra"
        
        if let json = await callContentForPath(path) {
            await extractVideosFromUnits4To15(json)
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
                  httpResponse.statusCode == 200 else {
                print("❌ HTTP request failed")
                return nil
            }
            
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
        } catch {
            print("❌ Error calling ContentForPath: \(error)")
            return nil
        }
    }
    
    private func extractVideosFromUnits4To15(_ json: [String: Any]) async {
        guard let data = json["data"] as? [String: Any],
              let contentRoute = data["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let course = listedPathData["course"] as? [String: Any],
              let unitChildren = course["unitChildren"] as? [[String: Any]] else {
            print("❌ Could not navigate to unitChildren")
            return
        }
        
        var allYouTubeURLs: [String: String] = [:]
        var totalVideos = 0
        
        // Process Units 4-15 (indices 3-14)
        for unitIndex in 3..<min(15, unitChildren.count) {
            let unit = unitChildren[unitIndex]
            let unitTitle = unit["translatedTitle"] as? String ?? "Unknown Unit"
            let lessons = unit["allOrderedChildren"] as? [[String: Any]] ?? []
            
            print("\n📁 Unit \(unitIndex + 1): \(unitTitle)")
            
            for lesson in lessons {
                let lessonTitle = lesson["translatedTitle"] as? String ?? "Unknown"
                let lessonTypename = lesson["__typename"] as? String ?? "Unknown"
                
                if lessonTypename == "Lesson",
                   let curatedChildren = lesson["curatedChildren"] as? [[String: Any]] {
                    
                    print("  📚 \(lessonTitle)")
                    
                    for step in curatedChildren {
                        if let stepTitle = step["translatedTitle"] as? String,
                           let stepTypename = step["__typename"] as? String,
                           stepTypename == "Video",
                           let downloadUrls = step["downloadUrls"] as? [String] {
                            
                            if let youtubeID = extractYouTubeID(from: downloadUrls) {
                                let youtubeURL = "https://www.youtube.com/embed/\(youtubeID)"
                                allYouTubeURLs[stepTitle] = youtubeURL
                                totalVideos += 1
                                print("    ✅ \(stepTitle) -> \(youtubeID)")
                            }
                        }
                    }
                }
            }
        }
        
        print("\n📊 Summary:")
        print("Total videos extracted: \(totalVideos)")
        
        // Save to JSON file
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "tools/brainlift_output/pre-algebra_units_4_15_youtube_\(timestamp).json"
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: allYouTubeURLs, options: .prettyPrinted)
            try jsonData.write(to: URL(fileURLWithPath: filename))
            print("💾 Saved YouTube URLs to: \(filename)")
        } catch {
            print("❌ Error saving file: \(error)")
        }
    }
    
    private func extractYouTubeID(from downloadUrls: [String]) -> String? {
        for url in downloadUrls {
            if url.contains("ka-youtube-converted") {
                let pattern = "ka-youtube-converted/([a-zA-Z0-9_-]{11})\\."
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
                   let range = Range(match.range(at: 1), in: url) {
                    return String(url[range])
                }
            }
        }
        return nil
    }
}

// Main execution
Task {
    let extractor = RemainingYouTubeExtractor()
    await extractor.extractRemainingUnits()
    exit(0)
}

// Keep the script running until Task completes
RunLoop.main.run()