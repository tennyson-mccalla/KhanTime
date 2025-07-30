#!/usr/bin/env swift

import Foundation

// Debug video paths by looking at the curatedChildren from our original GraphQL call
class VideoPathDebugger {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    func debugVideoPaths() async {
        print("🔍 Debugging Khan Academy video paths")
        print("====================================")
        
        // Call the same GraphQL we use for the main structure
        let path = "math/pre-algebra"
        
        if let json = await callContentForPath(path) {
            extractVideoPathsFromResponse(json)
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
    
    private func extractVideoPathsFromResponse(_ json: [String: Any]) {
        guard let data = json["data"] as? [String: Any],
              let contentRoute = data["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let course = listedPathData["course"] as? [String: Any],
              let unitChildren = course["unitChildren"] as? [[String: Any]] else {
            print("❌ Could not navigate to unitChildren")
            return
        }
        
        print("✅ Found \(unitChildren.count) units")
        
        // Look at first unit (Factors and multiples)
        if let firstUnit = unitChildren.first,
           let unitTitle = firstUnit["translatedTitle"] as? String,
           let children = firstUnit["allOrderedChildren"] as? [[String: Any]] {
            
            print("\n📁 Unit: \(unitTitle)")
            
            // Look at first lesson
            if let firstLesson = children.first,
               let lessonTitle = firstLesson["translatedTitle"] as? String,
               let curatedChildren = firstLesson["curatedChildren"] as? [[String: Any]] {
                
                print("  📖 Lesson: \(lessonTitle)")
                
                // Look at video steps in this lesson
                for (index, child) in curatedChildren.enumerated() {
                    let stepTitle = child["translatedTitle"] as? String ?? "Unknown"
                    let stepTypename = child["__typename"] as? String ?? "Unknown"
                    let stepId = child["id"] as? String ?? "Unknown"
                    
                    if stepTypename == "Video" {
                        print("    🎥 Video \(index + 1): \(stepTitle)")
                        print("        ID: \(stepId)")
                        
                        // Look for relativeUrl or other path hints
                        if let relativeUrl = child["relativeUrl"] as? String {
                            print("        Path: \(relativeUrl)")
                            
                            // Try to extract YouTube URL using this path
                            Task {
                                if let youtubeUrl = await self.extractYouTubeFromPath(relativeUrl) {
                                    print("        ✅ YouTube: \(youtubeUrl)")
                                } else {
                                    print("        ❌ Could not extract YouTube URL")
                                }
                            }
                        }
                        
                        // Look for other useful fields
                        for (key, value) in child {
                            if key.lowercased().contains("url") || key.lowercased().contains("path") {
                                print("        \(key): \(value)")
                            }
                        }
                        
                        print("")
                    }
                }
            }
        }
    }
    
    private func extractYouTubeFromPath(_ path: String) async -> String? {
        // Remove leading slash if present
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
let debugger = VideoPathDebugger()

Task {
    await debugger.debugVideoPaths()
    print("\n🎉 Video path debugging complete!")
    exit(0)
}

RunLoop.main.run()