import SwiftUI

/// Theme designed for high school students (9-12) with clean, professional design
struct HighSchoolTheme: ThemeProvider {
    // MARK: - Colors
    var primaryColor: Color { Color(red: 0.11, green: 0.29, blue: 0.64) } // Professional navy
    var secondaryColor: Color { Color(red: 0.29, green: 0.29, blue: 0.29) } // Charcoal gray
    var accentColor: Color { Color(red: 0.0, green: 0.73, blue: 0.83) } // Cyan accent
    var backgroundColor: Color { Color(red: 0.98, green: 0.98, blue: 0.98) } // Off-white
    var surfaceColor: Color { .white }
    var errorColor: Color { Color(red: 0.78, green: 0.16, blue: 0.16) } // Deep red
    var successColor: Color { Color(red: 0.16, green: 0.65, blue: 0.16) } // Professional green
    var warningColor: Color { Color(red: 0.85, green: 0.55, blue: 0.0) } // Dark amber

    // MARK: - Typography
    var titleFont: Font {
        .system(size: 28, weight: .semibold, design: .serif)
    }
    var headingFont: Font {
        .system(size: 20, weight: .medium, design: .default)
    }
    var bodyFont: Font {
        .system(size: 15, weight: .regular, design: .default)
    }
    var captionFont: Font {
        .system(size: 12, weight: .regular, design: .default)
    }
    var buttonFont: Font {
        .system(size: 16, weight: .medium, design: .default)
    }

    // MARK: - Spacing & Layout
    var smallSpacing: CGFloat { 8 }
    var standardSpacing: CGFloat { 14 }
    var largeSpacing: CGFloat { 24 }
    var cardCornerRadius: CGFloat { 8 }
    var buttonCornerRadius: CGFloat { 6 }
    var buttonHeight: CGFloat { 44 }

    // MARK: - Animations
    var defaultAnimation: Animation {
        .easeInOut(duration: 0.25)
    }
    var transitionStyle: AnyTransition {
        .opacity.combined(with: .move(edge: .trailing))
    }
    var feedbackAnimation: Animation {
        .easeOut(duration: 0.15)
    }
    var loadingAnimation: Animation {
        .linear(duration: 1.5).repeatForever(autoreverses: false)
    }

    // MARK: - Interactive Elements
    var buttonStyle: AnyButtonStyle {
        AnyButtonStyle(HighSchoolButtonStyle(theme: self))
    }
    var textFieldStyle: AnyTextFieldStyle {
        AnyTextFieldStyle(HighSchoolTextFieldStyle(theme: self))
    }

    // MARK: - Dynamic Colors
    func dynamicPrimaryColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.25, green: 0.5, blue: 1.0) : primaryColor
    }
    
    func dynamicSecondaryColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.7, green: 0.7, blue: 0.7) : secondaryColor
    }
    
    func dynamicAccentColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.2, green: 0.9, blue: 1.0) : accentColor
    }
    
    func dynamicBackgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.05, green: 0.05, blue: 0.05) : backgroundColor
    }
    
    func dynamicSurfaceColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.08) : surfaceColor
    }

    // MARK: - Theme Metadata
    var themeName: String { "High School Theme (9-12)" }
    var targetAgeGroup: AgeGroup { .g912 }
    var supportsHighContrast: Bool { true }
    var supportsDarkMode: Bool { true }
}

// MARK: - High School Button Style
struct HighSchoolButtonStyle: ButtonStyle {
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
                    .overlay(
                        configuration.isPressed ?
                        RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                            .fill(Color.black.opacity(0.1))
                        : nil
                    )
            )
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(theme.feedbackAnimation, value: configuration.isPressed)
    }
}

// MARK: - High School Text Field Style
struct HighSchoolTextFieldStyle: TextFieldStyle {
    let theme: ThemeProvider

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(theme.bodyFont)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(theme.secondaryColor.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

// MARK: - High School-specific UI Elements
extension HighSchoolTheme {
    /// Professional stats card
    func statsCard(title: String, value: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: smallSpacing) {
            Text(title)
                .font(captionFont)
                .foregroundColor(secondaryColor.opacity(0.7))
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(primaryColor)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(captionFont)
                    .foregroundColor(secondaryColor.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(standardSpacing)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(surfaceColor)
                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        )
    }

    /// Professional progress bar
    func progressBar(progress: Double, label: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: smallSpacing) {
            if let label = label {
                HStack {
                    Text(label)
                        .font(captionFont)
                        .foregroundColor(secondaryColor)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(captionFont)
                        .foregroundColor(secondaryColor)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(secondaryColor.opacity(0.1))
                        .frame(height: 4)

                    // Progress
                    Rectangle()
                        .fill(primaryColor)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(defaultAnimation, value: progress)
                }
            }
            .frame(height: 4)
        }
    }

    /// Minimal loading spinner
    func loadingSpinner(size: CGFloat = 24) -> some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                primaryColor,
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(0))
            .animation(loadingAnimation, value: true)
    }

    /// Professional navigation tab
    func navigationTab(title: String, isSelected: Bool) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(buttonFont)
                .foregroundColor(isSelected ? primaryColor : secondaryColor.opacity(0.6))

            Rectangle()
                .fill(isSelected ? primaryColor : Color.clear)
                .frame(height: 2)
                .animation(feedbackAnimation, value: isSelected)
        }
        .padding(.horizontal, standardSpacing)
    }

    /// Professional grade display
    func gradeDisplay(grade: String, score: Double) -> some View {
        HStack(spacing: standardSpacing) {
            // Grade letter
            Text(grade)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(primaryColor)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .stroke(primaryColor, lineWidth: 2)
                )

            // Score details
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(score))%")
                    .font(headingFont)
                    .foregroundColor(primaryColor)

                Text(gradeDescription(for: grade))
                    .font(captionFont)
                    .foregroundColor(secondaryColor.opacity(0.7))
            }

            Spacer()
        }
        .padding(standardSpacing)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(primaryColor.opacity(0.05))
        )
    }

    private func gradeDescription(for grade: String) -> String {
        switch grade {
        case "A": return "Excellent"
        case "B": return "Good"
        case "C": return "Satisfactory"
        case "D": return "Needs Improvement"
        case "F": return "Failing"
        default: return "Not Graded"
        }
    }
}
