#!/usr/bin/env swift

import Foundation

class VideoDetailsDebugger {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    func debugVideoDetails() async {
        print("🔍 Debugging video details for Units 4-15...")
        
        let path = "math/pre-algebra"
        
        if let json = await callContentForPath(path) {
            await debugVideoFields(json)
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
    
    private func debugVideoFields(_ json: [String: Any]) async {
        guard let data = json["data"] as? [String: Any],
              let contentRoute = data["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let course = listedPathData["course"] as? [String: Any],
              let unitChildren = course["unitChildren"] as? [[String: Any]] else {
            print("❌ Could not navigate to unitChildren")
            return
        }
        
        // Check Unit 4 (index 3) first video
        guard unitChildren.count > 3 else {
            print("❌ Unit 4 not found")
            return
        }
        
        let unit4 = unitChildren[3]
        guard let lessons = unit4["allOrderedChildren"] as? [[String: Any]],
              let firstLesson = lessons.first,
              let curatedChildren = firstLesson["curatedChildren"] as? [[String: Any]],
              let firstVideo = curatedChildren.first else {
            print("❌ Could not navigate to first video")
            return
        }
        
        let videoTitle = firstVideo["translatedTitle"] as? String ?? "Unknown"
        print("📹 Debugging video: '\(videoTitle)'")
        
        // Print all fields and their values
        for key in firstVideo.keys.sorted() {
            let value = firstVideo[key]
            print("\n🔑 \(key):")
            
            if let stringValue = value as? String {
                print("  📝 '\(stringValue)'")
                // Check if any fields contain YouTube patterns
                if stringValue.contains("youtube") || stringValue.contains("youtu.be") {
                    print("  ✅ Contains YouTube!")
                }
                if stringValue.contains("ka-youtube-converted") {
                    print("  ✅ Contains ka-youtube-converted!")
                }
            } else if let dictValue = value as? [String: Any] {
                print("  📦 Dictionary with keys: \(dictValue.keys.sorted())")
            } else if let arrayValue = value as? [Any] {
                print("  📋 Array with \(arrayValue.count) items")
            } else {
                print("  📊 \(type(of: value)): \(String(describing: value))")
            }
        }
        
        // Also check a video from Unit 1 for comparison
        print("\n" + String(repeating: "=", count: 50))
        print("🔍 Comparing with Unit 1 video for reference...")
        
        let unit1 = unitChildren[0]
        guard let unit1Lessons = unit1["allOrderedChildren"] as? [[String: Any]],
              let unit1FirstLesson = unit1Lessons.first,
              let unit1CuratedChildren = unit1FirstLesson["curatedChildren"] as? [[String: Any]],
              let unit1FirstVideo = unit1CuratedChildren.first else {
            print("❌ Could not navigate to Unit 1 first video")
            return
        }
        
        let unit1VideoTitle = unit1FirstVideo["translatedTitle"] as? String ?? "Unknown"
        print("📹 Unit 1 video: '\(unit1VideoTitle)'")
        print("🔑 Unit 1 video keys: \(unit1FirstVideo.keys.sorted())")
        
        // Check if Unit 1 has downloadUrls
        if let downloadUrls = unit1FirstVideo["downloadUrls"] as? [String] {
            print("✅ Unit 1 has downloadUrls: \(downloadUrls.count)")
            for url in downloadUrls.prefix(3) {
                print("  - \(url)")
            }
        } else {
            print("❌ Unit 1 also missing downloadUrls")
        }
    }
}

// Main execution
Task {
    let debugger = VideoDetailsDebugger()
    await debugger.debugVideoDetails()
    exit(0)
}

// Keep the script running until Task completes
RunLoop.main.run()