import Foundation
import Combine

@MainActor
class QTIViewModel: ObservableObject {

    @Published var qtiURL: URL?
    @Published var lastResponse: String?

    let resource: ComponentResource

    // The base URL for the QTI rendering service.
    private let qtiBaseURL = "https://alpha-powerpath-ui-production.up.railway.app/qti-embed/"

    init(resource: ComponentResource) {
        self.resource = resource
        self.qtiURL = buildURL()
    }

    private func buildURL() -> URL? {
        // The identifier for the QTI item is typically the `sourcedId` of the underlying Resource.
        let identifier = resource.resource.sourcedId
        return URL(string: qtiBaseURL + identifier)
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
