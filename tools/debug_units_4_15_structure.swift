#!/usr/bin/env swift

import Foundation

class StructureDebugger {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    func debugStructure() async {
        print("🔍 Debugging Units 4-15 structure...")
        
        let path = "math/pre-algebra"
        
        if let json = await callContentForPath(path) {
            await debugUnit4Structure(json)
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
    
    private func debugUnit4Structure(_ json: [String: Any]) async {
        guard let data = json["data"] as? [String: Any],
              let contentRoute = data["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let course = listedPathData["course"] as? [String: Any],
              let unitChildren = course["unitChildren"] as? [[String: Any]] else {
            print("❌ Could not navigate to unitChildren")
            return
        }
        
        print("📊 Found \(unitChildren.count) total units")
        
        // Debug Unit 4 (index 3) in detail
        guard unitChildren.count > 3 else {
            print("❌ Unit 4 not found")
            return
        }
        
        let unit4 = unitChildren[3]
        let unitTitle = unit4["translatedTitle"] as? String ?? "Unknown Unit"
        print("\n🔍 Debugging Unit 4: \(unitTitle)")
        
        // Print all keys in unit4
        print("🔑 Unit 4 keys: \(unit4.keys.sorted())")
        
        if let lessons = unit4["allOrderedChildren"] as? [[String: Any]] {
            print("📚 Found \(lessons.count) lessons in Unit 4")
            
            // Debug first lesson in detail
            if let firstLesson = lessons.first {
                let lessonTitle = firstLesson["translatedTitle"] as? String ?? "Unknown"
                let lessonTypename = firstLesson["__typename"] as? String ?? "Unknown"
                
                print("\n🔍 First lesson: '\(lessonTitle)' (type: \(lessonTypename))")
                print("🔑 Lesson keys: \(firstLesson.keys.sorted())")
                
                // Check if it has curatedChildren
                if let curatedChildren = firstLesson["curatedChildren"] as? [[String: Any]] {
                    print("👥 Found \(curatedChildren.count) curated children")
                    
                    // Debug first child
                    if let firstChild = curatedChildren.first {
                        let childTitle = firstChild["translatedTitle"] as? String ?? "Unknown"
                        let childTypename = firstChild["__typename"] as? String ?? "Unknown"
                        
                        print("\n🔍 First child: '\(childTitle)' (type: \(childTypename))")
                        print("🔑 Child keys: \(firstChild.keys.sorted())")
                        
                        // Check for downloadUrls
                        if let downloadUrls = firstChild["downloadUrls"] as? [String] {
                            print("📥 Download URLs found: \(downloadUrls.count)")
                            for (i, url) in downloadUrls.enumerated() {
                                print("  \(i + 1). \(url)")
                                if url.contains("ka-youtube-converted") {
                                    print("    ✅ Contains YouTube pattern!")
                                }
                            }
                        } else {
                            print("❌ No downloadUrls found")
                        }
                    }
                } else {
                    print("❌ No curatedChildren found")
                    
                    // Check for other possible children arrays
                    for key in firstLesson.keys.sorted() {
                        if key.lowercased().contains("child") {
                            print("🔍 Found potential children key: \(key)")
                            if let children = firstLesson[key] as? [[String: Any]] {
                                print("  📊 Contains \(children.count) items")
                            }
                        }
                    }
                }
            }
        } else {
            print("❌ No allOrderedChildren found in Unit 4")
            
            // Check for other possible lesson arrays
            for key in unit4.keys.sorted() {
                if key.lowercased().contains("child") || key.lowercased().contains("lesson") {
                    print("🔍 Found potential lessons key: \(key)")
                    if let children = unit4[key] as? [[String: Any]] {
                        print("  📊 Contains \(children.count) items")
                    }
                }
            }
        }
    }
}

// Main execution
Task {
    let debugger = StructureDebugger()
    await debugger.debugStructure()
    exit(0)
}

// Keep the script running until Task completes
RunLoop.main.run()