#!/usr/bin/env swift

import Foundation

// Test both staging and production API URLs to find the correct one
let authBaseURL = "https://alpha-auth-development-idp.auth.us-west-2.amazoncognito.com"
let stagingApiURL = "https://api.staging.alpha-1edtech.com"
let productionApiURL = "https://api.alpha-1edtech.com"
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

// Test API URL by fetching the Khan Academy course
func testApiUrl(baseUrl: String, token: String) -> (success: Bool, statusCode: Int, hasResources: Bool) {
    let courseUrl = URL(string: "\(baseUrl)/ims/oneroster/rostering/v1p2/courses/\(khanCourseId)")!
    var request = URLRequest(url: courseUrl)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        result = (data, response, error)
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    guard let httpResponse = result.1 as? HTTPURLResponse else {
        return (false, 0, false)
    }
    
    // Check PowerPath syllabus for resources
    var hasResources = false
    if httpResponse.statusCode == 200 {
        let syllabusUrl = URL(string: "\(baseUrl)/powerpath/syllabus/\(khanCourseId)")!
        var syllabusRequest = URLRequest(url: syllabusUrl)
        syllabusRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let syllabusSemaphore = DispatchSemaphore(value: 0)
        var syllabusResult: (Data?, URLResponse?, Error?)
        
        URLSession.shared.dataTask(with: syllabusRequest) { data, response, error in
            syllabusResult = (data, response, error)
            syllabusSemaphore.signal()
        }.resume()
        
        syllabusSemaphore.wait()
        
        if let syllabusData = syllabusResult.0,
           let syllabusResponse = syllabusResult.1 as? HTTPURLResponse,
           syllabusResponse.statusCode == 200,
           let jsonString = String(data: syllabusData, encoding: .utf8) {
            hasResources = jsonString.contains("\"resources\":[{") // Has actual resources, not empty array
        }
    }
    
    return (httpResponse.statusCode == 200, httpResponse.statusCode, hasResources)
}

// Main execution
do {
    print("🔍 Testing both API URLs to find the correct one...")
    
    let token = try getAuthToken()
    print("✅ Got auth token")
    
    print("\n📡 Testing STAGING URL: \(stagingApiURL)")
    let stagingResult = testApiUrl(baseUrl: stagingApiURL, token: token)
    print("   Status: \(stagingResult.statusCode)")
    print("   Success: \(stagingResult.success)")
    print("   Has Resources: \(stagingResult.hasResources)")
    
    print("\n📡 Testing PRODUCTION URL: \(productionApiURL)")
    let productionResult = testApiUrl(baseUrl: productionApiURL, token: token)
    print("   Status: \(productionResult.statusCode)")
    print("   Success: \(productionResult.success)")
    print("   Has Resources: \(productionResult.hasResources)")
    
    print("\n🎯 RESULTS:")
    if stagingResult.success && productionResult.success {
        if stagingResult.hasResources && !productionResult.hasResources {
            print("✅ Use STAGING - course exists and has resources")
            print("📱 iOS app API URL is CORRECT")
        } else if !stagingResult.hasResources && productionResult.hasResources {
            print("✅ Use PRODUCTION - course exists and has resources")
            print("📱 iOS app API URL needs to be changed to production")
        } else if stagingResult.hasResources && productionResult.hasResources {
            print("⚠️ Both have resources - need to check which has our Khan Academy data")
        } else {
            print("⚠️ Both work but neither has resources yet - PowerPath may still be syncing")
        }
    } else if stagingResult.success {
        print("✅ Use STAGING - only staging works")
        print("📱 iOS app API URL is CORRECT")
    } else if productionResult.success {
        print("✅ Use PRODUCTION - only production works")  
        print("📱 iOS app API URL needs to be changed to production")
    } else {
        print("❌ Neither URL works - deeper authentication issue")
    }
    
} catch {
    print("❌ FAILED: \(error)")
}