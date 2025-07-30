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
request.timeoutInterval = 10.0

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
    if let error = error {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }
    
    guard let data = data,
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        print("❌ Could not parse JSON")
        exit(1)
    }
    
    // Navigate to unitChildren
    if let data = json["data"] as? [String: Any],
       let contentRoute = data["contentRoute"] as? [String: Any],
       let listedPathData = contentRoute["listedPathData"] as? [String: Any],
       let course = listedPathData["course"] as? [String: Any],
       let unitChildren = course["unitChildren"] as? [[String: Any]] {
        
        // Look at the first unit's structure
        if let firstUnit = unitChildren.first {
            print("🔍 First unit structure:")
            for (key, value) in firstUnit {
                if key == "allOrderedChildren" {
                    if let children = value as? [[String: Any]] {
                        print("  \(key): [\(children.count) children]")
                        // Print first child structure 
                        if let firstChild = children.first {
                            print("    First child keys: \(Array(firstChild.keys))")
                            for (childKey, childValue) in firstChild {
                                if childKey == "contentKind" {
                                    print("      \(childKey): \(childValue)")
                                }
                            }
                        }
                    } else {
                        print("  \(key): \(type(of: value))")
                    }
                } else {
                    print("  \(key): \(type(of: value))")
                }
            }
        }
    }
    
    exit(0)
}

task.resume()
RunLoop.main.run()