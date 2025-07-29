#!/usr/bin/env swift

import Foundation

// Debug script to check component-resource associations
let apiBaseURL = "https://api.staging.alpha-1edtech.com"
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

// Function to check component-resources
func checkComponentResources(token: String) throws {
    // Check all component-resources
    let url = URL(string: "\(apiBaseURL)/ims/oneroster/rostering/v1p2/courses/component-resources")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        result = (data, response, error)
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    if let error = result.2 { throw error }
    
    guard let data = result.0,
          let httpResponse = result.1 as? HTTPURLResponse else {
        throw NSError(domain: "CheckError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response"])
    }
    
    print("📊 Component-resources fetch status: \(httpResponse.statusCode)")
    
    if let responseString = String(data: data, encoding: .utf8) {
        print("📄 Response: \(responseString)")
    }
    
    if httpResponse.statusCode == 200 {
        let response = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        if let componentResources = response["componentResources"] as? [[String: Any]] {
            print("✅ Found \(componentResources.count) component-resources")
            
            let khanAssociations = componentResources.filter { resource in
                if let courseComponent = resource["courseComponent"] as? [String: Any],
                   let sourcedId = courseComponent["sourcedId"] as? String {
                    return sourcedId.contains("khan-unit")
                }
                return false
            }
            
            print("🎯 Khan Academy associations: \(khanAssociations.count)")
            
            for association in khanAssociations {
                let title = association["title"] as? String ?? "Unknown"
                let sourcedId = association["sourcedId"] as? String ?? "Unknown"
                if let courseComponent = association["courseComponent"] as? [String: Any],
                   let unitId = courseComponent["sourcedId"] as? String {
                    print("  - \(title) (ID: \(sourcedId)) -> Unit: \(unitId)")
                }
            }
        } else {
            print("⚠️ No componentResources in response")
        }
    }
}

// Function to check resources
func checkResources(token: String) throws {
    let url = URL(string: "\(apiBaseURL)/ims/oneroster/resources/v1p2/resources")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        result = (data, response, error)
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    if let error = result.2 { throw error }
    
    guard let data = result.0,
          let httpResponse = result.1 as? HTTPURLResponse else {
        throw NSError(domain: "CheckError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response"])
    }
    
    print("📊 Resources fetch status: \(httpResponse.statusCode)")
    
    if httpResponse.statusCode == 200 {
        let response = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        if let resources = response["resources"] as? [[String: Any]] {
            print("✅ Found \(resources.count) total resources")
            
            let recentResources = resources.filter { resource in
                let sourcedId = resource["sourcedId"] as? String ?? ""
                return sourcedId.contains("lesson-") || sourcedId.contains("debug-")
            }
            
            print("🎯 Recent Khan Academy resources: \(recentResources.count)")
            for resource in recentResources {
                let title = resource["title"] as? String ?? "Unknown"
                let sourcedId = resource["sourcedId"] as? String ?? "Unknown"
                print("  - \(title) (ID: \(sourcedId))")
            }
        } else {
            print("⚠️ No resources in response")
        }
    }
}

// Main execution
do {
    print("🔍 Debugging component-resource associations...")
    
    let token = try getAuthToken()
    print("✅ Got auth token")
    
    print("\n📋 Checking component-resources:")
    try checkComponentResources(token: token)
    
    print("\n📋 Checking resources:")
    try checkResources(token: token)
    
    print("\n🎉 Debug complete!")
    
} catch {
    print("❌ FAILED: \(error)")
}