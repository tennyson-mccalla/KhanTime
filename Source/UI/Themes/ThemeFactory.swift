import SwiftUI

/// Factory for creating age-appropriate themes
enum ThemeFactory {
    /// Returns the appropriate theme for a given age group
    static func theme(for ageGroup: AgeGroup) -> ThemeProvider {
        switch ageGroup {
        case .k2:
            // K-2 uses the Kids theme
            return KidsTheme()
        case .g35:
            // 3-5 uses the Elementary theme
            return ElementaryTheme()
        case .g68:
            // 6-8 uses the Middle School theme
            return MiddleTheme()
        case .g912:
            // 9-12 uses the High School theme
            return HighSchoolTheme()
        }
    }

    /// Returns theme based on grade string
    static func theme(for grade: String) -> ThemeProvider {
        // Determine age group from grade
        let ageGroup = ageGroup(for: grade)
        return theme(for: ageGroup)
    }

    /// Converts a grade string to an age group
    static func ageGroup(for grade: String) -> AgeGroup {
        switch grade.uppercased() {
        case "K", "1", "2":
            return .k2
        case "3", "4", "5":
            return .g35
        case "6", "7", "8":
            return .g68
        case "9", "10", "11", "12":
            return .g912
        default:
            // Default to middle school for unknown grades
            return .g68
        }
    }

    /// Returns all available themes for preview/testing
    static var allThemes: [ThemeProvider] {
        [KidsTheme(), ElementaryTheme(), MiddleTheme(), HighSchoolTheme()]
    }
}

// MARK: - Theme Selection Storage
/// Stores the user's theme preference
class ThemePreference: ObservableObject {
    @Published var selectedAgeGroup: AgeGroup {
        didSet {
            UserDefaults.standard.set(selectedAgeGroup.rawValue, forKey: "selectedAgeGroup")
            // Update the current theme when age group changes
            currentTheme = ThemeFactory.theme(for: selectedAgeGroup)
        }
    }

    @Published var currentTheme: ThemeProvider

    init() {
        // Load saved preference or default to K-2
        if let savedAgeGroup = UserDefaults.standard.string(forKey: "selectedAgeGroup"),
           let ageGroup = AgeGroup(rawValue: savedAgeGroup) {
            self.selectedAgeGroup = ageGroup
            self.currentTheme = ThemeFactory.theme(for: ageGroup)
        } else {
            self.selectedAgeGroup = .k2
            self.currentTheme = KidsTheme()
        }
    }

    /// Updates the theme based on age group
    func updateTheme(for ageGroup: AgeGroup) {
        selectedAgeGroup = ageGroup
        currentTheme = ThemeFactory.theme(for: ageGroup)
    }

    /// Updates theme based on grade string
    func updateTheme(for grade: String) {
        let ageGroup = ThemeFactory.ageGroup(for: grade)
        updateTheme(for: ageGroup)
    }
}

// MARK: - Environment Integration
extension View {
    /// Applies theme based on user preference
    func themedWithPreference(_ preference: ThemePreference) -> some View {
        self.themed(with: preference.currentTheme)
    }
}
