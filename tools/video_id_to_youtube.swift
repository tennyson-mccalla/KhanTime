#!/usr/bin/env swift

import Foundation

// Extract YouTube URLs for specific Khan Academy video IDs
class VideoIdToYouTube {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    // Target video IDs that need YouTube URLs
    private let targetVideoIds = [
        ("56195550", "Common divisibility examples"),
        // Add more IDs from Unit 2 as needed
    ]
    
    func extractYouTubeUrls() async {
        print("🎯 Khan Academy Video ID to YouTube URL Converter")
        print("==============================================")
        
        for (videoId, title) in targetVideoIds {
            print("\n🔍 Processing: \(title) (ID: \(videoId))")
            
            if let youtubeUrl = await getYouTubeUrlForVideoId(videoId) {
                print("✅ Found YouTube URL: \(youtubeUrl)")
                print("   Add to scraper mapping:")
                print("   if titleLower.contains(\"\(title.lowercased())\") {")
                print("       return \"\(youtubeUrl)\"")
                print("   }")
            } else {
                print("❌ Could not find YouTube URL for video ID: \(videoId)")
            }
            
            // Rate limiting
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        }
    }
    
    private func getYouTubeUrlForVideoId(_ videoId: String) async -> String? {
        // Strategy 1: Use Khan Academy's ContentForPath API (similar to original scraper)
        if let youtubeUrl = await extractUsingContentForPath(videoId) {
            return youtubeUrl
        }
        
        // Strategy 2: Try direct video page access
        if let youtubeUrl = await extractFromVideoPage(videoId) {
            return youtubeUrl
        }
        
        return nil
    }
    
    private func extractUsingContentForPath(_ videoId: String) async -> String? {
        // Try to construct a video path and use ContentForPath API
        let possiblePaths = [
            "math/pre-algebra/v/\(videoId)",
            "v/\(videoId)",
            "math/pre-algebra/pre-algebra-factors-multiples/v/\(videoId)"
        ]
        
        for path in possiblePaths {
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
                return nil
            }
            
            print("      📡 GraphQL response for path: \(path)")
            
            // Try to extract YouTube URL from the response
            return extractYouTubeFromGraphQLResponse(json)
            
        } catch {
            print("      ❌ GraphQL error for path \(path): \(error)")
            return nil
        }
    }
    
    private func extractYouTubeFromGraphQLResponse(_ json: [String: Any]) -> String? {
        // Navigate the GraphQL response to find video data
        // This is based on the pattern from the original scraper
        
        if let data = json["data"] as? [String: Any],
           let contentRoute = data["contentRoute"] as? [String: Any],
           let listedPathData = contentRoute["listedPathData"] as? [String: Any],
           let content = listedPathData["content"] as? [String: Any] {
            
            // Check if this is a video content
            if let contentKind = content["contentKind"] as? String,
               contentKind == "Video" {
                
                // Look for download URLs with YouTube IDs
                if let downloadUrls = content["downloadUrls"] as? [String: Any],
                   let mp4Url = downloadUrls["mp4"] as? String {
                    
                    // Extract YouTube ID from ka-youtube-converted path
                    let youtubeIdPattern = "ka-youtube-converted/([a-zA-Z0-9_-]{11})\\."
                    
                    if let regex = try? NSRegularExpression(pattern: youtubeIdPattern, options: []) {
                        let range = NSRange(mp4Url.startIndex..<mp4Url.endIndex, in: mp4Url)
                        if let match = regex.firstMatch(in: mp4Url, options: [], range: range) {
                            let youtubeIdRange = Range(match.range(at: 1), in: mp4Url)!
                            let youtubeId = String(mp4Url[youtubeIdRange])
                            
                            print("      🎯 Extracted YouTube ID from GraphQL: \(youtubeId)")
                            return "https://www.youtube.com/embed/\(youtubeId)"
                        }
                    }
                }
                
                // Look for other video URL fields
                if let videoUrl = content["videoUrl"] as? String,
                   videoUrl.contains("youtube") {
                    return videoUrl
                }
            }
        }
        
        return nil
    }
    
    private func extractFromVideoPage(_ videoId: String) async -> String? {
        // Try accessing the video directly by ID
        let videoUrl = "\(baseURL)/v/\(videoId)"
        
        do {
            let (data, response) = try await session.data(from: URL(string: videoUrl)!)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let html = String(data: data, encoding: .utf8) else {
                return nil
            }
            
            print("      📄 Checking video page: \(videoUrl)")
            
            // Use same HTML extraction as before
            return extractYouTubeIdFromHtml(html)
            
        } catch {
            print("      ❌ Error accessing video page: \(error)")
            return nil
        }
    }
    
    private func extractYouTubeIdFromHtml(_ html: String) -> String? {
        let patterns = [
            "data-youtubeid=\"([a-zA-Z0-9_-]{11})\"",
            "https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
            "\"youTubeId\"\\s*:\\s*\"([a-zA-Z0-9_-]{11})\"",
            "\"videoId\"\\s*:\\s*\"([a-zA-Z0-9_-]{11})\""
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range),
                   match.numberOfRanges > 1 {
                    let videoIdRange = Range(match.range(at: 1), in: html)!
                    let videoId = String(html[videoIdRange])
                    
                    if videoId.count == 11 {
                        print("      🎯 Found YouTube ID from HTML: \(videoId)")
                        return "https://www.youtube.com/embed/\(videoId)"
                    }
                }
            }
        }
        
        return nil
    }
}

// Main execution
let converter = VideoIdToYouTube()

Task {
    await converter.extractYouTubeUrls()
    print("\n🎉 Video ID to YouTube URL conversion complete!")
    exit(0)
}

RunLoop.main.run()