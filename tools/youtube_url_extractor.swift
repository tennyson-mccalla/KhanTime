#!/usr/bin/env swift

import Foundation

// Targeted YouTube URL extractor for specific Khan Academy videos
class YouTubeUrlExtractor {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    // Target video titles to extract URLs for
    private let targetVideos = [
        // Unit 1 - Missing
        "Common divisibility examples",
        
        // Unit 2 - All missing
        "Factors and multiples: days of the week",
        "Math patterns: table", 
        "Math patterns: toothpicks",
        "Constructing numerical expressions",
        "Evaluating expressions with & without parentheses",
        "Translating expressions with parentheses",
        "Graphing patterns on coordinate plane",
        "Interpreting patterns on coordinate plane", 
        "Interpreting relationships in ordered pairs",
        "Graphing sequence relationships"
    ]
    
    func extractYouTubeUrls() async {
        print("🎯 YouTube URL Extractor for Khan Academy")
        print("========================================")
        
        for videoTitle in targetVideos {
            print("\n🔍 Searching for: \(videoTitle)")
            
            if let youtubeUrl = await extractYouTubeUrl(for: videoTitle) {
                print("✅ Found: \(youtubeUrl)")
                print("   Add to scraper: if titleLower.contains(\"\(videoTitle.lowercased())\") {")
                print("       return \"\(youtubeUrl)\"")
                print("   }")
            } else {
                print("❌ Could not find YouTube URL for: \(videoTitle)")
            }
            
            // Rate limiting
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
    }
    
    private func extractYouTubeUrl(for videoTitle: String) async -> String? {
        // Strategy 1: Try Khan Academy search
        if let searchUrl = await searchKhanAcademy(for: videoTitle) {
            if let youtubeUrl = await extractFromKhanPage(searchUrl) {
                return youtubeUrl
            }
        }
        
        // Strategy 2: Try direct URL construction
        if let directUrl = constructDirectUrl(for: videoTitle) {
            if let youtubeUrl = await extractFromKhanPage(directUrl) {
                return youtubeUrl
            }
        }
        
        return nil
    }
    
    private func searchKhanAcademy(for videoTitle: String) async -> String? {
        // Khan Academy search is complex, for now try direct construction
        return nil
    }
    
    private func constructDirectUrl(for videoTitle: String) -> String? {
        // Try to construct Khan Academy URLs based on title patterns
        let slug = videoTitle
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "&", with: "and")
        
        // Common Khan Academy URL patterns
        let possibleUrls = [
            "\(baseURL)/math/pre-algebra/pre-algebra-factors-multiples/v/\(slug)",
            "\(baseURL)/math/pre-algebra/patterns/v/\(slug)",
            "\(baseURL)/math/pre-algebra/pre-algebra-patterns/v/\(slug)",
            "\(baseURL)/v/\(slug)"
        ]
        
        return possibleUrls.first // For now, return first one to test
    }
    
    private func extractFromKhanPage(_ urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let html = String(data: data, encoding: .utf8) else {
                return nil
            }
            
            print("      📄 Checking page: \(urlString)")
            
            // Use the same extraction methods from the original scraper
            return extractYouTubeIdFromHtml(html)
            
        } catch {
            print("      ❌ Error fetching \(urlString): \(error)")
            return nil
        }
    }
    
    private func extractYouTubeIdFromHtml(_ html: String) -> String? {
        // Khan Academy iframe patterns
        let patterns = [
            // iframe with data-youtubeid attribute
            "data-youtubeid=\"([a-zA-Z0-9_-]{11})\"",
            // youtube-nocookie.com URLs
            "https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
            "src=\"https://www\\.youtube-nocookie\\.com/embed/([a-zA-Z0-9_-]{11})",
            // JSON embedded data
            "\"youTubeId\"\\s*:\\s*\"([a-zA-Z0-9_-]{11})\"",
            "\"videoId\"\\s*:\\s*\"([a-zA-Z0-9_-]{11})\"",
            // Standard YouTube URLs
            "https://www\\.youtube\\.com/embed/([a-zA-Z0-9_-]{11})"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range),
                   match.numberOfRanges > 1 {
                    let videoIdRange = Range(match.range(at: 1), in: html)!
                    let videoId = String(html[videoIdRange])
                    
                    // Validate YouTube ID format
                    if videoId.count == 11 {
                        print("      🎯 Found YouTube ID: \(videoId)")
                        return "https://www.youtube.com/embed/\(videoId)"
                    }
                }
            }
        }
        
        return nil
    }
}

// Main execution
let extractor = YouTubeUrlExtractor()

Task {
    await extractor.extractYouTubeUrls()
    print("\n🎉 YouTube URL extraction complete!")
    exit(0)
}

RunLoop.main.run()