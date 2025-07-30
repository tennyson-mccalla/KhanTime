#!/usr/bin/env swift

import Foundation

// Debug the structure of video objects in Unit 1 to see what fields are available
class Unit1VideoStructureDebugger {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    func debugVideoStructure() async {
        print("🔍 Debugging Unit 1 video object structure")
        print("==========================================")
        
        let path = "math/pre-algebra"
        
        if let json = await callContentForPath(path) {
            debugFirstVideoObject(json)
        }
    }
    
    private func debugFirstVideoObject(_ json: [String: Any]) {
        guard let data = json["data"] as? [String: Any],
              let contentRoute = data["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let course = listedPathData["course"] as? [String: Any],
              let unitChildren = course["unitChildren"] as? [[String: Any]] else {
            print("❌ Could not navigate to unitChildren")
            return
        }
        
        // Get first unit
        guard let firstUnit = unitChildren.first,
              let unitTitle = firstUnit["translatedTitle"] as? String,
              let lessons = firstUnit["allOrderedChildren"] as? [[String: Any]] else {
            print("❌ Could not find Unit 1")
            return
        }
        
        print("📁 Unit 1: \(unitTitle)")
        
        // Find first lesson with videos
        for lesson in lessons {
            let lessonTitle = lesson["translatedTitle"] as? String ?? "Unknown"
            let lessonTypename = lesson["__typename"] as? String ?? "Unknown"
            
            if lessonTypename == "Lesson",
               let curatedChildren = lesson["curatedChildren"] as? [[String: Any]] {
                
                print("\n📖 Lesson: \(lessonTitle)")
                
                // Find first video and dump all its fields
                for child in curatedChildren {
                    let stepTypename = child["__typename"] as? String ?? "Unknown"
                    
                    if stepTypename == "Video" {
                        let stepTitle = child["translatedTitle"] as? String ?? "Unknown"
                        print("\n🎥 First Video: \(stepTitle)")
                        print("All available fields:")
                        
                        for (key, value) in child.sorted(by: { $0.key < $1.key }) {
                            print("  \(key): \(value)")
                        }
                        
                        return // Just show the first video
                    }
                }
            }
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
let debugger = Unit1VideoStructureDebugger()

Task {
    await debugger.debugVideoStructure()
    print("\n🎉 Video structure debugging complete!")
    exit(0)
}

RunLoop.main.run()