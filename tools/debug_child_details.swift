#!/usr/bin/env swift

import Foundation

let baseURL = "https://www.khanacademy.org"
let path = "math/pre-algebra"
let urlString = "\(baseURL)/api/internal/graphql/ContentForPath"
let variables = ["path": path, "countryCode": "US"]
let variablesData = try! JSONSerialization.data(withJSONObject: variables)
let variablesString = String(data: variablesData, encoding: .utf8)!

let params = [
    "fastly_cacheable": "persist_until_publish",
    "pcv": "dd3a92f28329ba421fb048ddfa2c930cbbfbac29",
    "hash": "45296627",
    "variables": variablesString,
    "lang": "en",
    "app": "khanacademy"
]

var urlComponents = URLComponents(string: urlString)!
urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

var request = URLRequest(url: urlComponents.url!)
request.httpMethod = "GET"

let headers = [
    "Accept": "*/*",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15",
    "Referer": "\(baseURL)/\(path)"
]

for (key, value) in headers {
    request.setValue(value, forHTTPHeaderField: key)
}

let session = URLSession.shared

let task = session.dataTask(with: request) { data, response, error in
    guard let data = data,
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let data = json["data"] as? [String: Any],
          let contentRoute = data["contentRoute"] as? [String: Any],
          let listedPathData = contentRoute["listedPathData"] as? [String: Any],
          let course = listedPathData["course"] as? [String: Any],
          let unitChildren = course["unitChildren"] as? [[String: Any]],
          let firstUnit = unitChildren.first,
          let children = firstUnit["allOrderedChildren"] as? [[String: Any]] else {
        print("❌ Could not navigate to children")
        exit(1)
    }
    
    print("🔍 First unit: \(firstUnit["translatedTitle"] ?? "Unknown")")
    print("📊 Children count: \(children.count)")
    
    for (index, child) in children.enumerated() {
        let title = child["translatedTitle"] as? String ?? "Unknown"
        let typename = child["__typename"] as? String ?? "Unknown"
        let id = child["id"] as? String ?? "Unknown"
        
        print("\n📄 Child \(index + 1): \(title)")
        print("  Type: \(typename)")
        print("  ID: \(id)")
        
        // Check if it has curatedChildren (lessons/exercises)
        if let curatedChildren = child["curatedChildren"] as? [[String: Any]] {
            print("  🎯 Has \(curatedChildren.count) curated children")
            for (childIndex, curatedChild) in curatedChildren.enumerated() {
                let childTitle = curatedChild["translatedTitle"] as? String ?? "Unknown"
                let childTypename = curatedChild["__typename"] as? String ?? "Unknown"
                print("    \(childIndex + 1). \(childTitle) (\(childTypename))")
            }
        } else {
            print("  ❌ No curated children")
        }
    }
    
    exit(0)
}

task.resume()
RunLoop.main.run()