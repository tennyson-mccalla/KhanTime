#!/usr/bin/env swift

import Foundation

// MARK: - Khan Academy Content API Explorer
// Finding the real APIs that deliver video URLs and Perseus exercise content

print("🔍 Khan Academy Content API Explorer")
print("====================================")

class KhanContentAPIExplorer {
    private let session = URLSession.shared
    private let baseURL = "https://www.khanacademy.org"
    
    private var commonHeaders: [String: String] {
        return [
            "Accept": "*/*",
            "Sec-Fetch-Site": "same-origin",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept-Encoding": "gzip, deflate, br",
            "Sec-Fetch-Mode": "cors",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15",
            "Sec-Fetch-Dest": "empty",
            "x-ka-fkey": "1",
            "Priority": "u=3, i"
        ]
    }
    
    func exploreContentAPIs() async {
        print("\n🎯 Testing individual lesson content APIs...")
        
        // Test specific lesson content API patterns
        let testTargets = [
            "factors-and-multiples",
            "pre-algebra-factors-mult",
            "xa9d6fdff", // Unit ID from our scraped data
            "x88b53972"  // Lesson ID from our scraped data
        ]
        
        for target in testTargets {
            print("\n📡 Testing target: \(target)")
            await testContentAPI(target: target)
            await testVideoAPI(target: target)
            await testExerciseAPI(target: target)
        }
        
        print("\n🎯 Testing Perseus exercise APIs...")
        await testPerseusAPI()
    }
    
    private func testContentAPI(target: String) async {
        let apiPatterns = [
            "/api/internal/graphql/ContentForPath",
            "/api/internal/graphql/LessonPageQuery",
            "/api/internal/graphql/VideoContent",
            "/api/internal/content/\(target)",
            "/api/internal/lesson/\(target)"
        ]
        
        for pattern in apiPatterns {
            do {
                let url = URL(string: "\(baseURL)\(pattern)")!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                for (key, value) in commonHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }
                
                let (data, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("    \(pattern): HTTP \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        if let responseString = String(data: data, encoding: .utf8) {
                            if responseString.contains("video") || responseString.contains("youtube") {
                                print("      ✅ Contains video content!")
                                print("      Preview: \(responseString.prefix(200))...")
                            }
                        }
                    }
                }
            } catch {
                print("    \(pattern): Error - \(error.localizedDescription)")
            }
        }
    }
    
    private func testVideoAPI(target: String) async {
        let videoAPIs = [
            "/api/internal/videos/\(target)",
            "/api/internal/graphql/VideoDataQuery",
            "/video/\(target).json",
            "/content/video/\(target)"
        ]
        
        for api in videoAPIs {
            do {
                let url = URL(string: "\(baseURL)\(api)")!
                var request = URLRequest(url: url)
                
                for (key, value) in commonHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }
                
                let (data, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("    Video API \(api): HTTP \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("      ✅ Video API success!")
                            print("      Preview: \(responseString.prefix(300))...")
                        }
                    }
                }
            } catch {
                print("    Video API \(api): Error")
            }
        }
    }
    
    private func testExerciseAPI(target: String) async {
        let exerciseAPIs = [
            "/api/internal/exercises/\(target)",
            "/api/internal/graphql/ExerciseContent",
            "/exercise/\(target).json",
            "/api/internal/perseus/\(target)"
        ]
        
        for api in exerciseAPIs {
            do {
                let url = URL(string: "\(baseURL)\(api)")!
                var request = URLRequest(url: url)
                
                for (key, value) in commonHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }
                
                let (data, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("    Exercise API \(api): HTTP \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        if let responseString = String(data: data, encoding: .utf8) {
                            if responseString.contains("perseus") || responseString.contains("question") {
                                print("      ✅ Contains exercise content!")
                                print("      Preview: \(responseString.prefix(200))...")
                            }
                        }
                    }
                }
            } catch {
                print("    Exercise API \(api): Error")
            }
        }
    }
    
    private func testPerseusAPI() async {
        // Test Perseus exercise system
        let perseusTests = [
            "/api/internal/graphql/Perseus",
            "/api/internal/perseus/exercise",
            "/api/internal/exercises/factors_and_multiples",
            "/api/internal/exercises/prime_factorization_factors_and_multiples"
        ]
        
        for test in perseusTests {
            do {
                let url = URL(string: "\(baseURL)\(test)")!
                var request = URLRequest(url: url)
                
                for (key, value) in commonHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }
                
                let (data, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("    Perseus \(test): HTTP \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        print("      ✅ Perseus API accessible!")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("      Preview: \(responseString.prefix(300))...")
                        }
                    }
                }
            } catch {
                print("    Perseus \(test): Error")
            }
        }
    }
}

let explorer = KhanContentAPIExplorer()
await explorer.exploreContentAPIs()

print("\n🎉 API exploration complete!")
print("💡 This helps identify the actual content delivery APIs")