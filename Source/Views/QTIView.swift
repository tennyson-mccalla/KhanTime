import SwiftUI

struct QTIView: View {
    
    @StateObject private var viewModel: QTIViewModel
    
    init(resource: ComponentResource) {
        _viewModel = StateObject(wrappedValue: QTIViewModel(resource: resource))
    }
    
    var body: some View {
        VStack {
            if let url = viewModel.qtiURL {
                // Display the QTI web view and connect its response handler to our view model.
                QTIWebView(url: url, onResponseReceived: { identifier, response in
                    viewModel.handleResponse(identifier: identifier, response: response)
                })
            } else {
                Text("Invalid QTI URL.")
                    .foregroundColor(.red)
            }
            
            // For debugging, display the last response received.
            if let lastResponse = viewModel.lastResponse {
                Text(lastResponse)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .navigationTitle(viewModel.resource.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
