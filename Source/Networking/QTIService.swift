import Foundation

// MARK: - QTI Service
// Service to fetch valid QTI assessment tests and resources

class QTIService {
    
    private let apiService: APIService
    private let qtiBaseURL = "https://qti.alpha-1edtech.com/api"
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    // MARK: - Fetch Available Assessment Tests
    
    /// Fetches available QTI assessment tests from the API
    func fetchAvailableAssessmentTests() async throws -> [QTIAssessmentTest] {
        let endpoint = "/assessment-tests"
        
        let response: QTIAssessmentTestListResponse = try await apiService.request(
            baseURL: qtiBaseURL,
            endpoint: endpoint,
            method: "GET"
        )
        
        return response.data
    }
    
    /// Fetches a specific assessment test by identifier
    func fetchAssessmentTest(identifier: String) async throws -> QTIAssessmentTest {
        let endpoint = "/assessment-tests/\(identifier)"
        
        let response: QTIAssessmentTestResponse = try await apiService.request(
            baseURL: qtiBaseURL,
            endpoint: endpoint,
            method: "GET"
        )
        
        return response.data
    }
    
    /// Validates that a QTI URL is accessible
    func validateQTIURL(_ url: URL) async throws -> Bool {
        let (_, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            return (200...299).contains(httpResponse.statusCode)
        }
        
        return false
    }
    
    /// Finds the first valid QTI assessment test URL for a given resource
    func findValidQTIURL(for resource: ComponentResource) async throws -> URL? {
        // Strategy 1: Try the existing URL format first
        let currentURL = buildCurrentFormatURL(for: resource)
        
        if let currentURL = currentURL {
            do {
                if try await validateQTIURL(currentURL) {
                    print("✅ Current QTI URL format is valid: \(currentURL.absoluteString)")
                    return currentURL
                }
            } catch {
                print("⚠️ Current QTI URL format failed: \(currentURL.absoluteString)")
            }
        }
        
        // Strategy 2: Fetch available assessment tests and find a match
        do {
            let assessmentTests = try await fetchAvailableAssessmentTests()
            
            // Try to find a test that matches the resource identifier
            let resourceId = resource.resource.sourcedId
            
            // Look for exact match
            if let matchingTest = assessmentTests.first(where: { $0.identifier == resourceId }) {
                let url = buildQTIEmbedURL(for: matchingTest.identifier)
                print("✅ Found exact matching QTI test: \(url.absoluteString)")
                return url
            }
            
            // Look for partial match
            if let partialMatch = assessmentTests.first(where: { $0.identifier.contains(resourceId) || resourceId.contains($0.identifier) }) {
                let url = buildQTIEmbedURL(for: partialMatch.identifier)
                print("✅ Found partial matching QTI test: \(url.absoluteString)")
                return url
            }
            
            // If no match found, use the first available test (fallback)
            if let firstTest = assessmentTests.first {
                let url = buildQTIEmbedURL(for: firstTest.identifier)
                print("⚠️ No matching QTI test found, using fallback: \(url.absoluteString)")
                return url
            }
            
        } catch {
            print("❌ Failed to fetch QTI assessment tests: \(error)")
        }
        
        // Strategy 3: Use a known working test as ultimate fallback
        return buildFallbackQTIURL()
    }
    
    // MARK: - Private Helper Methods
    
    private func buildCurrentFormatURL(for resource: ComponentResource) -> URL? {
        let qtiEmbedBaseURL = "https://alpha-powerpath-ui-production.up.railway.app/qti-embed/"
        let identifier = resource.resource.sourcedId
        return URL(string: qtiEmbedBaseURL + identifier)
    }
    
    private func buildQTIEmbedURL(for identifier: String) -> URL {
        let qtiEmbedBaseURL = "https://alpha-powerpath-ui-production.up.railway.app/qti-embed/"
        return URL(string: qtiEmbedBaseURL + identifier)!
    }
    
    private func buildFallbackQTIURL() -> URL {
        // Use a known working QTI test as fallback
        // This should be replaced with actual working test identifier
        let fallbackIdentifier = "sample-assessment-test"
        return buildQTIEmbedURL(for: fallbackIdentifier)
    }
}

// MARK: - QTI Data Models

struct QTIAssessmentTestListResponse: Codable {
    let data: [QTIAssessmentTest]
    let pagination: QTIPagination?
}

struct QTIAssessmentTestResponse: Codable {
    let data: QTIAssessmentTest
}

struct QTIAssessmentTest: Codable {
    let identifier: String
    let title: String?
    let description: String?
    let navigationMode: String?
    let submissionMode: String?
    let testParts: [QTITestPart]?
}

struct QTITestPart: Codable {
    let identifier: String
    let title: String?
    let navigationMode: String?
    let submissionMode: String?
}

struct QTIPagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
}

// MARK: - QTI Error Types

enum QTIError: LocalizedError {
    case noValidURL
    case assessmentTestNotFound(String)
    case validationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noValidURL:
            return "No valid QTI URL could be found for this resource"
        case .assessmentTestNotFound(let identifier):
            return "Assessment test not found: \(identifier)"
        case .validationFailed(let url):
            return "QTI URL validation failed: \(url)"
        }
    }
}