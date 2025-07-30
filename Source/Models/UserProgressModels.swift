import Foundation

// MARK: - User Progress & XP System

struct UserProfile: Codable {
    let id: String
    var username: String
    var totalXP: Int
    var currentLevel: Int
    var currentStreak: Int
    var longestStreak: Int
    var lessonsCompleted: Int
    var totalStudyTime: TimeInterval
    var achievements: [Achievement]
    var lastStudyDate: Date?
    var lessonHistory: [UserLessonRecord]
    
    init(username: String) {
        self.id = UUID().uuidString
        self.username = username
        self.totalXP = 0
        self.currentLevel = 1
        self.currentStreak = 0
        self.longestStreak = 0
        self.lessonsCompleted = 0
        self.totalStudyTime = 0
        self.achievements = []
        self.lastStudyDate = nil
        self.lessonHistory = []
    }
    
    // Calculate level from XP using Khan Academy-like curve
    var calculatedLevel: Int {
        // Level curve: 100 XP for level 2, 150 for level 3, 200 for level 4, etc.
        var xpNeeded = 0
        var level = 1
        
        while xpNeeded < totalXP {
            level += 1
            xpNeeded += (50 + (level * 25)) // Increasing XP requirements
        }
        
        return max(1, level - 1)
    }
    
    // XP needed for next level
    var xpForNextLevel: Int {
        let nextLevel = calculatedLevel + 1
        return (50 + (nextLevel * 25))
    }
    
    // XP progress towards next level
    var xpProgressToNextLevel: Int {
        let currentLevelXP = totalXPForLevel(calculatedLevel)
        return totalXP - currentLevelXP
    }
    
    private func totalXPForLevel(_ level: Int) -> Int {
        var total = 0
        for l in 2...level {
            total += (50 + (l * 25))
        }
        return total
    }
    
    mutating func addXP(_ xp: Int) {
        let oldLevel = calculatedLevel
        totalXP += xp
        currentLevel = calculatedLevel
        
        // Check for level up achievements
        if currentLevel > oldLevel {
            unlockAchievement(.levelUp(currentLevel))
        }
    }
    
    mutating func completeLesson(_ lesson: UserLessonRecord) {
        lessonHistory.append(lesson)
        lessonsCompleted += 1
        totalStudyTime += lesson.timeSpent
        
        // Update streak
        updateStreak()
        
        // Add XP
        addXP(lesson.xpEarned)
        
        // Check for achievements
        checkAchievements()
    }
    
    private mutating func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = lastStudyDate {
            let lastStudyDay = Calendar.current.startOfDay(for: lastDate)
            let daysBetween = Calendar.current.dateComponents([.day], from: lastStudyDay, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysBetween > 1 {
                // Streak broken
                currentStreak = 1
            }
            // Same day = no change to streak
        } else {
            // First lesson ever
            currentStreak = 1
        }
        
        lastStudyDate = Date()
        longestStreak = max(longestStreak, currentStreak)
    }
    
    private mutating func checkAchievements() {
        // Lesson milestones
        if lessonsCompleted == 1 { unlockAchievement(.firstLesson) }
        if lessonsCompleted == 10 { unlockAchievement(.tenLessons) }
        if lessonsCompleted == 50 { unlockAchievement(.fiftyLessons) }
        
        // Streak achievements
        if currentStreak == 3 { unlockAchievement(.threeDay) }
        if currentStreak == 7 { unlockAchievement(.weekStreak) }
        if currentStreak == 30 { unlockAchievement(.monthStreak) }
        
        // XP milestones
        if totalXP >= 1000 { unlockAchievement(.xpMilestone(1000)) }
        if totalXP >= 5000 { unlockAchievement(.xpMilestone(5000)) }
        if totalXP >= 10000 { unlockAchievement(.xpMilestone(10000)) }
        
        // Perfect scores
        let perfectScores = lessonHistory.filter { $0.scorePercentage >= 0.95 }.count
        if perfectScores == 5 { unlockAchievement(.perfectionist) }
    }
    
    private mutating func unlockAchievement(_ achievementType: AchievementType) {
        if !achievements.contains(where: { $0.type == achievementType }) {
            achievements.append(Achievement(type: achievementType, unlockedDate: Date()))
        }
    }
}

struct UserLessonRecord: Codable, Identifiable {
    let id: String
    let lessonId: String
    let lessonTitle: String
    let subject: String
    let completedDate: Date
    let timeSpent: TimeInterval
    let score: Int
    let totalPossible: Int
    let xpEarned: Int
    
    var scorePercentage: Double {
        guard totalPossible > 0 else { return 0 }
        return Double(score) / Double(totalPossible)
    }
    
    init(lesson: InteractiveLesson, score: Int, totalPossible: Int, timeSpent: TimeInterval, xpEarned: Int) {
        self.id = UUID().uuidString
        self.lessonId = lesson.id
        self.lessonTitle = lesson.title
        self.subject = "General" // TODO: Get subject from parent hierarchy
        self.completedDate = Date()
        self.score = score
        self.totalPossible = totalPossible
        self.timeSpent = timeSpent
        self.xpEarned = xpEarned
    }
}

