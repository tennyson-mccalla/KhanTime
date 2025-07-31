import SwiftUI

/// Theme designed for middle school students (6-8) with modern but approachable design
struct MiddleTheme: ThemeProvider {
    // MARK: - Colors
    var primaryColor: Color { Color(red: 0.25, green: 0.47, blue: 0.85) } // Modern blue
    var secondaryColor: Color { Color(red: 0.55, green: 0.35, blue: 0.75) } // Cool purple
    var accentColor: Color { Color(red: 0.95, green: 0.45, blue: 0.35) } // Energetic coral
    var backgroundColor: Color { Color(red: 0.96, green: 0.97, blue: 0.98) } // Light gray
    var surfaceColor: Color { .white }
    var errorColor: Color { Color(red: 0.85, green: 0.25, blue: 0.25) } // Standard red
    var successColor: Color { Color(red: 0.25, green: 0.75, blue: 0.35) } // Modern green
    var warningColor: Color { Color(red: 0.95, green: 0.65, blue: 0.15) } // Amber

    // MARK: - Typography
    var titleFont: Font {
        .system(size: 34, weight: .bold, design: .default)
    }
    var headingFont: Font {
        .system(size: 24, weight: .semibold, design: .default)
    }
    var bodyFont: Font {
        .system(size: 16, weight: .regular, design: .default)
    }
    var captionFont: Font {
        .system(size: 13, weight: .regular, design: .default)
    }
    var buttonFont: Font {
        .system(size: 17, weight: .medium, design: .default)
    }

    // MARK: - Spacing & Layout
    var smallSpacing: CGFloat { 10 }
    var standardSpacing: CGFloat { 16 }
    var largeSpacing: CGFloat { 28 }
    var cardCornerRadius: CGFloat { 16 }
    var buttonCornerRadius: CGFloat { 12 }
    var buttonHeight: CGFloat { 52 }

    // MARK: - Animations
    var defaultAnimation: Animation {
        .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
    }
    var transitionStyle: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 1.05).combined(with: .opacity)
        )
    }
    var feedbackAnimation: Animation {
        .spring(response: 0.25, dampingFraction: 0.7, blendDuration: 0)
    }
    var loadingAnimation: Animation {
        .easeInOut(duration: 1.0).repeatForever(autoreverses: false)
    }

    // MARK: - Interactive Elements
    var buttonStyle: AnyButtonStyle {
        AnyButtonStyle(MiddleButtonStyle(theme: self))
    }
    var textFieldStyle: AnyTextFieldStyle {
        AnyTextFieldStyle(MiddleTextFieldStyle(theme: self))
    }

    // MARK: - Dynamic Colors
    func dynamicPrimaryColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.4, green: 0.6, blue: 1.0) : primaryColor
    }
    
    func dynamicSecondaryColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.7, green: 0.5, blue: 0.9) : secondaryColor
    }
    
    func dynamicAccentColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 1.0, green: 0.6, blue: 0.5) : accentColor
    }
    
    func dynamicBackgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.06, green: 0.06, blue: 0.08) : backgroundColor
    }
    
    func dynamicSurfaceColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.12) : surfaceColor
    }

    // MARK: - Theme Metadata
    var themeName: String { "Middle School Theme (6-8)" }
    var targetAgeGroup: AgeGroup { .g68 }
    var supportsHighContrast: Bool { true }
    var supportsDarkMode: Bool { true }
}

// MARK: - Middle School Button Style
struct MiddleButtonStyle: ButtonStyle {
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
                        color: theme.primaryColor.opacity(0.25),
                        radius: configuration.isPressed ? 2 : 6,
                        x: 0,
                        y: configuration.isPressed ? 1 : 3
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(theme.feedbackAnimation, value: configuration.isPressed)
    }
}

// MARK: - Middle School Text Field Style
struct MiddleTextFieldStyle: TextFieldStyle {
    let theme: ThemeProvider

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(theme.bodyFont)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.primaryColor.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Middle School-specific UI Elements
extension MiddleTheme {
    /// Achievement badge for completed tasks
    func achievementBadge(title: String, icon: String = "checkmark.circle.fill") -> some View {
        HStack(spacing: smallSpacing) {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(title)
                .font(buttonFont)
        }
        .foregroundColor(.white)
        .padding(.horizontal, standardSpacing)
        .padding(.vertical, smallSpacing)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: primaryColor.opacity(0.3), radius: 4, y: 2)
    }

    /// Modern progress ring
    func progressRing(progress: Double, size: CGFloat = 100) -> some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(primaryColor.opacity(0.2), lineWidth: 8)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(
                        colors: [primaryColor, accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(defaultAnimation, value: progress)

            // Progress text
            Text("\(Int(progress * 100))%")
                .font(headingFont)
                .foregroundColor(primaryColor)
        }
        .frame(width: size, height: size)
    }

    /// Sleek loading indicator
    func loadingIndicator() -> some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(primaryColor)
                    .frame(width: 4, height: 16)
                    .scaleEffect(y: 1.0)
                    .animation(
                        loadingAnimation
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: true
                    )
            }
        }
    }

    /// Card style for content
    func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: cardCornerRadius)
            .fill(surfaceColor)
            .shadow(
                color: Color.black.opacity(0.08),
                radius: 8,
                x: 0,
                y: 2
            )
    }

    /// Tab selector style
    func tabSelector(items: [String], selection: Binding<String>) -> some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(buttonFont)
                    .foregroundColor(selection.wrappedValue == item ? .white : primaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, smallSpacing)
                    .background(
                        selection.wrappedValue == item ?
                        primaryColor : Color.clear
                    )
                    .onTapGesture {
                        withAnimation(feedbackAnimation) {
                            selection.wrappedValue = item
                        }
                    }
            }
        }
        .background(primaryColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: buttonCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: buttonCornerRadius)
                .stroke(primaryColor.opacity(0.2), lineWidth: 1)
        )
    }
}
