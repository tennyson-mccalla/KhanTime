import Foundation

class AuthService {

    static let shared = AuthService()

    private var accessToken: String?
    private var tokenExpirationDate: Date?

    private init() {}

    /// Get the current access token if valid
    func getValidAccessToken() async throws -> String? {
        print("🔐 AuthService: Checking token validity...")
        
        if let token = accessToken {
            print("🔐 Current token exists: \(String(token.prefix(20)))...")
        } else {
            print("🔐 No current token stored")
        }
        
        if let expiration = tokenExpirationDate {
            print("🔐 Token expires at: \(expiration)")
            print("🔐 Current time: \(Date())")
        } else {
            print("🔐 No expiration date stored")
        }
        
        let tokenIsValid = isTokenValid()
        print("🔐 Token is valid: \(tokenIsValid)")
        
        if !tokenIsValid {
            print("🔐 Token invalid, authenticating...")
            try await authenticate()
        } else {
            print("🔐 Using existing valid token")
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
        let fullAuthUrl = APIConstants.authBaseURL + endpoint
        
        print("🔐 AuthService: Starting authentication...")
        print("🔐 Auth URL: \(fullAuthUrl)")
        print("🔐 Client ID: \(Credentials.clientID)")
        print("🔐 Environment: \(Credentials.environment)")

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: Credentials.clientID),
            URLQueryItem(name: "client_secret", value: Credentials.clientSecret)
        ]

        // The body needs to be x-www-form-urlencoded
        let body = components.query?.data(using: .utf8)

        var request = URLRequest(url: URL(string: fullAuthUrl)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        do {
            print("🔐 Making auth request...")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ No HTTP response")
                throw APIError.invalidResponse
            }
            
            print("🔐 Auth response status: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                let errorData = String(data: data, encoding: .utf8) ?? "No error data"
                print("❌ Auth Error Response: \(errorData)")
                throw APIError.invalidResponse
            }

            let tokenResponse = try JSONDecoder().decode(AuthTokenResponse.self, from: data)

            // Store the access token and expiration date
            self.accessToken = tokenResponse.accessToken
            self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

            print("✅ Successfully authenticated. Token expires at: \(tokenExpirationDate!)")
            print("🔐 Token preview: \(String(tokenResponse.accessToken.prefix(20)))...")

        } catch {
            print("❌ Authentication failed: \(error)")
            throw error
        }
    }
}
