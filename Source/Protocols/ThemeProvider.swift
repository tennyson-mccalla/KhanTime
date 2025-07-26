import SwiftUI

/// Protocol defining the contract for all themes
/// This allows us to create age-appropriate UI experiences
protocol ThemeProvider {
    // MARK: - Colors
    var primaryColor: Color { get }
    var secondaryColor: Color { get }
    var accentColor: Color { get }
    var backgroundColor: Color { get }
    var surfaceColor: Color { get }
    var errorColor: Color { get }
    var successColor: Color { get }
    var warningColor: Color { get }

    // MARK: - Typography
    var titleFont: Font { get }
    var headingFont: Font { get }
    var bodyFont: Font { get }
    var captionFont: Font { get }
    var buttonFont: Font { get }

    // MARK: - Spacing & Layout
    var smallSpacing: CGFloat { get }
    var standardSpacing: CGFloat { get }
    var largeSpacing: CGFloat { get }
    var cardCornerRadius: CGFloat { get }
    var buttonCornerRadius: CGFloat { get }
    var buttonHeight: CGFloat { get }

    // MARK: - Animations
    var defaultAnimation: Animation { get }
    var transitionStyle: AnyTransition { get }
    var feedbackAnimation: Animation { get }
    var loadingAnimation: Animation { get }

    // MARK: - Interactive Elements
    var buttonStyle: AnyButtonStyle { get }
    var textFieldStyle: AnyTextFieldStyle { get }

    // MARK: - Theme Metadata
    var themeName: String { get }
    var targetAgeGroup: AgeGroup { get }
    var supportsHighContrast: Bool { get }
    var supportsDarkMode: Bool { get }
}

// MARK: - Type-erased button style
struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

// Default button style implementation
struct DefaultButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Type-erased text field style
struct AnyTextFieldStyle {
    let apply: (TextField<Text>) -> AnyView

    init<S: TextFieldStyle>(_ style: S) {
        self.apply = { textField in
            AnyView(textField.textFieldStyle(style))
        }
    }
}

// Default text field style implementation
struct DefaultTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}

// MARK: - Environment key for theme injection
private struct ThemeKey: EnvironmentKey {
    // Default will be set in AppContainer
    static let defaultValue: ThemeProvider? = nil
}

extension EnvironmentValues {
    var theme: ThemeProvider? {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View modifier for theme application
struct ThemedView: ViewModifier {
    let theme: ThemeProvider

    func body(content: Content) -> some View {
        content
            .environment(\.theme, theme)
            .accentColor(theme.accentColor)
            .font(theme.bodyFont)
    }
}

extension View {
    func themed(with theme: ThemeProvider) -> some View {
        modifier(ThemedView(theme: theme))
    }
}

// MARK: - Preview helper
struct ThemePreview<Content: View>: View {
    let content: () -> Content
    let themes: [ThemeProvider]

    init(themes: [ThemeProvider] = [], @ViewBuilder content: @escaping () -> Content) {
        self.themes = themes
        self.content = content
    }

    var body: some View {
        VStack(spacing: 20) {
            ForEach(themes, id: \.themeName) { theme in
                VStack {
                    Text(theme.themeName)
                        .font(.headline)

                    content()
                        .themed(with: theme)
                        .padding()
                        .background(theme.surfaceColor)
                        .cornerRadius(theme.cardCornerRadius)
                }
            }
        }
        .padding()
    }
}
