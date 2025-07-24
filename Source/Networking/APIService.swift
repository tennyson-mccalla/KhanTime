import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case custom(String)
}

class APIService {

    static let shared = APIService()

    private init() {}

    /// Makes a generic network request.
    func request<T: Decodable>(
        baseURL: String,
        endpoint: String,
        method: String = "GET",
        params: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> T {

        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        if let params = params {
            urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Get a valid access token (will refresh if needed)
        if let accessToken = try await AuthService.shared.getValidAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                // Handle non-2xx responses
                let errorData = String(data: data, encoding: .utf8) ?? "No error data"
                print("API Error Response: \(errorData)")
                throw APIError.invalidResponse
            }

            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            return decodedObject

        } catch let error as DecodingError {
            print("Decoding Error: \(error)")
            throw APIError.decodingError(error)
        } catch {
            print("Request Error: \(error)")
            throw APIError.requestFailed(error)
        }
    }
}
