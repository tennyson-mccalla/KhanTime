import SwiftUI

@main
struct KhanTimeApp: App {
    @StateObject private var themePreference = ThemePreference()

    var body: some Scene {
        WindowGroup {
            // Start with the immersive HeroLandingView inspired by modern web design
            // It will handle the presentation of the main DashboardView upon successful authentication.
            HeroLandingView()
                .environmentObject(themePreference)
                .themedWithPreference(themePreference)
        }
    }
}
