#!/usr/bin/env swift

import Foundation

// Simple script to create a Khan Academy course in TimeBack platform
// This runs outside the iOS app as an external tool

struct CreateKhanAcademyCourse {
    
    let baseURL = "https://api.staging.alpha-1edtech.com"
    let orgSourcedId = "827d69dc-1312-4b07-89e3-c2e2d9822fb1"
    
    func createCourse() async throws -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let courseId = "khan-pre-algebra-\(timestamp)"
        
        print("🚀 Creating Khan Academy Pre-algebra course externally...")
        print("📋 Course ID: \(courseId)")
        
        // Step 1: Get auth token
        let token = try await getAuthToken()
        print("✅ Got auth token")
        
        // Step 2: Create course
        try await createCourseEntity(courseId: courseId, token: token)
        print("✅ Created course")
        
        // Step 3: Create units with fixed metadata
        try await createKhanUnits(courseId: courseId, token: token)
        print("✅ Created all units")
        
        // Step 4: Verify course exists and can be fetched
        try await verifyCourse(courseId: courseId, token: token)
        
        print("🎉 Khan Academy course created successfully!")
        print("📱 Course ID to use in app: \(courseId)")
        
        return courseId
    }
    
    private func getAuthToken() async throws -> String {
        // Use your existing credentials to get token
        let url = URL(string: "\(baseURL)/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Use actual credentials from iOS app
        let credentials = "client_id=3ab5g0ak4fshvlaccu0s9f75g&client_secret=ukrk6q99c62hic32pv6jb2afjq5kdddafku0s64a6m70vjlnnh&grant_type=client_credentials"
        request.httpBody = credentials.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        if let httpResponse = response as? HTTPURLResponse {
            print("Auth response status: \(httpResponse.statusCode)")
        }
        
        // Parse response safely
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse auth response: \(responseString)"])
        }
        
        print("Auth response: \(jsonResponse)")
        
        guard let accessToken = jsonResponse["access_token"] as? String else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No access token in response: \(jsonResponse)"])
        }
        
        return accessToken
    }
    
    private func createCourseEntity(courseId: String, token: String) async throws {
        let url = URL(string: "\(baseURL)/ims/oneroster/rostering/v1p2/courses")!
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
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "CourseCreation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create course"])
        }
    }
    
    private func createKhanUnits(courseId: String, token: String) async throws {
        let khanUnits = [
            "Factors and multiples",
            "Prime numbers", 
            "Prime factorization",
            "Divisibility",
            "Greatest common factor",
            "Least common multiple",
            "Arithmetic patterns",
            "Intro to fractions",
            "Comparing fractions",
            "Adding and subtracting fractions",
            "Mixed numbers",
            "Multiplying fractions",
            "Dividing fractions",
            "Intro to decimals",
            "Decimals and fractions"
        ]
        
        for (index, unitTitle) in khanUnits.enumerated() {
            let unitId = "khan-unit-\(index)-\(Int(Date().timeIntervalSince1970))"
            
            print("📝 Creating unit \(index + 1)/15: \(unitTitle)")
            
            // Create component
            try await createComponent(unitId: unitId, courseId: courseId, title: unitTitle, sortOrder: index, token: token)
            
            // Create resources with proper format field
            try await createUnitResources(unitId: unitId, unitTitle: unitTitle, unitIndex: index, token: token)
        }
    }
    
    private func createComponent(unitId: String, courseId: String, title: String, sortOrder: Int, token: String) async throws {
        let url = URL(string: "\(baseURL)/ims/oneroster/rostering/v1p2/courses/components")!
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
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "ComponentCreation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create component: \(title)"])
        }
    }
    
    private func createUnitResources(unitId: String, unitTitle: String, unitIndex: Int, token: String) async throws {
        let timestamp = Int(Date().timeIntervalSince1970)
        
        let resources = [
            (
                id: "video-\(unitIndex)-\(timestamp)",
                title: "Video: Understanding \(unitTitle)",
                type: "video",
                subType: "educational-video",
                format: "video/mp4",  // Added required format
                url: "https://www.khanacademy.org/math/pre-algebra/\(unitTitle.lowercased().replacingOccurrences(of: " ", with: "-"))/video"
            ),
            (
                id: "exercise-\(unitIndex)-\(timestamp)", 
                title: "Practice: \(unitTitle) Exercises",
                type: "qti-assessment",
                subType: "qti-test",
                format: "application/xml", // QTI format
                url: "https://www.khanacademy.org/math/pre-algebra/\(unitTitle.lowercased().replacingOccurrences(of: " ", with: "-"))/exercise"
            ),
            (
                id: "quiz-\(unitIndex)-\(timestamp)",
                title: "Quiz: \(unitTitle)",
                type: "qti-assessment", 
                subType: "qti-quiz",
                format: "application/xml", // QTI format
                url: "https://www.khanacademy.org/math/pre-algebra/\(unitTitle.lowercased().replacingOccurrences(of: " ", with: "-"))/quiz"
            )
        ]
        
        for (resourceIndex, resource) in resources.enumerated() {
            // Create resource
            try await createResource(resource: resource, token: token)
            
            // Associate with component
            let componentResourceId = "comp-res-\(unitIndex)-\(resourceIndex)-\(timestamp)"
            try await associateResourceToComponent(componentResourceId: componentResourceId, unitId: unitId, resourceId: resource.id, resourceTitle: resource.title, token: token)
        }
    }
    
    private func createResource(resource: (id: String, title: String, type: String, subType: String, format: String, url: String), token: String) async throws {
        let url = URL(string: "\(baseURL)/ims/oneroster/resources/v1p2/resources")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = [
            "resource": [
                "sourcedId": resource.id,
                "status": "active",
                "title": resource.title,
                "vendorResourceId": "khan-\(resource.id)",
                "metadata": [
                    "type": resource.type,
                    "subType": resource.subType,
                    "format": resource.format,  // Required field now included
                    "url": resource.url
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "ResourceCreation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create resource: \(resource.title)"])
        }
    }
    
    private func associateResourceToComponent(componentResourceId: String, unitId: String, resourceId: String, resourceTitle: String, token: String) async throws {
        let url = URL(string: "\(baseURL)/ims/oneroster/rostering/v1p2/courses/component-resources")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = [
            "componentResource": [
                "sourcedId": componentResourceId,
                "status": "active", 
                "title": resourceTitle,
                "sortOrder": 1,
                "courseComponent": ["sourcedId": unitId],
                "resource": ["sourcedId": resourceId]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "AssociationCreation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to associate resource to component"])
        }
    }
    
    private func verifyCourse(courseId: String, token: String) async throws {
        print("🔍 Verifying course creation...")
        
        // Check course exists
        let courseUrl = URL(string: "\(baseURL)/ims/oneroster/rostering/v1p2/courses/\(courseId)")!
        var courseRequest = URLRequest(url: courseUrl)
        courseRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (courseData, _) = try await URLSession.shared.data(for: courseRequest)
        let courseResponse = try JSONSerialization.jsonObject(with: courseData) as! [String: Any]
        let course = courseResponse["course"] as! [String: Any]
        
        print("✅ Course verified: \(course["title"] as! String)")
        
        // Check syllabus exists
        let syllabusUrl = URL(string: "\(baseURL)/powerpath/syllabus/\(courseId)")!
        var syllabusRequest = URLRequest(url: syllabusUrl)
        syllabusRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (syllabusData, _) = try await URLSession.shared.data(for: syllabusRequest)
        let syllabusResponse = try JSONSerialization.jsonObject(with: syllabusData) as! [String: Any]
        let syllabus = syllabusResponse["syllabus"] as! [String: Any]
        let components = syllabus["subComponents"] as! [[String: Any]]
        
        print("✅ Syllabus verified: \(components.count) components")
        
        for component in components {
            let title = component["title"] as! String
            let resources = component["componentResources"] as? [[String: Any]] ?? []
            print("  - \(title): \(resources.count) resources")
        }
    }
}

// Main execution
if #available(macOS 10.15, iOS 13.0, *) {
    Task {
        do {
            let creator = CreateKhanAcademyCourse()
            let courseId = try await creator.createCourse()
            print("\\n🎯 SUCCESS!")
            print("Use this course ID in your app: \(courseId)")
        } catch {
            print("❌ FAILED: \(error)")
        }
    }
    
    // Keep the script running for async operations
    RunLoop.main.run()
} else {
    print("❌ This script requires macOS 10.15+ or iOS 13.0+")
}