#!/usr/bin/env swift

import Foundation

// Test JSON structure from our file
struct ScrapedSubjectContent: Codable {
    let id: String
    let subject: String
    let title: String
    let description: String
    let units: [ScrapedUnit]
    let scrapedAt: Date
    
    struct ScrapedUnit: Codable {
        let id: String
        let title: String
        let description: String?
        let lessons: [ScrapedLesson]
        let exercises: [ScrapedExercise]
        
        struct ScrapedLesson: Codable {
            let id: String
            let title: String
            let description: String
            let contentKind: String
            let duration: Int?
            let lessonSteps: [ScrapedLessonStep]
            
            struct ScrapedLessonStep: Codable {
                let id: String
                let title: String
                let description: String
                let type: String
                let youtubeUrl: String?
            }
        }
        
        struct ScrapedExercise: Codable {
            let id: String
            let title: String
            let description: String
        }
    }
}

print("🧪 Testing JSON loading...")

do {
    let filePath = "/Users/Tennyson/KhanTime/Source/Resources/pre-algebra_final_complete_1753900384.json"
    let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
    
    print("✅ File loaded: \(data.count) bytes")
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    let content = try decoder.decode(ScrapedSubjectContent.self, from: data)
    
    print("✅ JSON decoded successfully!")
    print("📊 Subject: \(content.title)")
    print("📊 Units: \(content.units.count)")
    print("📊 First unit: \(content.units.first?.title ?? "none")")
    print("📊 First lesson: \(content.units.first?.lessons.first?.title ?? "none")")
    
} catch {
    print("❌ Error: \(error)")
    
    if let decodingError = error as? DecodingError {
        switch decodingError {
        case .keyNotFound(let key, let context):
            print("🔍 Missing key: \(key.stringValue)")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Path: \(context.codingPath)")
        case .typeMismatch(let type, let context):
            print("🔍 Type mismatch: expected \(type)")
            print("🔍 Context: \(context.debugDescription)")
        case .valueNotFound(let type, let context):
            print("🔍 Value not found: \(type)")
            print("🔍 Context: \(context.debugDescription)")
        case .dataCorrupted(let context):
            print("🔍 Data corrupted: \(context.debugDescription)")
        @unknown default:
            print("🔍 Unknown decoding error")
        }
    }
}