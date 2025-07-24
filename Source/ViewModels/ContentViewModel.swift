import Foundation

class ContentViewModel: ObservableObject {
    @Published var welcomeMessage: String = "Welcome to KhanTime!"
    
    init() {
        // In the future, we can add logic here to check for authentication
        // and decide whether to show the login screen or the main dashboard.
    }
}
