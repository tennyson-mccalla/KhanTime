#!/usr/bin/env swift

import Foundation

struct GraphQLRequest: Codable {
    let query: String
    let variables: [String: String]
}

struct GraphQLResponse: Codable {
    let data: ContentData?
}

struct ContentData: Codable {
    let contentByPath: ContentByPath?
}

struct ContentByPath: Codable {
    let children: [Child]?
}

struct Child: Codable {
    let relativeUrl: String?
    let translatedTitle: String?
    let children: [Child]?
    let downloadUrls: [String]?
}

func extractYouTubeID(from downloadUrls: [String]) -> String? {
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

let units = [
    ("arithmetic/arith-decimals", "Unit 4: Arithmetic with decimals"),
    ("arithmetic/arith-fractions", "Unit 5: Arithmetic with fractions"),
    ("algebra-basics/alg-negative-numbers", "Unit 6: Negative numbers"),
    ("algebra-basics/alg-variables-and-expressions", "Unit 7: Variables & expressions"),
    ("algebra-basics/alg-linear-equations-and-inequalities", "Unit 8: Equations & inequalities introduction"),
    ("algebra-basics/alg-working-with-units", "Unit 9: Working with units"),
    ("algebra-basics/alg-linear-equations-and-inequalities-two-variables", "Unit 10: Linear equations & graphs"),
    ("algebra-basics/alg-systems-of-equations", "Unit 11: Systems of equations"),
    ("geometry-basics/basic-geo-area-and-perimeter", "Unit 12: Geometry basics"),
    ("geometry-basics/basic-geo-volume-and-surface-area", "Unit 13: Area and perimeter"),
    ("algebra-basics/alg-pythagorean-theorem", "Unit 14: Volume and surface area"),
    ("basic-statistics-probability/basic-stats-and-probability", "Unit 15: Pythagorean theorem")
]

var allYouTubeURLs: [String: String] = [:]

func makeGraphQLRequest(for unitPath: String) async throws -> GraphQLResponse? {
    let url = URL(string: "https://www.khanacademy.org/api/internal/graphql/ContentForPath")!
    
    let query = """
    query ContentForPath($path: String!) {
        contentByPath(path: $path) {
            ... on Topic {
                children {
                    relativeUrl
                    translatedTitle
                    children {
                        relativeUrl
                        translatedTitle
                        children {
                            relativeUrl
                            translatedTitle
                            ... on Video {
                                downloadUrls
                            }
                        }
                    }
                }
            }
        }
    }
    """
    
    let requestBody = GraphQLRequest(query: query, variables: ["path": unitPath])
    let jsonData = try JSONEncoder().encode(requestBody)
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(GraphQLResponse.self, from: data)
}

func processUnit(unitPath: String, unitTitle: String) async {
    print("Processing \(unitTitle)...")
    
    do {
        guard let response = try await makeGraphQLRequest(for: unitPath),
              let children = response.data?.contentByPath?.children else {
            print("❌ No data for \(unitTitle)")
            return
        }
        
        var videoCount = 0
        
        for lesson in children {
            guard let _ = lesson.translatedTitle,
                  let lessonChildren = lesson.children else { continue }
            
            for step in lessonChildren {
                if let downloadUrls = step.downloadUrls,
                   let youtubeID = extractYouTubeID(from: downloadUrls),
                   let stepTitle = step.translatedTitle {
                    
                    let videoURL = "https://www.youtube.com/embed/\(youtubeID)"
                    allYouTubeURLs[stepTitle] = videoURL
                    videoCount += 1
                    print("  ✅ \(stepTitle) -> \(youtubeID)")
                }
            }
        }
        
        print("✅ \(unitTitle): \(videoCount) videos extracted")
        
    } catch {
        print("❌ Error processing \(unitTitle): \(error)")
    }
    
    // Rate limiting
    try? await Task.sleep(nanoseconds: 2_000_000_000)
}

// Main execution
Task {
        print("🚀 Starting YouTube URL extraction for Units 4-15...")
        
        for (unitPath, unitTitle) in units {
            await processUnit(unitPath: unitPath, unitTitle: unitTitle)
        }
        
        print("\n📊 Summary:")
        print("Total videos extracted: \(allYouTubeURLs.count)")
        
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

// Keep the script running until Task completes
RunLoop.main.run()