#!/usr/bin/env swift

import Foundation

// Load the corrupted file
guard let data = try? Data(contentsOf: URL(fileURLWithPath: "Source/Resources/pre-algebra_complete_15_units.json")),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let units = json["units"] as? [[String: Any]] else {
    print("❌ Failed to load JSON file")
    exit(1)
}

print("📊 Original file has \(units.count) units")

// Take only the first 15 units (Units 1-3 are correct, but Units 4-15 are the wrong ones)
// We need to take Units 1-3 from the first part, and Units 4-15 from the duplicate part

var correctedUnits: [[String: Any]] = []

// Take Units 1-3 (first 3 units)
for i in 0..<3 {
    if i < units.count {
        correctedUnits.append(units[i])
        let title = units[i]["title"] as? String ?? "Unknown"
        print("✅ Keeping Unit \(i + 1): \(title)")
    }
}

// Take Units 4-15 from the later part (units 15-26, which are the corrected duplicates)
for i in 15..<27 {
    if i < units.count {
        correctedUnits.append(units[i])
        let title = units[i]["title"] as? String ?? "Unknown"
        print("✅ Keeping Unit \(correctedUnits.count): \(title)")
    }
}

print("\n📊 Corrected file will have \(correctedUnits.count) units")

// Create corrected JSON
var correctedJson = json
correctedJson["units"] = correctedUnits
correctedJson["scrapedAt"] = ISO8601DateFormatter().string(from: Date())

// Save corrected file
do {
    let correctedData = try JSONSerialization.data(withJSONObject: correctedJson, options: .prettyPrinted)
    try correctedData.write(to: URL(fileURLWithPath: "Source/Resources/pre-algebra_complete_15_units_fixed.json"))
    print("💾 Saved corrected file: Source/Resources/pre-algebra_complete_15_units_fixed.json")
    
    // Also save as the main file
    try correctedData.write(to: URL(fileURLWithPath: "Source/Resources/pre-algebra_complete_15_units.json"))
    print("💾 Overwrote original file with corrected version")
    
} catch {
    print("❌ Error saving corrected file: \(error)")
}