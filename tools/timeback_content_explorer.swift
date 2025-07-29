#!/usr/bin/swift

import Foundation

// TimeBack Content Explorer for ae.studio 3rd grade language content
// This script will query the TimeBack staging API to find existing content

struct TimeBackExplorer {
    let baseURL = "https://api.staging.alpha-1edtech.com"
    
    func run() async {
        print("🔍 Exploring TimeBack staging for ae.studio 3rd grade language content...")
        
        await exploreOrganizations()
        await exploreCourses()
        await exploreResources()
    }
    
    private func exploreOrganizations() async {
        print("\n🏢 Step 1: Finding ae.studio organization...")
        let endpoint = "/ims/oneroster/rostering/v1p2/orgs"
        
        await makeAPICall(endpoint: endpoint, description: "Organizations") { data in
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let orgs = json["orgs"] as? [[String: Any]] {
                
                print("Found \(orgs.count) organizations:")
                for org in orgs.prefix(10) {
                    if let name = org["name"] as? String,
                       let sourcedId = org["sourcedId"] as? String {
                        print("  - \(name) (ID: \(sourcedId))")
                        if name.lowercased().contains("ae.studio") || name.lowercased().contains("aestudio") {
                            print("    ⭐ POTENTIAL MATCH!")
                        }
                    }
                }
            }
        }
    }
    
    private func exploreCourses() async {
        print("\n📚 Step 2: Searching for language/grade content...")
        
        // Try different search strategies
        let searchQueries = [
            ("language", "/ims/oneroster/rostering/v1p2/courses?limit=100"),
            ("grade 3", "/ims/oneroster/rostering/v1p2/courses?limit=100"),
            ("all courses", "/ims/oneroster/rostering/v1p2/courses?limit=50")
        ]
        
        for (description, endpoint) in searchQueries {
            print("\n🔎 Searching for: \(description)")
            
            await makeAPICall(endpoint: endpoint, description: description) { data in
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let courses = json["courses"] as? [[String: Any]] {
                    
                    print("Found \(courses.count) courses")
                    
                    // Look for language/grade-related courses
                    let relevantCourses = courses.filter { course in
                        guard let title = course["title"] as? String else { return false }
                        let titleLower = title.lowercased()
                        return titleLower.contains("language") || 
                               titleLower.contains("grade") || 
                               titleLower.contains("3rd") ||
                               titleLower.contains("elementary") ||
                               titleLower.contains("reading") ||
                               titleLower.contains("english")
                    }
                    
                    if !relevantCourses.isEmpty {
                        print("🎯 Relevant courses found:")
                        for course in relevantCourses.prefix(5) {
                            if let title = course["title"] as? String,
                               let id = course["sourcedId"] as? String {
                                print("  - \(title) (ID: \(id))")
                            }
                        }
                    } else {
                        print("📋 Sample course titles:")
                        for course in courses.prefix(5) {
                            if let title = course["title"] as? String {
                                print("  - \(title)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func exploreResources() async {
        print("\n📦 Step 3: Exploring resources...")
        let endpoint = "/ims/oneroster/rostering/v1p2/resources?limit=50"
        
        await makeAPICall(endpoint: endpoint, description: "Resources") { data in
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let resources = json["resources"] as? [[String: Any]] {
                
                print("Found \(resources.count) resources")
                
                // Look for language/educational resources
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
                    for resource in relevantResources.prefix(5) {
                        if let title = resource["title"] as? String,
                           let id = resource["sourcedId"] as? String {
                            print("  - \(title) (ID: \(id))")
                        }
                    }
                } else {
                    print("📋 Sample resource titles:")
                    for resource in resources.prefix(5) {
                        if let title = resource["title"] as? String {
                            print("  - \(title)")
                        }
                    }
                }
            }
        }
    }
    
    private func makeAPICall(endpoint: String, description: String, handler: @escaping (Data) -> Void) async {
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ Invalid URL: \(baseURL + endpoint)")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Note: This would need proper OAuth token in real implementation
        // For now, we'll try without auth to see what's publicly available
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 \(description): HTTP \(httpResponse.statusCode)")
                
                if (200...299).contains(httpResponse.statusCode) {
                    handler(data)
                } else if httpResponse.statusCode == 401 {
                    print("🔐 Authentication required - this confirms the endpoint exists")
                } else {
                    print("❌ Error response")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("Error: \(errorString.prefix(200))")
                    }
                }
            }
        } catch {
            print("❌ Network error for \(description): \(error)")
        }
    }
}

// Run the explorer
Task {
    let explorer = TimeBackExplorer()
    await explorer.run()
    print("\n✅ Exploration complete!")
    print("\n💡 Next steps:")
    print("1. Use valid OAuth token from your app")
    print("2. Query specific course IDs found above")
    print("3. Examine PowerPath syllabi for content structure")
    print("4. Look for QTI resources within courses")
}