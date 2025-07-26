import SwiftUI

/// Theme designed for K-5 students with colorful, playful elements
struct KidsTheme: ThemeProvider {
    // MARK: - Colors
    var primaryColor: Color { Color(red: 0.2, green: 0.6, blue: 1.0) } // Bright blue
    var secondaryColor: Color { Color(red: 0.9, green: 0.3, blue: 0.9) } // Playful purple
    var accentColor: Color { Color(red: 1.0, green: 0.6, blue: 0.2) } // Warm orange
    var backgroundColor: Color { Color(red: 0.98, green: 0.98, blue: 1.0) } // Soft light blue-white
    var surfaceColor: Color { .white }
    var errorColor: Color { Color(red: 0.9, green: 0.2, blue: 0.3) } // Softer red
    var successColor: Color { Color(red: 0.2, green: 0.8, blue: 0.4) } // Friendly green
    var warningColor: Color { Color(red: 1.0, green: 0.8, blue: 0.2) } // Bright yellow

    // MARK: - Typography
    var titleFont: Font {
        .system(size: 40, weight: .bold, design: .rounded)
    }
    var headingFont: Font {
        .system(size: 28, weight: .semibold, design: .rounded)
    }
    var bodyFont: Font {
        .system(size: 18, weight: .regular, design: .rounded)
    }
    var captionFont: Font {
        .system(size: 14, weight: .regular, design: .rounded)
    }
    var buttonFont: Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }

    // MARK: - Spacing & Layout
    var smallSpacing: CGFloat { 12 }
    var standardSpacing: CGFloat { 20 }
    var largeSpacing: CGFloat { 32 }
    var cardCornerRadius: CGFloat { 25 }
    var buttonCornerRadius: CGFloat { 20 }
    var buttonHeight: CGFloat { 64 }  // Extra tall for easy tapping

    // MARK: - Animations
    var defaultAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)
    }
    var transitionStyle: AnyTransition {
        .scale(scale: 0.8)
            .combined(with: .opacity)
            .combined(with: .move(edge: .bottom))
    }
    var feedbackAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)
    }
    var loadingAnimation: Animation {
        .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
    }

    // MARK: - Interactive Elements
    var buttonStyle: AnyButtonStyle {
        AnyButtonStyle(KidsButtonStyle(theme: self))
    }
    var textFieldStyle: AnyTextFieldStyle {
        AnyTextFieldStyle(KidsTextFieldStyle(theme: self))
    }

    // MARK: - Theme Metadata
    var themeName: String { "Kids Theme (K-5)" }
    var targetAgeGroup: AgeGroup { .k2 }  // Using K-2 as starting point for K-5
    var supportsHighContrast: Bool { true }
    var supportsDarkMode: Bool { false }  // Kids theme is always bright
}

// MARK: - Kids Button Style
struct KidsButtonStyle: ButtonStyle {
    let theme: ThemeProvider

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.buttonFont)
            .foregroundColor(.white)
            .frame(height: theme.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.primaryColor,
                                theme.primaryColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: theme.primaryColor.opacity(0.4),
                        radius: configuration.isPressed ? 0 : 8,
                        x: 0,
                        y: configuration.isPressed ? 0 : 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(theme.feedbackAnimation, value: configuration.isPressed)
    }
}

// MARK: - Kids Text Field Style
struct KidsTextFieldStyle: TextFieldStyle {
    let theme: ThemeProvider

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(theme.bodyFont)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(theme.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(theme.primaryColor.opacity(0.3), lineWidth: 2)
                    )
            )
    }
}

// MARK: - Kids-specific UI Elements
extension KidsTheme {
    /// Special celebration animation for correct answers
    func celebrationView() -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 30))
                    .foregroundColor(accentColor)
                    .offset(
                        x: cos(CGFloat(index) * .pi / 4) * 100,
                        y: sin(CGFloat(index) * .pi / 4) * 100
                    )
                    .rotationEffect(.degrees(Double(index) * 45))
                    .scaleEffect(0)
                    .animation(
                        feedbackAnimation.delay(Double(index) * 0.1),
                        value: true
                    )
            }
        }
    }

    /// Progress indicator with fun visuals
    func progressBar(progress: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 15)
                    .fill(primaryColor.opacity(0.2))

                // Progress fill with gradient
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [primaryColor, accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)

                // Animated stars along the progress
                if progress > 0 {
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .offset(x: geometry.size.width * progress - 25)
                        .animation(defaultAnimation, value: progress)
                }
            }
        }
        .frame(height: 30)
    }

    /// Fun loading spinner
    func loadingSpinner() -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == 0 ? primaryColor : (index == 1 ? accentColor : secondaryColor))
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat(index - 1) * 30)
                    .scaleEffect(1.0)
                    .animation(
                        loadingAnimation.delay(Double(index) * 0.2),
                        value: true
                    )
            }
        }
    }
}
