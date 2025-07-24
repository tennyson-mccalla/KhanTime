import Foundation

struct APIConstants {
    // Base URLs change based on environment
    static var authBaseURL: String {
        switch Credentials.environment {
        case .staging:
            return "https://alpha-auth-development-idp.auth.us-west-2.amazoncognito.com"
        case .production:
            return "https://alpha-auth-production-idp.auth.us-west-2.amazoncognito.com"
        }
    }

    static var apiBaseURL: String {
        switch Credentials.environment {
        case .staging:
            return "https://api.staging.alpha-1edtech.com"
        case .production:
            return "https://api.alpha-1edtech.com"
        }
    }

    // GraphQL/Scalar endpoint for API documentation
    static var scalarEndpoint: String {
        return apiBaseURL + "/scalar"
    }

    // Endpoints
    static let oauthTokenEndpoint = "/oauth2/token"
}
