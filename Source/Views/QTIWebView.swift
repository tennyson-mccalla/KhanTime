import SwiftUI
import WebKit

// This struct wraps a WKWebView, making it usable within a SwiftUI view hierarchy.
// It also sets up a communication bridge to receive messages from the JavaScript content.
struct QTIWebView: UIViewRepresentable {
    
    let url: URL
    
    // This closure will be called whenever the web content sends a message.
    var onResponseReceived: ((String, Any) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        // Configure the web view to allow JavaScript messages to be received.
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "qtiResponseHandler")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Load the URL request when the view is updated.
        let request = URLRequest(url: url)
        uiView.load(request)
    }
    
    // Creates the coordinator object that acts as a delegate for the WKWebView.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // The Coordinator class handles delegate callbacks from the WKWebView.
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: QTIWebView
        
        init(_ parent: QTIWebView) {
            self.parent = parent
        }
        
        // This method is called when the JavaScript in the web page posts a message.
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "qtiResponseHandler", let body = message.body as? [String: Any] {
                // Extract the response data and pass it to our closure.
                if let responseIdentifier = body["responseIdentifier"] as? String,
                   let response = body["response"] {
                    parent.onResponseReceived?(responseIdentifier, response)
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("Failed to load web view: \(error.localizedDescription)")
        }
    }
}
