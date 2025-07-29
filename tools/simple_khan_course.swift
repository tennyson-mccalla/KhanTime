#!/usr/bin/env swift

import Foundation

// Simple script to create Khan Academy course in TimeBack
// Uses synchronous URLSession for simplicity

let apiBaseURL = "https://api.staging.alpha-1edtech.com"
let authBaseURL = "https://alpha-auth-development-idp.auth.us-west-2.amazoncognito.com"
let orgSourcedId = "827d69dc-1312-4b07-89e3-c2e2d9822fb1"

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
    
    if let error = result.2 {
        throw error
    }
    
    guard let data = result.0,
          let httpResponse = result.1 as? HTTPURLResponse else {
        throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response"])
    }
    
    print("Auth response status: \(httpResponse.statusCode)")
    
    guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
        throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse: \(responseString)"])
    }
    
    print("Auth response keys: \(Array(jsonResponse.keys))")
    
    guard let accessToken = jsonResponse["access_token"] as? String else {
        throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No access token in: \(jsonResponse)"])
    }
    
    return accessToken
}

// Function to create course
func createCourse(courseId: String, token: String) throws {
    let url = URL(string: "\(apiBaseURL)/ims/oneroster/rostering/v1p2/courses")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let coursePayload = [
        "course": [
            "sourcedId": courseId,
            "status": "active",
            "title": "Khan Academy Pre-algebra",
            "courseCode": "KHAN_PRE_ALGEBRA",
            "grades": ["6", "7", "8"],
            "subjects": ["mathematics"],
            "org": ["sourcedId": orgSourcedId]
        ]
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: coursePayload)
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Data?, URLResponse?, Error?)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        result = (data, response, error)
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
    
    if let error = result.2 {
        throw error
    }
    
    guard let httpResponse = result.1 as? HTTPURLResponse else {
        throw NSError(domain: "CourseError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
    }
    
    print("Course creation status: \(httpResponse.statusCode)")
    
    if let data = result.0, let responseString = String(data: data, encoding: .utf8) {
        print("Course creation response: \(responseString)")
    }
    
    guard (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "CourseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create course"])
    }
}

// Function to create a simple component
func createComponent(unitId: String, courseId: String, title: String, sortOrder: Int, token: String) throws {
    let url = URL(string: "\(apiBaseURL)/ims/oneroster/rostering/v1p2/courses/components")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let payload = [
        "courseComponent": [
            "sourcedId": unitId,
            "status": "active",
            "title": title,
            "sortOrder": sortOrder,
            "courseSourcedId": courseId,
            "course": ["sourcedId": courseId]
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
    
    if let error = result.2 {
        throw error
    }
    
    guard let httpResponse = result.1 as? HTTPURLResponse else {
        throw NSError(domain: "ComponentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
    }
    
    print("Component '\(title)' creation status: \(httpResponse.statusCode)")
    
    if let data = result.0, let responseString = String(data: data, encoding: .utf8) {
        if httpResponse.statusCode != 200 {
            print("Component creation error: \(responseString)")
        }
    }
    
    guard (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "ComponentError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create component: \(title)"])
    }
}

// Function to verify course exists
func verifyCourse(courseId: String, token: String) throws {
    print("🔍 Verifying course...")
    
    // Check course exists
    let courseUrl = URL(string: "\(apiBaseURL)/ims/oneroster/rostering/v1p2/courses/\(courseId)")!
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
        throw error
    }
    
    guard let data = result.0,
          let httpResponse = result.1 as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw NSError(domain: "VerificationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Course verification failed"])
    }
    
    let courseResponse = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    let course = courseResponse["course"] as! [String: Any]
    
    print("✅ Course verified: \(course["title"] as! String)")
    
    // Check syllabus
    let syllabusUrl = URL(string: "\(apiBaseURL)/powerpath/syllabus/\(courseId)")!
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
        print("⚠️ Syllabus check failed: \(error)")
        return
    }
    
    guard let syllabusData = syllabusResult.0,
          let syllabusHttpResponse = syllabusResult.1 as? HTTPURLResponse,
          syllabusHttpResponse.statusCode == 200 else {
        print("⚠️ Syllabus not available yet (may take time to sync)")
        return
    }
    
    let syllabusResponse = try JSONSerialization.jsonObject(with: syllabusData) as! [String: Any]
    let syllabus = syllabusResponse["syllabus"] as! [String: Any]
    let components = syllabus["subComponents"] as! [[String: Any]]
    
    print("✅ Syllabus verified: \(components.count) components")
    
    for component in components {
        let title = component["title"] as! String
        print("  - \(title)")
    }
}

// Main execution
do {
    let timestamp = Int(Date().timeIntervalSince1970)
    let courseId = "khan-pre-algebra-\(timestamp)"
    
    print("🚀 Creating Khan Academy Pre-algebra course...")
    print("📋 Course ID: \(courseId)")
    
    // Step 1: Get auth token
    print("1️⃣ Getting auth token...")
    let token = try getAuthToken()
    print("✅ Got auth token")
    
    // Step 2: Create course
    print("2️⃣ Creating course...")
    try createCourse(courseId: courseId, token: token)
    print("✅ Course created")
    
    // Step 3: Create first few units
    print("3️⃣ Creating units...")
    let units = ["Factors and multiples", "Prime numbers", "Prime factorization"]
    
    for (index, title) in units.enumerated() {
        let unitId = "khan-unit-\(index)-\(timestamp)"
        print("📝 Creating unit: \(title)")
        try createComponent(unitId: unitId, courseId: courseId, title: title, sortOrder: index, token: token)
    }
    
    print("✅ Created \(units.count) units")
    
    // Step 4: Verify
    print("4️⃣ Verifying course...")
    try verifyCourse(courseId: courseId, token: token)
    
    print("")
    print("🎉 SUCCESS!")
    print("📱 Course ID for your app: \(courseId)")
    print("")
    print("To test in your iOS app:")
    print("defaults write com.yourcompany.KhanTime KhanAcademyCourseId '\(courseId)'")
    
} catch {
    print("❌ FAILED: \(error)")
    exit(1)
}