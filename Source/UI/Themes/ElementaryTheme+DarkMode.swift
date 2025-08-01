import SwiftUI

// MARK: - ElementaryTheme Dark Mode Extension
extension ElementaryTheme {
    
    // MARK: - Custom Dark Mode Colors for Elementary (3-5)
    var darkPrimaryColor: Color { 
        Color(red: 0.3, green: 0.8, blue: 0.6) // Brighter teal-green for dark mode
    }
    
    var darkSecondaryColor: Color { 
        Color(red: 0.5, green: 0.7, blue: 1.0) // Lighter blue for better contrast
    }
    
    var darkAccentColor: Color { 
        Color(red: 1.0, green: 0.8, blue: 0.2) // Bright yellow-orange that stands out
    }
    
    var darkBackgroundColor: Color { 
        Color(red: 0.09, green: 0.11, blue: 0.1) // Dark with slight green tint
    }
    
    var darkSurfaceColor: Color { 
        Color(red: 0.13, green: 0.15, blue: 0.14) // Slightly lighter with green undertone
    }
}