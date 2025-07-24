import Foundation

/// Protocol defining the contract for progress tracking systems
/// Supports Alpha School's 2-hour learning methodology
protocol ProgressTracker {
    /// Record progress for a specific lesson
    func recordProgress(lessonId: String, score: Double, timeSpent: TimeInterval) async throws

    /// Get overall progress for a course
    func getProgress(courseId: String) async throws -> CourseProgress

    /// Get today's learning session status
    func getTodaySession() async throws -> LearningSession

    /// Start a new learning session
    func startSession(courseId: String) async throws -> LearningSession

    /// End the current learning session
    func endSession(_ session: LearningSession) async throws

    /// Get learning efficiency metrics
    func getEfficiencyMetrics(for userId: String) async throws -> EfficiencyMetrics

    /// Suggest the next lesson based on progress and time remaining
    func suggestNextLesson(for courseId: String) async throws -> Lesson?

    /// Check if daily learning goal is met
    func isDailyGoalMet() async throws -> Bool

    /// Provider name for debugging
    var trackerName: String { get }
}

// MARK: - Progress Models

/// Overall progress for a course
struct CourseProgress: Identifiable {
    let id: String
    let courseId: String
    let userId: String
    let completedLessons: [String]
    let currentLessonId: String?
    let totalTimeSpent: TimeInterval
    let averageScore: Double
    let lastAccessDate: Date
    let completionPercentage: Double
}

/// Learning session following 2-hour methodology
struct LearningSession: Identifiable {
    let id: String
    let userId: String
    let courseId: String
    let startTime: Date
    var endTime: Date?
    var lessonsCompleted: [CompletedLesson]
    var totalDuration: TimeInterval
    var isActive: Bool

    /// Time remaining in the 2-hour window
    var timeRemaining: TimeInterval {
        let targetDuration: TimeInterval = 2 * 60 * 60 // 2 hours
        return max(0, targetDuration - totalDuration)
    }

    /// Progress towards 2-hour goal (0.0 to 1.0)
    var progressTowardsGoal: Double {
        let targetDuration: TimeInterval = 2 * 60 * 60
        return min(1.0, totalDuration / targetDuration)
    }
}

/// Completed lesson within a session
struct CompletedLesson: Identifiable {
    let id: String
    let lessonId: String
    let startTime: Date
    let endTime: Date
    let score: Double
    let timeSpent: TimeInterval
}

/// Efficiency metrics for adaptive learning
struct EfficiencyMetrics: Identifiable {
    let id: String
    let userId: String
    let averageLessonDuration: TimeInterval
    let averageScore: Double
    let strongSubjects: [String]
    let needsImprovement: [String]
    let learningVelocity: Double // Lessons per hour
    let consistencyScore: Double // 0.0 to 1.0
    let streakDays: Int
}

// MARK: - Alpha School Specific Extensions

extension LearningSession {
    /// Check if session meets Alpha School's efficiency standards
    var meetsEfficiencyStandards: Bool {
        // At least 80% of time should be active learning
        let activePercentage = lessonsCompleted.reduce(0) { $0 + $1.timeSpent } / totalDuration
        return activePercentage >= 0.8
    }

    /// Get recommended break time based on session progress
    var recommendedBreakDuration: TimeInterval {
        // 5-minute break every 30 minutes of learning
        let thirtyMinuteChunks = Int(totalDuration / (30 * 60))
        return TimeInterval(thirtyMinuteChunks * 5 * 60)
    }
}

// MARK: - Progress Persistence Protocol

/// Protocol for persisting progress data locally
protocol ProgressPersistence {
    func save(_ progress: CourseProgress) async throws
    func load(courseId: String) async throws -> CourseProgress?
    func saveSession(_ session: LearningSession) async throws
    func loadActiveSession() async throws -> LearningSession?
    func clearAllData() async throws
}
