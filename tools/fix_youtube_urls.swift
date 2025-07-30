#!/usr/bin/env swift

import Foundation

// Fix YouTube URLs using proper GraphQL ContentForPath method
class YouTubeUrlFixer {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    // Videos that need fixing (first few that are broken)
    private let videosToFix = [
        ("x6cf07b5dab8b8803", "Reasoning about factors and multiples", "factors-mult"),
        ("2600703", "Finding factors of a number", "factors"),
        ("GvTcpfSnOMQ", "Prime numbers", "prime-numbers") // This one might be wrong ID
    ]
    
    func fixYouTubeUrls() async {
        print("🔧 Fixing YouTube URLs using GraphQL ContentForPath")
        print("================================================")
        
        for (videoId, title, slug) in videosToFix {
            print("\n🎯 Fixing: \(title)")
            print("   Video ID: \(videoId)")
            
            if let youtubeUrl = await getCorrectYouTubeUrl(videoId: videoId, slug: slug) {
                print("✅ Correct URL: \(youtubeUrl)")
                
                // Extract YouTube ID for mapping
                if let youtubePart = youtubeUrl.components(separatedBy: "/embed/").last {
                    let youtubeId = youtubePart.components(separatedBy: "?").first ?? youtubePart
                    print("   Update mapping:")
                    print("   if titleLower.contains(\"\(title.lowercased())\") {")
                    print("       return \"https://www.youtube.com/embed/\(youtubeId)\"")
                    print("   }")
                }
            } else {
                print("❌ Could not extract YouTube URL for: \(title)")
            }
            
            // Rate limiting
            try? await Task.sleep(nanoseconds: 3_000_000_000)
        }
    }
    
    private func getCorrectYouTubeUrl(videoId: String, slug: String) async -> String? {
        // Try different path patterns for the video
        let possiblePaths = [
            "math/pre-algebra/pre-algebra-factors-multiples/v/\(slug)",
            "math/pre-algebra/pre-algebra-factors-multiples/\(slug)/v/\(videoId)", 
            "v/\(slug)",
            "math/pre-algebra/v/\(slug)"
        ]
        
        for path in possiblePaths {
            print("   🔍 Trying path: \(path)")
            
            if let youtubeUrl = await callContentForPath(path) {
                return youtubeUrl
            }
        }
        
        return nil
    }
    
    private func callContentForPath(_ path: String) async -> String? {
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
                print("     ❌ GraphQL request failed for \(path)")
                return nil
            }
            
            return extractYouTubeFromGraphQL(json)
            
        } catch {
            print("     ❌ Error calling GraphQL for \(path): \(error)")
            return nil
        }
    }
    
    private func extractYouTubeFromGraphQL(_ json: [String: Any]) -> String? {
        // Navigate GraphQL response structure
        guard let data = json["data"] as? [String: Any],
              let contentRoute = data["contentRoute"] as? [String: Any],
              let listedPathData = contentRoute["listedPathData"] as? [String: Any],
              let content = listedPathData["content"] as? [String: Any] else {
            print("     ❌ Could not navigate GraphQL response structure")
            return nil
        }
        
        // Check if this is video content
        if let contentKind = content["contentKind"] as? String,
           contentKind == "Video" {
            
            // Method 1: Extract from downloadUrls (original working method)
            if let downloadUrlsString = content["downloadUrls"] as? String {
                print("     🔍 Found downloadUrls string")
                
                if let downloadUrlsData = downloadUrlsString.data(using: .utf8),
                   let downloadUrls = try? JSONSerialization.jsonObject(with: downloadUrlsData) as? [String: Any],
                   let mp4Url = downloadUrls["mp4"] as? String {
                    
                    print("     🔍 MP4 URL: \(mp4Url.prefix(100))...")
                    
                    // Extract YouTube ID from ka-youtube-converted pattern
                    let youtubeIdPattern = "ka-youtube-converted/([a-zA-Z0-9_-]{11})\\."
                    
                    if let regex = try? NSRegularExpression(pattern: youtubeIdPattern, options: []) {
                        let range = NSRange(mp4Url.startIndex..<mp4Url.endIndex, in: mp4Url)
                        if let match = regex.firstMatch(in: mp4Url, options: [], range: range),
                           match.numberOfRanges > 1 {
                            let youtubeIdRange = Range(match.range(at: 1), in: mp4Url)!
                            let youtubeId = String(mp4Url[youtubeIdRange])
                            
                            print("     🎯 Extracted YouTube ID: \(youtubeId)")
                            return "https://www.youtube.com/embed/\(youtubeId)"
                        }
                    }
                }
            }
            
            // Method 2: Check for direct videoUrl fields
            if let videoUrl = content["videoUrl"] as? String,
               videoUrl.contains("youtube") {
                print("     🎯 Found direct videoUrl: \(videoUrl)")
                return videoUrl
            }
        }
        
        print("     ❌ No YouTube URL found in GraphQL response")
        return nil
    }
}

// Main execution
let fixer = YouTubeUrlFixer()

Task {
    await fixer.fixYouTubeUrls()
    print("\n🎉 YouTube URL fixing complete!")
    exit(0)
}

RunLoop.main.run()