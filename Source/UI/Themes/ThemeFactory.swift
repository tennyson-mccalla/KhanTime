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
        // Load saved age group preference or default to K-2
        let initialAgeGroup: AgeGroup
        if let savedAgeGroup = UserDefaults.standard.string(forKey: "selectedAgeGroup"),
           let ageGroup = AgeGroup(rawValue: savedAgeGroup) {
            initialAgeGroup = ageGroup
        } else {
            initialAgeGroup = .k2
        }
        
        // Initialize all properties
        self.selectedAgeGroup = initialAgeGroup
        self.currentTheme = ThemeFactory.theme(for: initialAgeGroup)
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

// MARK: - Theme Dynamic Color Extensions
extension ThemeProvider {
    // MARK: - Light Mode Colors (defaults to existing static colors)
    var lightPrimaryColor: Color { primaryColor }
    var lightSecondaryColor: Color { secondaryColor }
    var lightAccentColor: Color { accentColor }
    var lightBackgroundColor: Color { backgroundColor }
    var lightSurfaceColor: Color { surfaceColor }
    
    // MARK: - Dark Mode Colors (basic defaults - should be overridden by individual theme extensions)
    var darkPrimaryColor: Color { 
        lightPrimaryColor.opacity(0.9)
    }
    var darkSecondaryColor: Color { 
        lightSecondaryColor.opacity(0.8)
    }
    var darkAccentColor: Color { 
        lightAccentColor
    }
    var darkBackgroundColor: Color { 
        Color(red: 0.1, green: 0.1, blue: 0.12)
    }
    var darkSurfaceColor: Color { 
        Color(red: 0.15, green: 0.15, blue: 0.18)
    }
}

// MARK: - Environment Integration
extension View {
    /// Applies theme based on user preference
    func themedWithPreference(_ preference: ThemePreference) -> some View {
        self.themed(with: preference.currentTheme)
    }
}
