import SwiftUI

@main
struct KhanTimeApp: App {
    var body: some Scene {
        WindowGroup {
            // Start with the LoginView.
            // It will handle the presentation of the main ContentView upon successful authentication.
            LoginView()
        }
    }
}
