#!/usr/bin/env swift

import Foundation

print("🔍 Testing Khan Academy GraphQL endpoint...")

let baseURL = "https://www.khanacademy.org"
let path = "math/pre-algebra"

// Build the GraphQL request exactly like the scraper does
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

print("📍 URL: \(urlComponents.url!)")
print("📍 Variables: \(variablesString)")

var request = URLRequest(url: urlComponents.url!)
request.httpMethod = "GET"
request.timeoutInterval = 10.0

// Add headers
let headers = [
    "Accept": "*/*",
    "Sec-Fetch-Site": "same-origin",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br",
    "Sec-Fetch-Mode": "cors",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15",
    "Sec-Fetch-Dest": "empty",
    "x-ka-fkey": "1",
    "Priority": "u=3, i",
    "Referer": "\(baseURL)/\(path)"
]

for (key, value) in headers {
    request.setValue(value, forHTTPHeaderField: key)
}

let session = URLSession.shared

print("📡 Making request...")

let task = session.dataTask(with: request) { data, response, error in
    if let error = error {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response")
        exit(1)
    }
    
    print("✅ HTTP Status: \(httpResponse.statusCode)")
    
    if let data = data {
        print("📊 Response size: \(data.count) bytes")
        
        if let responseString = String(data: data, encoding: .utf8) {
            let preview = String(responseString.prefix(500))
            print("📄 Response preview: \(preview)")
            
            // Check if it looks like Khan Academy returned data
            if responseString.contains("unitChildren") {
                print("🎯 Found unitChildren in response!")
            } else {
                print("⚠️ No unitChildren found in response")
            }
        }
    }
    
    exit(0)
}

task.resume()

// Keep the script running
RunLoop.main.run()