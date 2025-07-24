import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false

    init() {}

    func login() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await AuthService.shared.authenticate()
                // If authentication is successful, we can transition to the main app view.
                self.isAuthenticated = true
            } catch {
                self.errorMessage = "Login Failed. Please check credentials and network connection. Error: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
}
