import SwiftUI

/// A reusable card component for displaying course information
/// Automatically adapts to the current theme
struct CourseCard: View {
    let course: Course
    @Environment(\.theme) var theme
    @State private var isPressed = false

    var body: some View {
        if let theme = theme {
            themedCard(theme: theme)
        } else {
            // Fallback if no theme is set
            basicCard()
        }
    }

    @ViewBuilder
    private func themedCard(theme: ThemeProvider) -> some View {
        VStack(alignment: .leading, spacing: theme.smallSpacing) {
            // Course Title
            Text(course.title)
                .font(theme.headingFont)
                .foregroundColor(theme.primaryColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Course Code
            if let courseCode = course.courseCode {
                Text(courseCode)
                    .font(theme.captionFont)
                    .foregroundColor(theme.secondaryColor.opacity(0.7))
            }

            // Grades
            if let grades = course.grades, !grades.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 12))
                        .foregroundColor(theme.accentColor)

                    Text("Grades: \(grades.joined(separator: ", "))")
                        .font(theme.captionFont)
                        .foregroundColor(theme.secondaryColor)
                }
            }

            Spacer(minLength: 0)

            // Progress indicator (placeholder for now)
            progressBar(theme: theme)
        }
        .padding(theme.standardSpacing)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.surfaceColor)
                .shadow(
                    color: theme.primaryColor.opacity(0.1),
                    radius: isPressed ? 2 : 8,
                    x: 0,
                    y: isPressed ? 1 : 4
                )
        )
                .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(theme.feedbackAnimation, value: isPressed)
    }

    @ViewBuilder
    private func progressBar(theme: ThemeProvider) -> some View {
        // Get progress based on theme type for demonstration
        let progress = demoProgress(for: theme)

        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.primaryColor.opacity(0.1))
                    .frame(height: 8)

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryColor, theme.accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)

                // For kids theme, add a star at the end
                if theme.targetAgeGroup == .k2 && progress > 0 {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .offset(x: geometry.size.width * progress - 10)
                }
            }
        }
        .frame(height: 8)
    }

    private func demoProgress(for theme: ThemeProvider) -> Double {
        // Demo different progress levels for different themes
        switch theme.targetAgeGroup {
        case .k2: return 0.7
        case .g35: return 0.6
        case .g68: return 0.5
        case .g912: return 0.4
        }
    }

    @ViewBuilder
    private func basicCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.title)
                .font(.headline)
                .lineLimit(2)

            if let courseCode = course.courseCode {
                Text(courseCode)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 4)
        )
    }
}

// MARK: - Preview
struct CourseCard_Previews: PreviewProvider {
    static let sampleCourse = Course(
        sourcedId: "1",
        title: "Introduction to Algebra",
        courseCode: "MATH-101",
        grades: ["6", "7", "8"],
        dateLastModified: "2024-01-01",
        org: OrgRef(sourcedId: "org1")
    )

    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(ThemeFactory.allThemes, id: \.themeName) { theme in
                    VStack(alignment: .leading) {
                        Text(theme.themeName)
                            .font(.headline)
                            .padding(.horizontal)

                        CourseCard(course: sampleCourse)
                            .padding(.horizontal)
                            .themed(with: theme)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGray6))
    }
}
