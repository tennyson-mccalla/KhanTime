import Foundation

/// Age groups for content filtering and theme selection
enum AgeGroup: String, CaseIterable, Codable {
    case k2 = "K-2"
    case g35 = "3-5"
    case g68 = "6-8"
    case g912 = "9-12"

    var grades: [String] {
        switch self {
        case .k2: return ["K", "1", "2"]
        case .g35: return ["3", "4", "5"]
        case .g68: return ["6", "7", "8"]
        case .g912: return ["9", "10", "11", "12"]
        }
    }
}

/// Unified lesson model that all providers must map to
struct Lesson: Identifiable {
    let id: String
    let title: String
    let duration: TimeInterval // For 2-hour learning tracking
    let ageGroup: AgeGroup
    let components: [LessonComponent]
    let courseId: String
}

/// Types of content components within a lesson
enum LessonComponent: Identifiable {
    case video(VideoContent)
    case article(ArticleContent)
    case exercise(ExerciseContent)
    case quiz(QuizContent)

    var id: String {
        switch self {
        case .video(let content): return content.id
        case .article(let content): return content.id
        case .exercise(let content): return content.id
        case .quiz(let content): return content.id
        }
    }
}

/// Video content model
struct VideoContent: Identifiable {
    let id: String
    let title: String
    let url: URL
    let duration: TimeInterval
    let transcript: String?
}

/// Article/reading content model
struct ArticleContent: Identifiable {
    let id: String
    let title: String
    let markdownContent: String
    let estimatedReadTime: TimeInterval
}

/// Exercise content model
struct ExerciseContent: Identifiable {
    let id: String
    let title: String
    let instructions: String
    let problemSets: [ProblemSet]
}

struct ProblemSet: Identifiable {
    let id: String
    let problems: [Problem]
}

struct Problem: Identifiable {
    let id: String
    let question: String
    let type: ProblemType
}

enum ProblemType {
    case multipleChoice([String])
    case freeResponse
    case numeric
}

/// Quiz content model (QTI-based)
struct QuizContent: Identifiable {
    let id: String
    let title: String
    let qtiUrl: URL
    let timeLimit: TimeInterval?
    let attempts: Int
}
