#!/usr/bin/env swift

import Foundation

// Check if our Khan Academy resources exist on staging or were created on production
let authBaseURL = "https://alpha-auth-development-idp.auth.us-west-2.amazoncognito.com"
let stagingApiURL = "https://api.staging.alpha-1edtech.com"
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

// Check for Khan Academy resources on staging
func checkResources(token: String) {
    print("🔍 Checking for Khan Academy resources on STAGING...")
    
    // Check component-resources
    let componentResourcesUrl = URL(string: "\(stagingApiURL)/ims/oneroster/rostering/v1p2/courses/component-resources?filter=courseComponent.sourcedId~'khan-unit'")!
    var request = URLRequest(url: componentResourcesUrl)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        result = (data, response, error)
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    if let error = result.2 {
        print("❌ Component-resources request failed: \(error)")
        return
    }
    
    guard let data = result.0,
          let httpResponse = result.1 as? HTTPURLResponse else {
        print("❌ No response data")
        return
    }
    
    print("📊 Component-resources status: \(httpResponse.statusCode)")
    
    if httpResponse.statusCode == 200 {
        do {
            let response = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            if let componentResources = response["componentResources"] as? [[String: Any]] {
                let khanResources = componentResources.filter { resource in
                    if let courseComponent = resource["courseComponent"] as? [String: Any],
                       let sourcedId = courseComponent["sourcedId"] as? String {
                        return sourcedId.contains("khan-unit")
                    }
                    return false
                }
                
                print("✅ Found \(khanResources.count) Khan Academy component-resources on staging")
                
                if khanResources.count > 0 {
                    print("📋 Khan Academy resources:")
                    for resource in khanResources {
                        let title = resource["title"] as? String ?? "Unknown"
                        let sourcedId = resource["sourcedId"] as? String ?? "Unknown"
                        if let courseComponent = resource["courseComponent"] as? [String: Any],
                           let unitId = courseComponent["sourcedId"] as? String {
                            print("  - \(title) (ID: \(sourcedId)) -> Unit: \(unitId)")
                        }
                    }
                }
            }
        } catch {
            print("❌ Failed to parse component-resources response: \(error)")
        }
    } else {
        let responseString = String(data: data, encoding: .utf8) ?? "No response"
        print("❌ Component-resources error: \(responseString)")
    }
    
    // Check standalone resources
    print("\n🔍 Checking standalone resources...")
    let resourcesUrl = URL(string: "\(stagingApiURL)/ims/oneroster/resources/v1p2/resources?filter=sourcedId~'khan'")!
    var resourcesRequest = URLRequest(url: resourcesUrl)
    resourcesRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let resourcesSemaphore = DispatchSemaphore(value: 0)
    var resourcesResult: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: resourcesRequest) { data, response, error in
        resourcesResult = (data, response, error)
        resourcesSemaphore.signal()
    }.resume()
    
    resourcesSemaphore.wait()
    
    if let resourcesData = resourcesResult.0,
       let resourcesResponse = resourcesResult.1 as? HTTPURLResponse,
       resourcesResponse.statusCode == 200 {
        do {
            let response = try JSONSerialization.jsonObject(with: resourcesData) as! [String: Any]
            if let resources = response["resources"] as? [[String: Any]] {
                let khanStandaloneResources = resources.filter { resource in
                    let sourcedId = resource["sourcedId"] as? String ?? ""
                    return sourcedId.contains("khan")
                }
                
                print("✅ Found \(khanStandaloneResources.count) Khan Academy standalone resources on staging")
                
                if khanStandaloneResources.count > 0 {
                    print("📋 Khan Academy standalone resources:")
                    for resource in khanStandaloneResources.prefix(5) {  // Show first 5
                        let title = resource["title"] as? String ?? "Unknown"
                        let sourcedId = resource["sourcedId"] as? String ?? "Unknown"
                        print("  - \(title) (ID: \(sourcedId))")
                    }
                    if khanStandaloneResources.count > 5 {
                        print("  ... and \(khanStandaloneResources.count - 5) more")
                    }
                }
            }
        } catch {
            print("❌ Failed to parse resources response: \(error)")
        }
    }
}

// Main execution
do {
    print("🔍 Checking where our Khan Academy resources were created...")
    
    let token = try getAuthToken()
    print("✅ Got auth token")
    
    checkResources(token: token)
    
    print("\n🎯 ANALYSIS:")
    print("If resources exist on staging but not in PowerPath syllabus:")
    print("  → PowerPath sync is broken/slow, use OneRoster direct approach")
    print("If no resources exist on staging:")
    print("  → Resources were created on production, need to recreate on staging")
    
} catch {
    print("❌ FAILED: \(error)")
}