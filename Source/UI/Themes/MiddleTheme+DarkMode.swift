import SwiftUI

// MARK: - MiddleTheme Dark Mode Extension
extension MiddleTheme {
    
    // MARK: - Custom Dark Mode Colors for Middle School (6-8)
    var darkPrimaryColor: Color { 
        Color(red: 0.4, green: 0.6, blue: 1.0) // Modern blue that works well in dark mode
    }
    
    var darkSecondaryColor: Color { 
        Color(red: 0.6, green: 0.8, blue: 0.9) // Lighter blue-gray for secondary content
    }
    
    var darkAccentColor: Color { 
        Color(red: 0.2, green: 0.9, blue: 0.7) // Bright cyan-teal accent
    }
    
    var darkBackgroundColor: Color { 
        Color(red: 0.08, green: 0.1, blue: 0.12) // Cool dark background
    }
    
    var darkSurfaceColor: Color { 
        Color(red: 0.12, green: 0.14, blue: 0.16) // Slightly lighter surface
    }
}