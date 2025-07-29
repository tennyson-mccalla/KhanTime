import SwiftUI
import WebKit

struct InteractiveVideoContentView: View {
    let content: InteractiveVideoContent
    @Environment(\.theme) var theme
    @State private var isLoading = true
    @State private var hasError = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme?.standardSpacing ?? 16) {
            // Video Title
            Text("📹 Khan Academy Video")
                .font(theme?.headingFont ?? .headline)
                .foregroundColor(theme?.primaryColor ?? .primary)
            
            // YouTube Video Player
            ZStack {
                YouTubePlayerView(videoURL: content.videoURL) { loading, error in
                    isLoading = loading
                    hasError = error
                }
                .frame(height: 250)
                .cornerRadius(theme?.cardCornerRadius ?? 12)
                
                // Loading/Error Overlay
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading Khan Academy video...")
                            .font(theme?.captionFont ?? .caption)
                            .foregroundColor(theme?.secondaryColor ?? .secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(theme?.cardCornerRadius ?? 12)
                } else if hasError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(.orange)
                        Text("Unable to load video")
                            .font(theme?.bodyFont ?? .body)
                            .foregroundColor(theme?.primaryColor ?? .primary)
                        Text("Please check your internet connection")
                            .font(theme?.captionFont ?? .caption)
                            .foregroundColor(theme?.secondaryColor ?? .secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme?.surfaceColor ?? Color(.systemBackground))
                    .cornerRadius(theme?.cardCornerRadius ?? 12)
                }
            }
            
            // Video Information
            if !content.videoURL.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(theme?.accentColor ?? .blue)
                        Text("Interactive Khan Academy Content")
                            .font(theme?.bodyFont ?? .body)
                            .foregroundColor(theme?.primaryColor ?? .primary)
                    }
                    
                    Text("Watch this video to learn the key concepts, then continue with the practice exercises.")
                        .font(theme?.captionFont ?? .caption)
                        .foregroundColor(theme?.secondaryColor ?? .secondary)
                        .padding(.leading, 24)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: theme?.cardCornerRadius ?? 8)
                        .fill((theme?.accentColor ?? .blue).opacity(0.1))
                )
            }
        }
        .padding()
        .background(theme?.surfaceColor ?? Color(.systemBackground))
        .cornerRadius(theme?.cardCornerRadius ?? 16)
    }
}

// MARK: - YouTube Player Web View
struct YouTubePlayerView: UIViewRepresentable {
    let videoURL: String
    let onStatusChange: (Bool, Bool) -> Void // (isLoading, hasError)
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor.black
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Create embedded YouTube player HTML
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { 
                    margin: 0; 
                    padding: 0; 
                    background-color: black;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                }
                iframe { 
                    width: 100%; 
                    height: 100%; 
                    border: none;
                }
            </style>
        </head>
        <body>
            <iframe src="\(videoURL)?autoplay=0&controls=1&modestbranding=1&rel=0&showinfo=0"
                    frameborder="0" 
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
                    allowfullscreen>
            </iframe>
        </body>
        </html>
        """
        
        webView.loadHTMLString(embedHTML, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: YouTubePlayerView
        
        init(_ parent: YouTubePlayerView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.onStatusChange(true, false)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onStatusChange(false, false)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.onStatusChange(false, true)
        }
    }
}

// MARK: - Themed Extension
extension InteractiveVideoContentView {
    func themed(with theme: ThemeProvider) -> some View {
        self.environment(\.theme, theme)
    }
}

#Preview {
    InteractiveVideoContentView(
        content: InteractiveVideoContent(
            videoURL: "https://www.youtube.com/embed/KcKOM7Degu0",
            thumbnailURL: "",
            transcript: nil
        )
    )
}