import Foundation

class AuthService {

    static let shared = AuthService()

    private var accessToken: String?
    private var tokenExpirationDate: Date?

    private init() {}

    /// Get the current access token if valid
    func getValidAccessToken() async throws -> String? {
        if !isTokenValid() {
            try await authenticate()
        }
        return accessToken
    }

    /// Checks if the current token is still valid
    private func isTokenValid() -> Bool {
        guard let expirationDate = tokenExpirationDate else { return false }
        // Add a 30-second buffer to avoid edge cases
        return Date().addingTimeInterval(30) < expirationDate
    }

    /// Authenticates with the backend to get a machine-to-machine access token.
    func authenticate() async throws {
        let endpoint = APIConstants.oauthTokenEndpoint

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: Credentials.clientID),
            URLQueryItem(name: "client_secret", value: Credentials.clientSecret)
        ]

        // The body needs to be x-www-form-urlencoded
        let body = components.query?.data(using: .utf8)

        var request = URLRequest(url: URL(string: APIConstants.authBaseURL + endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let errorData = String(data: data, encoding: .utf8) ?? "No error data"
                print("Auth Error Response: \(errorData)")
                throw APIError.invalidResponse
            }

            let tokenResponse = try JSONDecoder().decode(AuthTokenResponse.self, from: data)

            // Store the access token and expiration date
            self.accessToken = tokenResponse.accessToken
            self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

            print("Successfully authenticated. Token expires at: \(tokenExpirationDate!)")

        } catch {
            print("Authentication failed: \(error)")
            throw error
        }
    }
}
