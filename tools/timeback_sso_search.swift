#!/usr/bin/swift

import Foundation

// TimeBack search using SSO credentials for ae.studio content
struct TimeBackSSOSearch {
    let baseURL = "https://api.staging.alpha-1edtech.com"
    let authBaseURL = "https://alpha-auth-development-idp.auth.us-west-2.amazoncognito.com"
    
    // SSO Credentials
    let ssoClientID = "3bq28tn7fpo3cfuvvq1p3mahe2"
    
    // M2M Credentials (fallback)
    let m2mClientID = "3ab5g0ak4fshvlaccu0s9f75g"
    let m2mClientSecret = "ukrk6q99c62hic32pv6jb2afjq5kdddafku0s64a6m70vjlnnh"
    
    func run() async {
        print("🔍 Searching TimeBack staging for ae.studio 3rd grade language content...")
        print("=====================================\n")
        
        // Try M2M first (what we know works)
        print("🔐 Trying M2M authentication first...")
        if let m2mToken = await getM2MToken() {
            print("✅ M2M authentication successful")
            await searchWithToken(m2mToken, authType: "M2M")
        } else {
            print("❌ M2M authentication failed")
        }
        
        print("\n" + String(repeating: "=", count: 50) + "\n")
        
        // Then try to understand SSO flow
        print("🔐 Examining SSO authentication...")
        await exploreSSO()
        
        print("\n✅ Search complete!")
        print("\n💡 Next steps:")
        print("1. If M2M found ae.studio content, we're good to go")
        print("2. If not, we may need to implement proper SSO flow")
        print("3. Consider asking Andy for specific course IDs")
    }
    
    private func getM2MToken() async -> String? {
        let endpoint = "/oauth2/token"
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: m2mClientID),
            URLQueryItem(name: "client_secret", value: m2mClientSecret)
        ]
        
        let body = components.query?.data(using: .utf8)
        
        guard let url = URL(string: authBaseURL + endpoint) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let accessToken = json["access_token"] as? String {
                        return accessToken
                    }
                } else {
                    print("❌ M2M Auth failed with HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ M2M Auth network error: \(error)")
        }
        
        return nil
    }
    
    private func exploreSSO() async {
        print("🔍 SSO typically requires:")
        print("1. Authorization Code flow (not client credentials)")
        print("2. User login through browser/webview")
        print("3. Redirect URI for callback")
        print("4. PKCE for security")
        
        print("\n📋 SSO Client ID: \(ssoClientID)")
        print("📋 Would need to implement full OAuth2 authorization code flow")
        
        // For now, just test if SSO client ID is valid by trying a simple request
        print("\n🧪 Testing SSO client ID validity...")
        
        let testEndpoint = "/oauth2/token"
        guard let url = URL(string: authBaseURL + testEndpoint) else { return }
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: ssoClientID),
            URLQueryItem(name: "client_secret", value: "dummy") // SSO doesn't need secret
        ]
        
        let body = components.query?.data(using: .utf8)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 SSO test response: HTTP \(httpResponse.statusCode)")
                
                if let errorString = String(data: data, encoding: .utf8) {
                    if errorString.contains("invalid_client") {
                        print("❌ SSO Client ID not configured for client_credentials flow (expected)")
                    } else {
                        print("📝 Response: \(errorString)")
                    }
                }
            }
        } catch {
            print("❌ SSO test error: \(error)")
        }
    }
    
    private func searchWithToken(_ token: String, authType: String) async {
        print("\n🔍 Searching with \(authType) token...")
        
        // Search organizations
        await findOrganizations(token: token)
        
        // Search courses
        await searchCourses(token: token)
        
        // Search resources
        await searchResources(token: token)
    }
    
    private func findOrganizations(token: String) async {
        print("\n🏢 ORGANIZATIONS:")
        
        let endpoint = "/ims/oneroster/rostering/v1p2/orgs"
        
        if let data = await makeAPICall(endpoint: endpoint, token: token) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let orgs = json["orgs"] as? [[String: Any]] {
                
                print("Found \(orgs.count) organizations")
                
                var foundAEStudio = false
                for org in orgs {
                    if let name = org["name"] as? String,
                       let sourcedId = org["sourcedId"] as? String {
                        
                        let nameMatch = name.lowercased().contains("ae.studio") ||
                                       name.lowercased().contains("aestudio") ||
                                       name.lowercased().contains("ae studio") ||
                                       name.lowercased().contains("alpha")
                        
                        if nameMatch {
                            print("⭐ FOUND: \(name) (ID: \(sourcedId))")
                            foundAEStudio = true
                        } else if orgs.count < 20 { // Only show all if not too many
                            print("  - \(name)")
                        }
                    }
                }
                
                if !foundAEStudio {
                    print("❌ No ae.studio/alpha organization found")
                }
            }
        }
    }
    
    private func searchCourses(token: String) async {
        print("\n📚 COURSES:")
        
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
                           titleLower.contains("elementary") ||
                           titleLower.contains("3")
                }
                
                if !relevantCourses.isEmpty {
                    print("🎯 Relevant courses:")
                    for course in relevantCourses {
                        if let title = course["title"] as? String,
                           let id = course["sourcedId"] as? String {
                            print("  ⭐ \(title)")
                            print("     ID: \(id)")
                            
                            // Try to get syllabus
                            await checkSyllabus(courseId: id, token: token)
                        }
                    }
                } else {
                    print("❌ No language-related courses found")
                    print("Sample course titles:")
                    for course in courses.prefix(10) {
                        if let title = course["title"] as? String {
                            print("  - \(title)")
                        }
                    }
                }
            }
        }
    }
    
    private func searchResources(token: String) async {
        print("\n📦 RESOURCES:")
        
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
                           titleLower.contains("grade") ||
                           titleLower.contains("3")
                }
                
                if !relevantResources.isEmpty {
                    print("🎯 Relevant resources:")
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
                print("     └─ Syllabus: \(components.count) components")
            } else {
                print("     └─ No syllabus found")
            }
        }
    }
    
    private func makeAPICall(endpoint: String, token: String) async -> Data? {
        guard let url = URL(string: baseURL + endpoint) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    return data
                } else {
                    print("❌ HTTP \(httpResponse.statusCode) for \(endpoint)")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("   Error: \(errorString.prefix(200))")
                    }
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
    let search = TimeBackSSOSearch()
    await search.run()
}