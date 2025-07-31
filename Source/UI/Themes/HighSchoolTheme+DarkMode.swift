import SwiftUI

// MARK: - HighSchoolTheme Dark Mode Extension
extension HighSchoolTheme {
    
    // MARK: - Custom Dark Mode Colors for High School (9-12)
    var darkPrimaryColor: Color { 
        Color(red: 0.9, green: 0.9, blue: 0.95) // Very light gray-white for text
    }
    
    var darkSecondaryColor: Color { 
        Color(red: 0.7, green: 0.7, blue: 0.75) // Medium gray for secondary text
    }
    
    var darkAccentColor: Color { 
        Color(red: 0.3, green: 0.7, blue: 1.0) // Professional blue accent
    }
    
    var darkBackgroundColor: Color { 
        Color(red: 0.05, green: 0.05, blue: 0.08) // Very dark, almost black background
    }
    
    var darkSurfaceColor: Color { 
        Color(red: 0.1, green: 0.1, blue: 0.13) // Dark surface with subtle blue tint
    }
}