// MARK: - Achievements System

struct Achievement: Codable, Identifiable {
    let id: String
    let type: AchievementType
    let unlockedDate: Date
    
    var title: String { type.title }
    var description: String { type.description }
    var iconName: String { type.iconName }
    var color: String { type.colorName }
    
    init(type: AchievementType, unlockedDate: Date) {
        self.id = UUID().uuidString
        self.type = type
        self.unlockedDate = unlockedDate
    }
}

enum AchievementType: Codable, Equatable {
    case firstLesson
    case tenLessons
    case fiftyLessons
    case threeDay
    case weekStreak
    case monthStreak
    case levelUp(Int)
    case xpMilestone(Int)
    case perfectionist
    case speedster // Complete lesson in under 30 seconds
    case scholar // Study for 1 hour total
    
    var title: String {
        switch self {
        case .firstLesson: return "First Steps"
        case .tenLessons: return "Getting Started"
        case .fiftyLessons: return "Dedicated Learner"
        case .threeDay: return "Building Habits"
        case .weekStreak: return "Week Warrior"
        case .monthStreak: return "Consistency Champion"
        case .levelUp(let level): return "Level \(level) Reached!"
        case .xpMilestone(let xp): return "\(xp) XP Milestone"
        case .perfectionist: return "Perfectionist"
        case .speedster: return "Speed Demon"
        case .scholar: return "Scholar"
        }
    }
    
    var description: String {
        switch self {
        case .firstLesson: return "Complete your first lesson"
        case .tenLessons: return "Complete 10 lessons"
        case .fiftyLessons: return "Complete 50 lessons"
        case .threeDay: return "Study for 3 days in a row"
        case .weekStreak: return "Study for 7 days in a row"
        case .monthStreak: return "Study for 30 days in a row"
        case .levelUp(let level): return "Reached level \(level)"
        case .xpMilestone(let xp): return "Earned \(xp) total XP"
        case .perfectionist: return "Get perfect scores on 5 lessons"
        case .speedster: return "Complete a lesson in under 30 seconds"
        case .scholar: return "Study for 1 hour total"
        }
    }
    
    var iconName: String {
        switch self {
        case .firstLesson: return "star.fill"
        case .tenLessons: return "10.circle.fill"
        case .fiftyLessons: return "50.circle.fill"
        case .threeDay: return "flame.fill"
        case .weekStreak: return "flame.fill"
        case .monthStreak: return "crown.fill"
        case .levelUp: return "arrow.up.circle.fill"
        case .xpMilestone: return "star.circle.fill"
        case .perfectionist: return "target"
        case .speedster: return "bolt.fill"
        case .scholar: return "book.fill"
        }
    }
    
    var colorName: String {
        switch self {
        case .firstLesson: return "blue"
        case .tenLessons, .fiftyLessons: return "green"
        case .threeDay, .weekStreak: return "orange"
        case .monthStreak: return "red"
        case .levelUp: return "purple"
        case .xpMilestone: return "yellow"
        case .perfectionist: return "pink"
        case .speedster: return "cyan"
        case .scholar: return "brown"
        }
    }
}

// MARK: - Progress Manager Service

class ProgressManager: ObservableObject {
    @Published var userProfile: UserProfile
    
    private let userDefaultsKey = "KhanTimeUserProfile"
    
    init() {
        // Load from UserDefaults or create new profile
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = profile
        } else {
            self.userProfile = UserProfile(username: "Student")
        }
    }
    
    func completeLesson(_ lesson: InteractiveLesson, score: Int, totalPossible: Int, timeSpent: TimeInterval) {
        let xpEarned = calculateXP(score: score, totalPossible: totalPossible, timeSpent: timeSpent)
        let completedLesson = UserLessonRecord(
            lesson: lesson,
            score: score,
            totalPossible: totalPossible,
            timeSpent: timeSpent,
            xpEarned: xpEarned
        )
        
        userProfile.completeLesson(completedLesson)
        saveProfile()
    }
    
    private func calculateXP(score: Int, totalPossible: Int, timeSpent: TimeInterval) -> Int {
        let baseXP = 50
        
        // Safety check: Handle division by zero and invalid values
        let scorePercentage: Double
        if totalPossible <= 0 {
            scorePercentage = 0.0  // No points possible = 0% score
        } else {
            scorePercentage = Double(score) / Double(totalPossible)
        }
        
        // Safety check: Handle NaN or infinite values
        let safePercentage = scorePercentage.isNaN || scorePercentage.isInfinite ? 0.0 : scorePercentage
        let performanceBonus = Int(safePercentage * 100) // Up to 100 bonus XP
        
        // Time bonus: faster completion = more XP (but not too punishing)
        let timeBonus: Int
        if timeSpent < 60 { timeBonus = 25 }
        else if timeSpent < 120 { timeBonus = 15 }
        else if timeSpent < 300 { timeBonus = 10 }
        else { timeBonus = 5 }
        
        return baseXP + performanceBonus + timeBonus
    }
    
    private func saveProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func resetProgress() {
        userProfile = UserProfile(username: userProfile.username)
        saveProfile()
    }
}