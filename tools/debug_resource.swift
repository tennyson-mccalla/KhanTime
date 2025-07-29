#!/usr/bin/env swift

import Foundation

// Debug script to test simple resource creation
let apiBaseURL = "https://api.staging.alpha-1edtech.com"
let authBaseURL = "https://alpha-auth-development-idp.auth.us-west-2.amazoncognito.com"
let khanCourseId = "khan-pre-algebra-1753750080"

// Function to get auth token (same as before)
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

// Try a very simple resource creation
func createSimpleResource(token: String) throws {
    let url = URL(string: "\(apiBaseURL)/ims/oneroster/resources/v1p2/resources")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let timestamp = Int(Date().timeIntervalSince1970)
    let resourceId = "debug-resource-\(timestamp)"
    
    let payload = [
        "resource": [
            "sourcedId": resourceId,
            "status": "active",
            "title": "Test Khan Academy Lesson",
            "vendorResourceId": "khan-test-1",
            "metadata": [
                "type": "qti",
                "subType": "qti-test",
                "format": "application/xml",
                "url": "https://qti.alpha-1edtech.com/api/assessment-tests/test-67aa14ec-3-PP.1"
            ]
        ]
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: payload)
    request.httpBody = jsonData
    
    // Print the payload for debugging
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("📤 Sending payload:")
        print(jsonString)
    }
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        result = (data, response, error)
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    if let error = result.2 { throw error }
    
    guard let httpResponse = result.1 as? HTTPURLResponse else {
        throw NSError(domain: "ResourceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
    }
    
    print("📥 Response status: \(httpResponse.statusCode)")
    
    if let data = result.0, let responseString = String(data: data, encoding: .utf8) {
        print("📥 Response body: \(responseString)")
    }
    
    guard (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "ResourceError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create resource"])
    }
    
    print("✅ Successfully created test resource: \(resourceId)")
}

// Main execution
do {
    print("🚀 Testing simple resource creation...")
    
    let token = try getAuthToken()
    print("✅ Got auth token")
    
    try createSimpleResource(token: token)
    
    print("🎉 SUCCESS!")
    
} catch {
    print("❌ FAILED: \(error)")
}