import Foundation
import Combine

@MainActor
class QTIViewModel: ObservableObject {

    @Published var qtiURL: URL?
    @Published var lastResponse: String?
    @Published var isLoadingURL = false
    @Published var urlError: String?

    let resource: ComponentResource
    private let qtiService: QTIService

    init(resource: ComponentResource, qtiService: QTIService = QTIService()) {
        self.resource = resource
        self.qtiService = qtiService
        
        // Start with the legacy URL format, then try to find a valid one
        self.qtiURL = buildLegacyURL()
        
        // Asynchronously try to find a valid URL
        Task {
            await findValidQTIURL()
        }
    }

    private func buildLegacyURL() -> URL? {
        // The legacy identifier format - this may return 404
        let qtiBaseURL = "https://alpha-powerpath-ui-production.up.railway.app/qti-embed/"
        let identifier = resource.resource.sourcedId
        return URL(string: qtiBaseURL + identifier)
    }
    
    private func findValidQTIURL() async {
        isLoadingURL = true
        urlError = nil
        
        do {
            if let validURL = try await qtiService.findValidQTIURL(for: resource) {
                qtiURL = validURL
                urlError = nil
                print("✅ Found valid QTI URL: \(validURL.absoluteString)")
            } else {
                urlError = "No valid QTI URL found for this assessment"
                print("❌ No valid QTI URL found for resource: \(resource.resource.sourcedId)")
            }
        } catch {
            urlError = error.localizedDescription
            print("❌ Error finding valid QTI URL: \(error)")
        }
        
        isLoadingURL = false
    }
    
    /// Retry finding a valid QTI URL
    func retryFindingURL() {
        Task {
            await findValidQTIURL()
        }
    }

    /// This function is called by the view when a response is received from the web view.
    func handleResponse(identifier: String, response: Any) {
        // For now, we'll just log the response.
        // In the future, this is where we would send the answer to the PowerPath API.
        let responseString = "Received response for '\(identifier)': \(response)"
        print(responseString)
        self.lastResponse = responseString
    }
}
