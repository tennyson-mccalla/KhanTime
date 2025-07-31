import SwiftUI

// MARK: - KidsTheme Dark Mode Extension
extension KidsTheme {
    
    // MARK: - Custom Dark Mode Colors for Kids (K-2)
    var darkPrimaryColor: Color { 
        Color(red: 0.4, green: 0.7, blue: 1.0) // Brighter, softer blue for dark mode
    }
    
    var darkSecondaryColor: Color { 
        Color(red: 0.95, green: 0.5, blue: 0.95) // Lighter, more visible purple for dark mode
    }
    
    var darkAccentColor: Color { 
        Color(red: 1.0, green: 0.7, blue: 0.3) // Slightly brighter orange that pops in dark mode
    }
    
    var darkBackgroundColor: Color { 
        Color(red: 0.08, green: 0.08, blue: 0.12) // Very dark blue-tinted background
    }
    
    var darkSurfaceColor: Color { 
        Color(red: 0.12, green: 0.12, blue: 0.16) // Slightly lighter surface with blue tint
    }
}