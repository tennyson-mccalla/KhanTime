#!/usr/bin/env swift

import Foundation

// Script to populate the Khan Academy course with real scraped content
let apiBaseURL = "https://api.staging.alpha-1edtech.com"
let authBaseURL = "https://alpha-auth-development-idp.auth.us-west-2.amazoncognito.com"
let khanCourseId = "khan-pre-algebra-1753750080"

struct KhanContent: Codable {
    let title: String
    let description: String
    let units: [KhanUnit]
    
    struct KhanUnit: Codable {
        let id: String
        let title: String
        let description: String
        let lessons: [KhanLesson]
        let exercises: [KhanExercise]
    }
    
    struct KhanLesson: Codable {
        let id: String
        let title: String
        let slug: String
        let contentKind: String
        let videoUrl: String?
        let duration: Int?
        let difficulty: String?
        let prerequisites: [String]?
    }
    
    struct KhanExercise: Codable {
        let id: String
        let title: String
        let slug: String
        let difficulty: String?
    }
}

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

// Function to create resource with proper format
func createResource(resourceId: String, title: String, type: String, subType: String, format: String, url: String, token: String) throws {
    let resourceUrl = URL(string: "\(apiBaseURL)/ims/oneroster/resources/v1p2/resources")!
    var request = URLRequest(url: resourceUrl)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let payload = [
        "resource": [
            "sourcedId": resourceId,
            "status": "active",
            "title": title,
            "vendorResourceId": "khan-\(resourceId)",
            "metadata": [
                "type": type,
                "subType": subType,
                "format": format,
                "url": url
            ]
        ]
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        result = (data, response, error)
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    if let error = result.2 { throw error }
    
    guard let httpResponse = result.1 as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        if let data = result.0, let errorString = String(data: data, encoding: .utf8) {
            print("Resource creation error: \(errorString)")
        }
        throw NSError(domain: "ResourceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create resource: \(title)"])
    }
    
    print("✅ Created resource: \(title)")
}

// Function to associate resource to component
func associateResourceToComponent(componentResourceId: String, unitId: String, resourceId: String, resourceTitle: String, sortOrder: Int, token: String) throws {
    let url = URL(string: "\(apiBaseURL)/ims/oneroster/rostering/v1p2/courses/component-resources")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let payload = [
        "componentResource": [
            "sourcedId": componentResourceId,
            "status": "active",
            "title": resourceTitle,
            "sortOrder": sortOrder,
            "courseComponent": ["sourcedId": unitId],
            "resource": ["sourcedId": resourceId]
        ]
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        result = (data, response, error)
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    if let error = result.2 { throw error }
    
    guard let httpResponse = result.1 as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "AssociationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to associate resource"])
    }
    
    print("✅ Associated resource: \(resourceTitle)")
}

// Main execution
do {
    print("🚀 Populating Khan Academy course with real content...")
    
    // Load scraped Khan Academy content
    let jsonPath = "/Users/Tennyson/KhanTime/tools/brainlift_output/pre-algebra_deep_authenticated_1753722260.json"
    
    guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
          let khanContent = try? JSONDecoder().decode(KhanContent.self, from: jsonData) else {
        throw NSError(domain: "LoadError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load Khan Academy content"])
    }
    
    print("📚 Loaded Khan Academy content: \(khanContent.units.count) units")
    
    // Get auth token
    let token = try getAuthToken()
    print("✅ Got auth token")
    
    // Process first 3 units (to match what we created)
    let unitsToProcess = Array(khanContent.units.prefix(3))
    
    for (unitIndex, unit) in unitsToProcess.enumerated() {
        print("\\n📝 Processing unit \(unitIndex + 1): \(unit.title)")
        
        let unitId = "khan-unit-\(unitIndex)-1753750080"  // Match what we created
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // Process lessons in this unit
        for (lessonIndex, lesson) in unit.lessons.enumerated() {
            let resourceId = "lesson-\(unitIndex)-\(lessonIndex)-\(timestamp)"
            
            // Determine format based on content type
            let (type, subType, format) = getResourceTypeInfo(for: lesson)
            let url = lesson.videoUrl ?? "https://www.khanacademy.org/math/pre-algebra/\(lesson.slug)"
            
            // Create resource
            try createResource(
                resourceId: resourceId,
                title: lesson.title,
                type: type,
                subType: subType,
                format: format,
                url: url,
                token: token
            )
            
            // Associate with unit
            let componentResourceId = "comp-res-\(unitIndex)-\(lessonIndex)-\(timestamp)"
            try associateResourceToComponent(
                componentResourceId: componentResourceId,
                unitId: unitId,
                resourceId: resourceId,
                resourceTitle: lesson.title,
                sortOrder: lessonIndex,
                token: token
            )
        }
        
        print("✅ Completed unit: \(unit.title) (\(unit.lessons.count) resources)")
    }
    
    print("\\n🎉 SUCCESS!")
    print("📱 Khan Academy course now has real content!")
    print("🔄 Restart your iOS app to see the changes")
    
} catch {
    print("❌ FAILED: \(error)")
}

func getResourceTypeInfo(for lesson: KhanContent.KhanLesson) -> (String, String, String) {
    // For now, use QTI format for all resources since TimeBack API is restrictive
    return ("qti", "qti-test", "application/xml")
}