#!/usr/bin/env swift

import Foundation

class WorkingUnits4to15Extractor {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    func extractUnits4to15YouTube() async {
        print("🎯 Extracting YouTube URLs for Units 4-15 using individual video path method")
        print("========================================================================")
        
        let path = "math/pre-algebra"
        
        if let json = await callContentForPath(path) {
            await extractVideosFromUnits4to15(json)
        }
    }
    
    private func extractVideosFromUnits4to15(_ json: [String: Any]) async {
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
        var successfulExtractions = 0
        
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
                    
                    print("  📖 \(lessonTitle)")
                    
                    for child in curatedChildren {
                        let stepTitle = child["translatedTitle"] as? String ?? "Unknown"
                        let stepTypename = child["__typename"] as? String ?? "Unknown"
                        
                        if stepTypename == "Video" {
                            totalVideos += 1
                            print("    🎥 \(stepTitle)")
                            
                            if let videoPath = child["urlWithinCurationNode"] as? String {
                                if let youtubeUrl = await extractYouTubeFromPath(videoPath) {
                                    successfulExtractions += 1
                                    allYouTubeURLs[stepTitle] = youtubeUrl
                                    
                                    if let youtubePart = youtubeUrl.components(separatedBy: "/embed/").last {
                                        let youtubeId = youtubePart.components(separatedBy: "?").first ?? youtubePart
                                        print("      ✅ \(youtubeId)")
                                    }
                                } else {
                                    print("      ❌ Failed to extract YouTube URL")
                                }
                                
                                // 1 second delay for rate limiting
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                            }
                        }
                    }
                }
            }
        }
        
        print("\n📊 EXTRACTION SUMMARY:")
        print("=====================")
        print("Units processed: \(15 - 3) (Units 4-15)")
        print("Total videos found: \(totalVideos)")
        print("Successful extractions: \(successfulExtractions)")
        print("Success rate: \(successfulExtractions > 0 ? (successfulExtractions * 100 / totalVideos) : 0)%")
        
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
        
        print("\n🎯 Next steps:")
        print("1. Update final_scraper.swift with these YouTube mappings")
        print("2. Generate complete 15-unit dataset")
        print("3. Test in iPad app")
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
    
    private func extractYouTubeFromPath(_ path: String) async -> String? {
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
            request.timeoutInterval = 30.0
            
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
Task {
    let extractor = WorkingUnits4to15Extractor()
    await extractor.extractUnits4to15YouTube()
    exit(0)
}

RunLoop.main.run()