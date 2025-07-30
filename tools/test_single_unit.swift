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

func makeGraphQLRequest(for unitPath: String) -> GraphQLResponse? {
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
    
    do {
        let jsonData = try JSONEncoder().encode(requestBody)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: GraphQLResponse?
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("❌ Request error: \(error)")
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                return
            }
            
            do {
                result = try JSONDecoder().decode(GraphQLResponse.self, from: data)
            } catch {
                print("❌ Decode error: \(error)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            }
        }.resume()
        
        semaphore.wait()
        return result
        
    } catch {
        print("❌ Error: \(error)")
        return nil
    }
}

print("🧪 Testing single unit extraction...")
print("Testing: arithmetic/arith-decimals")

guard let response = makeGraphQLRequest(for: "arithmetic/arith-decimals"),
      let children = response.data?.contentByPath?.children else {
    print("❌ No data received")
    exit(1)
}

print("✅ Received data with \(children.count) lessons")

var videoCount = 0
var youtubeURLs: [String: String] = [:]

for lesson in children {
    guard let lessonTitle = lesson.translatedTitle,
          let lessonChildren = lesson.children else { continue }
    
    print("📚 Processing lesson: \(lessonTitle)")
    
    for step in lessonChildren {
        if let downloadUrls = step.downloadUrls,
           let youtubeID = extractYouTubeID(from: downloadUrls),
           let stepTitle = step.translatedTitle {
            
            let videoURL = "https://www.youtube.com/embed/\(youtubeID)"
            youtubeURLs[stepTitle] = videoURL
            videoCount += 1
            print("  ✅ \(stepTitle) -> \(youtubeID)")
        }
    }
}

print("\n📊 Summary:")
print("Total videos found: \(videoCount)")

if videoCount > 0 {
    print("✅ Single unit test successful! Proceeding with all units...")
} else {
    print("❌ No videos found - check the GraphQL structure")
}