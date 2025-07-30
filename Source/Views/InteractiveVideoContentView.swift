import SwiftUI
import WebKit

// Observable class to hold video content
class VideoContentModel: ObservableObject {
    let content: InteractiveVideoContent
    @Published var isLoading = true
    @Published var hasError = false
    @Published var hasInitialized = false
    
    init(content: InteractiveVideoContent) {
        self.content = content
    }
}

struct InteractiveVideoContentView: View {
    @StateObject private var videoModel: VideoContentModel
    @Environment(\.theme) var theme
    
    init(content: InteractiveVideoContent) {
        // Create stable StateObject
        self._videoModel = StateObject(wrappedValue: VideoContentModel(content: content))
        // Removed excessive logging
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme?.standardSpacing ?? 16) {
            // Video Title
            Text("📹 Khan Academy Video")
                .font(theme?.headingFont ?? .headline)
                .foregroundColor(theme?.primaryColor ?? .primary)
            
            // YouTube Video Player - Centered
            HStack {
                Spacer()
                ZStack {
                    if !videoModel.hasInitialized {
                        Rectangle()
                            .fill(Color.black)
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxHeight: 400)
                            .cornerRadius(theme?.cardCornerRadius ?? 12)
                            .overlay(
                                VStack {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("Initializing video player...")
                                        .font(theme?.captionFont ?? .caption)
                                        .foregroundColor(.white)
                                }
                            )
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    videoModel.hasInitialized = true
                                }
                            }
                    } else {
                        YouTubePlayerView(videoURL: videoModel.content.videoURL) { loading, error in
                            DispatchQueue.main.async {
                                videoModel.isLoading = loading
                                videoModel.hasError = error
                            }
                        }
                        .aspectRatio(16/9, contentMode: .fit) // YouTube standard 16:9 aspect ratio
                        .frame(maxHeight: 400) // Maximum height constraint
                        .cornerRadius(theme?.cardCornerRadius ?? 12)
                        .id("youtube-player-\(videoModel.content.videoURL.hashValue)") // Stable ID
                    }
                    
                    // Loading/Error Overlay
                    if videoModel.isLoading {
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
                    } else if videoModel.hasError {
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
                Spacer()
            }
            
            // Video Information
            if !videoModel.content.videoURL.isEmpty {
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
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        
        // Enable fullscreen video support
        configuration.preferences.setValue(true, forKey: "fullScreenEnabled")
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        // Add user content controller for better iframe support
        let userContentController = WKUserContentController()
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor.black
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        // Enable fullscreen gestures
        if #available(iOS 14.0, *) {
            webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Check if we need to load a new video URL
        let shouldLoadNewVideo = webView.url == nil || context.coordinator.lastLoadedURL != videoURL
        
        if shouldLoadNewVideo {
            context.coordinator.lastLoadedURL = videoURL
            // Create embedded YouTube player HTML
            let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <meta http-equiv="Content-Security-Policy" content="default-src * 'unsafe-inline' 'unsafe-eval'; script-src * 'unsafe-inline' 'unsafe-eval'; connect-src * 'unsafe-inline'; img-src * data: blob: 'unsafe-inline'; frame-src *; style-src * 'unsafe-inline';">
            <style>
                * {
                    box-sizing: border-box;
                }
                html, body { 
                    margin: 0; 
                    padding: 0; 
                    width: 100%;
                    height: 100%;
                    background-color: #000;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    overflow: hidden;
                }
                .video-container {
                    position: relative;
                    width: 100%;
                    height: 100%;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                }
                iframe { 
                    width: 100%; 
                    height: 100%; 
                    border: none;
                    border-radius: 8px;
                    background-color: #000;
                }
                .loading {
                    color: white;
                    text-align: center;
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                }
            </style>
        </head>
        <body>
            <div class="video-container">
                <div class="loading" id="loading">Loading Khan Academy video...</div>
                <iframe id="videoFrame" 
                        src="\(videoURL)?autoplay=0&controls=1&modestbranding=1&rel=0&showinfo=0&fs=1&origin=\(Bundle.main.bundleIdentifier ?? "com.khantime.app")" 
                        frameborder="0" 
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen; web-share" 
                        allowfullscreen
                        webkitallowfullscreen
                        mozallowfullscreen
                        style="display:none;"
                        onload="document.getElementById('loading').style.display='none'; this.style.display='block';">
                </iframe>
            </div>
        </body>
        </html>
        """
            
            webView.loadHTMLString(embedHTML, baseURL: nil)
        }
        // Removed "already loaded" logging
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: YouTubePlayerView
        var lastLoadedURL: String = ""
        
        init(_ parent: YouTubePlayerView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if navigation != nil {
                parent.onStatusChange(true, false)
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if navigation != nil {
                parent.onStatusChange(false, false)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.onStatusChange(false, true)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            // Silently handle navigation failures to reduce log spam
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