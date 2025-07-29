#!/usr/bin/env swift

import Foundation

// Quick debug of what the OneRoster API is actually returning
let apiBaseURL = "https://api.alpha-1edtech.com"
let authBaseURL = "https://alpha-auth-development-idp.auth.us-west-2.amazoncognito.com"
let khanCourseId = "khan-pre-algebra-1753750080"

// Function to get auth token
func getAuthToken() throws -> String {
    let url = URL(string: "\(authBaseURL)/oauth2/token")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    let credentials = "client_id=3ab5g0ak4fshvlaccu0s9f75g&client_secret=ukrk6q99c62hic32pv6jb2afjq5kdddafku0s64a6m70vjlnnh&grant_type=client_credentials"
    request.httpBody = credentials.data(using: .utf8)
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        result = (data, response, error)
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    if let error = result.2 { throw error }
    
    guard let data = result.0,
          let httpResponse = result.1 as? HTTPURLResponse,
          httpResponse.statusCode == 200,
          let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let accessToken = jsonResponse["access_token"] as? String else {
        throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get token"])
    }
    
    return accessToken
}

// Main execution
do {
    print("🔍 Debugging OneRoster direct access...")
    
    let token = try getAuthToken()
    print("✅ Got auth token")
    
    // Test the exact URL we're using in the app
    let componentsUrl = URL(string: "\(apiBaseURL)/ims/oneroster/rostering/v1p2/courses/\(khanCourseId)/components")!
    var componentsRequest = URLRequest(url: componentsUrl)
    componentsRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    print("📡 Fetching: \(componentsUrl)")
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: componentsRequest) { data, response, error in
        result = (data, response, error)
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    if let error = result.2 {
        print("❌ Network error: \(error)")
        exit(1)
    }
    
    guard let data = result.0,
          let httpResponse = result.1 as? HTTPURLResponse else {
        print("❌ No response data")
        exit(1)
    }
    
    print("📊 Status code: \(httpResponse.statusCode)")
    
    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
    print("📄 Response (first 500 chars):")
    print(responseString.prefix(500))
    
    if httpResponse.statusCode == 200 {
        print("✅ SUCCESS - This should work in the app")
    } else {
        print("❌ HTTP error - this explains the app failure")
    }
    
} catch {
    print("❌ FAILED: \(error)")
}