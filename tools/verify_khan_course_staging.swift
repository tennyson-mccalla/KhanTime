#!/usr/bin/env swift

import Foundation

// Verify Khan Academy course on STAGING (correct URL)
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

// Main execution
do {
    print("🔍 Verifying Khan Academy course on STAGING: \(khanCourseId)")
    
    let token = try getAuthToken()
    print("✅ Got auth token")
    
    // Verify course exists
    let courseUrl = URL(string: "\(apiBaseURL)/ims/oneroster/rostering/v1p2/courses/\(khanCourseId)")!
    var courseRequest = URLRequest(url: courseUrl)
    courseRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: courseRequest) { data, response, error in
        result = (data, response, error)
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    if let error = result.2 {
        print("❌ Course request failed: \(error)")
        exit(1)
    }
    
    guard let data = result.0,
          let httpResponse = result.1 as? HTTPURLResponse else {
        print("❌ No response data")
        exit(1)
    }
    
    print("📊 Course fetch status: \(httpResponse.statusCode)")
    
    if httpResponse.statusCode == 200 {
        let courseResponse = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let course = courseResponse["course"] as! [String: Any]
        let title = course["title"] as! String
        print("✅ Course found: \(title)")
    } else {
        let responseString = String(data: data, encoding: .utf8) ?? "No response"
        print("❌ Course not found: \(responseString)")
        exit(1)
    }
    
    // Check PowerPath syllabus on STAGING
    print("\n🔍 Checking PowerPath syllabus on STAGING...")
    let syllabusUrl = URL(string: "\(apiBaseURL)/powerpath/syllabus/\(khanCourseId)")!
    var syllabusRequest = URLRequest(url: syllabusUrl)
    syllabusRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let syllabusSemaphore = DispatchSemaphore(value: 0)
    var syllabusResult: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: syllabusRequest) { data, response, error in
        syllabusResult = (data, response, error)
        syllabusSemaphore.signal()
    }.resume()
    
    syllabusSemaphore.wait()
    
    if let error = syllabusResult.2 {
        print("❌ Syllabus request failed: \(error)")
        exit(1)
    }
    
    guard let syllabusData = syllabusResult.0,
          let syllabusHttpResponse = syllabusResult.1 as? HTTPURLResponse else {
        print("❌ No syllabus response data")
        exit(1)
    }
    
    print("📊 Syllabus fetch status: \(syllabusHttpResponse.statusCode)")
    
    if syllabusHttpResponse.statusCode == 200 {
        let syllabusResponse = try JSONSerialization.jsonObject(with: syllabusData) as! [String: Any]
        let syllabus = syllabusResponse["syllabus"] as! [String: Any]
        
        if let components = syllabus["subComponents"] as? [[String: Any]] {
            print("✅ Syllabus has \(components.count) components:")
            var hasAnyResources = false
            
            for (index, component) in components.enumerated() {
                let title = component["title"] as? String ?? "Unknown"
                let componentId = component["sourcedId"] as? String ?? "Unknown"
                
                // Check for resources in each component
                if let resources = component["resources"] as? [[String: Any]], !resources.isEmpty {
                    print("  \(index + 1). \(title) (ID: \(componentId))")
                    print("     📝 \(resources.count) resources:")
                    hasAnyResources = true
                    for resource in resources {
                        let resourceTitle = resource["title"] as? String ?? "Unknown"
                        print("        - \(resourceTitle)")
                    }
                } else {
                    print("  \(index + 1). \(title) (ID: \(componentId))")
                    print("     📝 No resources found")
                }
            }
            
            if hasAnyResources {
                print("\n🎉 SUCCESS: PowerPath has synced! Resources are available!")
            } else {
                print("\n⚠️ PowerPath sync still incomplete - no resources found in any component")
            }
        } else {
            print("⚠️ No components found in syllabus")
        }
    } else {
        let responseString = String(data: syllabusData, encoding: .utf8) ?? "No response"
        print("❌ Syllabus not available: \(responseString)")
    }
    
    print("\n✅ Verification complete on STAGING environment")
    
} catch {
    print("❌ FAILED: \(error)")
    exit(1)
}