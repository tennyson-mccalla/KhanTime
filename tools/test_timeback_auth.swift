#!/usr/bin/swift

import Foundation

// Quick test of TimeBack authentication
struct AuthTest {
    let authBaseURL = "https://alpha-auth-development-idp.auth.us-west-2.amazoncognito.com"
    let clientID = "3ab5g0ak4fshvlaccu0s9f75g"
    let clientSecret = "ukrk6q99c62hic32pv6jb2afjq5kdddafku0s64a6m70vjlnnh"
    
    func test() async {
        print("🔐 Testing TimeBack authentication...")
        
        let endpoint = "/oauth2/token"
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret)
        ]
        
        let body = components.query?.data(using: .utf8)
        
        guard let url = URL(string: authBaseURL + endpoint) else {
            print("❌ Invalid URL")
            return
        }
        
        print("📡 Requesting: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 10 // 10 second timeout
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status: \(httpResponse.statusCode)")
                
                if (200...299).contains(httpResponse.statusCode) {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("✅ Auth successful!")
                        print("Response keys: \(json.keys)")
                        
                        if let accessToken = json["access_token"] as? String {
                            print("🎫 Got access token (length: \(accessToken.count))")
                        }
                    }
                } else {
                    print("❌ Auth failed")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("Error response: \(errorString)")
                    }
                }
            }
        } catch {
            print("❌ Network error: \(error)")
        }
    }
}

Task {
    let test = AuthTest()
    await test.test()
    print("✅ Test complete")
}