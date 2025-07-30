import SwiftUI

struct QTIView: View {
    
    @StateObject private var viewModel: QTIViewModel
    
    init(resource: ComponentResource) {
        _viewModel = StateObject(wrappedValue: QTIViewModel(resource: resource))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoadingURL {
                // Loading state
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Finding valid assessment URL...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if let error = viewModel.urlError {
                // Error state with retry option
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Assessment Not Available")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Try Again") {
                        viewModel.retryFindingURL()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // Show current URL being attempted for debugging
                    if let url = viewModel.qtiURL {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Debug Info:")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Text("Resource ID: \(viewModel.resource.resource.sourcedId)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("URL: \(url.absoluteString)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if let url = viewModel.qtiURL {
                // Success state - display the QTI web view
                QTIWebView(url: url, onResponseReceived: { identifier, response in
                    viewModel.handleResponse(identifier: identifier, response: response)
                })
                
            } else {
                // Fallback error state
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("Assessment Unavailable")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("This assessment cannot be loaded at this time.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // For debugging, display the last response received.
            if let lastResponse = viewModel.lastResponse {
                Text(lastResponse)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                    .padding(.horizontal)
            }
        }
        .navigationTitle(viewModel.resource.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
