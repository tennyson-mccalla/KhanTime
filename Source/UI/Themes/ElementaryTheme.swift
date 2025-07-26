import SwiftUI

/// Theme designed for elementary students (3-5) with engaging but less playful elements than K-2
struct ElementaryTheme: ThemeProvider {
    // MARK: - Colors
    var primaryColor: Color { Color(red: 0.15, green: 0.5, blue: 0.85) } // Calmer blue
    var secondaryColor: Color { Color(red: 0.6, green: 0.4, blue: 0.8) } // Softer purple
    var accentColor: Color { Color(red: 0.95, green: 0.5, blue: 0.25) } // Muted orange
    var backgroundColor: Color { Color(red: 0.97, green: 0.97, blue: 0.99) } // Light background
    var surfaceColor: Color { .white }
    var errorColor: Color { Color(red: 0.85, green: 0.3, blue: 0.35) } // Standard red
    var successColor: Color { Color(red: 0.3, green: 0.75, blue: 0.45) } // Fresh green
    var warningColor: Color { Color(red: 0.95, green: 0.75, blue: 0.25) } // Warm yellow

    // MARK: - Typography
    var titleFont: Font {
        .system(size: 36, weight: .semibold, design: .rounded)
    }
    var headingFont: Font {
        .system(size: 26, weight: .medium, design: .rounded)
    }
    var bodyFont: Font {
        .system(size: 17, weight: .regular, design: .rounded)
    }
    var captionFont: Font {
        .system(size: 14, weight: .regular, design: .rounded)
    }
    var buttonFont: Font {
        .system(size: 18, weight: .medium, design: .rounded)
    }

    // MARK: - Spacing & Layout
    var smallSpacing: CGFloat { 10 }
    var standardSpacing: CGFloat { 18 }
    var largeSpacing: CGFloat { 28 }
    var cardCornerRadius: CGFloat { 20 }
    var buttonCornerRadius: CGFloat { 16 }
    var buttonHeight: CGFloat { 56 }  // Still tall but not as large as K-2

    // MARK: - Animations
    var defaultAnimation: Animation {
        .spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0)
    }
    var transitionStyle: AnyTransition {
        .scale(scale: 0.9)
            .combined(with: .opacity)
    }
    var feedbackAnimation: Animation {
        .spring(response: 0.28, dampingFraction: 0.6, blendDuration: 0)
    }
    var loadingAnimation: Animation {
        .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    }

    // MARK: - Interactive Elements
    var buttonStyle: AnyButtonStyle {
        AnyButtonStyle(ElementaryButtonStyle(theme: self))
    }
    var textFieldStyle: AnyTextFieldStyle {
        AnyTextFieldStyle(ElementaryTextFieldStyle(theme: self))
    }

    // MARK: - Theme Metadata
    var themeName: String { "Elementary Theme (3-5)" }
    var targetAgeGroup: AgeGroup { .g35 }
    var supportsHighContrast: Bool { true }
    var supportsDarkMode: Bool { true }
}

// MARK: - Elementary Button Style
struct ElementaryButtonStyle: ButtonStyle {
    let theme: ThemeProvider

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.buttonFont)
            .foregroundColor(.white)
            .frame(height: theme.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                    .fill(theme.primaryColor)
                    .shadow(
                        color: theme.primaryColor.opacity(0.3),
                        radius: configuration.isPressed ? 1 : 6,
                        x: 0,
                        y: configuration.isPressed ? 1 : 3
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(theme.feedbackAnimation, value: configuration.isPressed)
    }
}

// MARK: - Elementary Text Field Style
struct ElementaryTextFieldStyle: TextFieldStyle {
    let theme: ThemeProvider

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(theme.bodyFont)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.primaryColor.opacity(0.25), lineWidth: 1.5)
                    )
            )
    }
}

// MARK: - Elementary-specific UI Elements
extension ElementaryTheme {
    /// Achievement star for completed tasks
    func achievementStar() -> some View {
        ZStack {
            Star(corners: 5, smoothness: 0.5)
                .fill(
                    LinearGradient(
                        colors: [accentColor, primaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .shadow(color: primaryColor.opacity(0.3), radius: 4, y: 2)

            Image(systemName: "checkmark")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
    }

    /// Progress indicator with achievement milestones
    func progressBar(progress: Double, milestones: Int = 4) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 10)
                    .fill(primaryColor.opacity(0.15))

                // Progress fill
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)

                // Milestone markers
                HStack(spacing: 0) {
                    ForEach(0..<milestones, id: \.self) { index in
                        if index > 0 {
                            Spacer()
                        }
                        Circle()
                            .fill(progress >= Double(index + 1) / Double(milestones) ? successColor : Color.white)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(primaryColor, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(height: 20)
    }

    /// Animated loading dots
    func loadingDots() -> some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(primaryColor)
                    .frame(width: 12, height: 12)
                    .scaleEffect(1.0)
                    .animation(
                        loadingAnimation
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: true
                    )
            }
        }
    }
}

// Custom star shape
struct Star: Shape {
    let corners: Int
    let smoothness: Double

    func path(in rect: CGRect) -> Path {
        guard corners >= 2 else { return Path() }
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        var currentAngle = -CGFloat.pi / 2
        let angleAdjustment = .pi * 2 / CGFloat(corners * 2)
        let innerX = center.x * smoothness
        let innerY = center.y * smoothness

        var path = Path()
        path.move(to: CGPoint(x: center.x * cos(currentAngle) + center.x,
                              y: center.y * sin(currentAngle) + center.y))

        for corner in 0..<corners * 2 {
            let sinAngle = sin(currentAngle)
            let cosAngle = cos(currentAngle)
            let bottom: CGFloat

            if corner.isMultiple(of: 2) {
                bottom = center.y * cosAngle + center.y
                path.addLine(to: CGPoint(x: center.x * cosAngle + center.x,
                                         y: bottom))
            } else {
                bottom = innerY * sinAngle + center.y
                path.addLine(to: CGPoint(x: innerX * cosAngle + center.x,
                                         y: bottom))
            }
            currentAngle += angleAdjustment
        }
        path.closeSubpath()
        return path
    }
}
