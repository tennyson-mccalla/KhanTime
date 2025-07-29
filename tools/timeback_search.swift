#!/usr/bin/swift

import Foundation

// Command-line TimeBack search for ae.studio content
// This uses your existing TimeBack staging credentials

struct TimeBackSearch {
    let baseURL = "https://api.staging.alpha-1edtech.com"
    let authBaseURL = "https://alpha-auth-development-idp.auth.us-west-2.amazoncognito.com"
    let clientID = "3ab5g0ak4fshvlaccu0s9f75g"
    let clientSecret = "ukrk6q99c62hic32pv6jb2afjq5kdddafku0s64a6m70vjlnnh"
    
    func run() async {
        print("🔍 Searching TimeBack staging for ae.studio 3rd grade language content...")
        print("=====================================\n")
        
        // Step 1: Get auth token
        guard let token = await getAuthToken() else {
            print("❌ Could not get auth token")
            return
        }
        
        print("✅ Authentication successful\n")
        
        // Step 2: Search for organizations
        await findOrganizations(token: token)
        
        // Step 3: Search for courses
        await searchCourses(token: token)
        
        // Step 4: Search for resources
        await searchResources(token: token)
        
        print("\n✅ Search complete!")
        print("\n💡 If nothing found, ask Andy Montgomery for:")
        print("1. Exact course IDs for ae.studio 3rd grade language content")
        print("2. Organization name/ID used by ae.studio in TimeBack")
        print("3. Whether content is in production instead of staging")
    }
    
    private func getAuthToken() async -> String? {
        print("🔐 Authenticating with TimeBack staging...")
        
        let endpoint = "/oauth2/token"
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret)
        ]
        
        let body = components.query?.data(using: .utf8)
        
        guard let url = URL(string: authBaseURL + endpoint) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let accessToken = json["access_token"] as? String {
                        return accessToken
                    }
                } else {
                    print("❌ Auth failed with HTTP \(httpResponse.statusCode)")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("Error: \(errorString)")
                    }
                }
            }
        } catch {
            print("❌ Auth network error: \(error)")
        }
        
        return nil
    }
    
    private func findOrganizations(token: String) async {
        print("🏢 STEP 1: Searching for ae.studio organization...")
        
        let endpoint = "/ims/oneroster/rostering/v1p2/orgs"
        
        if let data = await makeAPICall(endpoint: endpoint, token: token) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let orgs = json["orgs"] as? [[String: Any]] {
                
                print("Found \(orgs.count) organizations:")
                
                var foundAEStudio = false
                for org in orgs {
                    if let name = org["name"] as? String,
                       let sourcedId = org["sourcedId"] as? String {
                        
                        let nameMatch = name.lowercased().contains("ae.studio") ||
                                       name.lowercased().contains("aestudio") ||
                                       name.lowercased().contains("ae studio")
                        
                        if nameMatch {
                            print("⭐ FOUND: \(name) (ID: \(sourcedId))")
                            foundAEStudio = true
                        } else {
                            print("  - \(name)")
                        }
                    }
                }
                
                if !foundAEStudio {
                    print("❌ No ae.studio organization found")
                }
            }
        }
        print("")
    }
    
    private func searchCourses(token: String) async {
        print("📚 STEP 2: Searching for language/grade courses...")
        
        let endpoint = "/ims/oneroster/rostering/v1p2/courses?limit=100"
        
        if let data = await makeAPICall(endpoint: endpoint, token: token) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let courses = json["courses"] as? [[String: Any]] {
                
                print("Found \(courses.count) total courses")
                
                // Filter for relevant courses
                let relevantCourses = courses.filter { course in
                    guard let title = course["title"] as? String else { return false }
                    let titleLower = title.lowercased()
                    return titleLower.contains("language") ||
                           titleLower.contains("english") ||
                           titleLower.contains("reading") ||
                           titleLower.contains("grade") ||
                           titleLower.contains("3rd") ||
                           titleLower.contains("elementary")
                }
                
                if !relevantCourses.isEmpty {
                    print("🎯 Relevant courses found:")
                    for course in relevantCourses {
                        if let title = course["title"] as? String,
                           let id = course["sourcedId"] as? String {
                            print("  ⭐ \(title) (ID: \(id))")
                            
                            // Try to get syllabus
                            await checkSyllabus(courseId: id, token: token)
                        }
                    }
                } else {
                    print("❌ No language-related courses found")
                    print("Sample course titles:")
                    for course in courses.prefix(5) {
                        if let title = course["title"] as? String {
                            print("  - \(title)")
                        }
                    }
                }
            }
        }
        print("")
    }
    
    private func searchResources(token: String) async {
        print("📦 STEP 3: Searching for language resources...")
        
        let endpoint = "/ims/oneroster/rostering/v1p2/resources?limit=50"
        
        if let data = await makeAPICall(endpoint: endpoint, token: token) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let resources = json["resources"] as? [[String: Any]] {
                
                print("Found \(resources.count) total resources")
                
                let relevantResources = resources.filter { resource in
                    guard let title = resource["title"] as? String else { return false }
                    let titleLower = title.lowercased()
                    return titleLower.contains("language") ||
                           titleLower.contains("reading") ||
                           titleLower.contains("english") ||
                           titleLower.contains("grade")
                }
                
                if !relevantResources.isEmpty {
                    print("🎯 Relevant resources found:")
                    for resource in relevantResources {
                        if let title = resource["title"] as? String,
                           let id = resource["sourcedId"] as? String {
                            print("  ⭐ \(title) (ID: \(id))")
                        }
                    }
                } else {
                    print("❌ No language-related resources found")
                }
            }
        }
    }
    
    private func checkSyllabus(courseId: String, token: String) async {
        let endpoint = "/powerpath/syllabus/\(courseId)"
        
        if let data = await makeAPICall(endpoint: endpoint, token: token) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let syllabus = json["syllabus"] as? [String: Any],
               let components = syllabus["components"] as? [[String: Any]] {
                print("    └─ Syllabus: \(components.count) components")
            }
        }
    }
    
    private func makeAPICall(endpoint: String, token: String) async -> Data? {
        guard let url = URL(string: baseURL + endpoint) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    return data
                } else {
                    print("❌ HTTP \(httpResponse.statusCode) for \(endpoint)")
                }
            }
        } catch {
            print("❌ Network error for \(endpoint): \(error)")
        }
        
        return nil
    }
}

// Run the search
Task {
    let search = TimeBackSearch()
    await search.run()
}