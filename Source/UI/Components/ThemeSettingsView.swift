import SwiftUI

/// Settings view for selecting age-appropriate themes
struct ThemeSettingsView: View {
    @EnvironmentObject var themePreference: ThemePreference
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: theme?.smallSpacing ?? 8) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 48))
                        .foregroundColor(theme?.primaryColor ?? .blue)

                    Text("Choose Your Theme")
                        .font(theme?.headingFont ?? .title2)
                        .foregroundColor(theme?.primaryColor ?? .primary)

                    Text("Select the theme that matches your grade level")
                        .font(theme?.captionFont ?? .caption)
                        .foregroundColor(theme?.secondaryColor.opacity(0.7) ?? .secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(theme?.largeSpacing ?? 24)

                // Theme Options
                ScrollView {
                    VStack(spacing: theme?.standardSpacing ?? 16) {
                        ForEach(AgeGroup.allCases, id: \.self) { ageGroup in
                            themeOption(for: ageGroup)
                        }
                    }
                    .padding(theme?.standardSpacing ?? 16)
                }
            }
            .background(theme?.backgroundColor ?? Color(.systemBackground))
            .navigationTitle("Theme Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func themeOption(for ageGroup: AgeGroup) -> some View {
        let isSelected = themePreference.selectedAgeGroup == ageGroup
        let previewTheme = ThemeFactory.theme(for: ageGroup)

        Button(action: {
            withAnimation {
                themePreference.updateTheme(for: ageGroup)
            }
        }) {
            VStack(alignment: .leading, spacing: theme?.smallSpacing ?? 8) {
                // Theme Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ageGroup.rawValue)
                            .font(previewTheme.headingFont)
                            .foregroundColor(previewTheme.primaryColor)

                        Text(themeDescription(for: ageGroup))
                            .font(previewTheme.captionFont)
                            .foregroundColor(previewTheme.secondaryColor.opacity(0.7))
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(previewTheme.accentColor)
                    }
                }

                // Color Preview
                HStack(spacing: theme?.smallSpacing ?? 8) {
                    ForEach(colorPreview(for: previewTheme), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                    }
                }

                // Sample UI Elements
                HStack(spacing: theme?.smallSpacing ?? 8) {
                    // Sample button
                    Text("Sample Button")
                        .font(previewTheme.buttonFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, previewTheme.standardSpacing)
                        .padding(.vertical, previewTheme.smallSpacing)
                        .background(
                            RoundedRectangle(cornerRadius: previewTheme.buttonCornerRadius)
                                .fill(previewTheme.primaryColor)
                        )

                    Spacer()

                    // Sample progress
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(previewTheme.primaryColor.opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(previewTheme.primaryColor)
                                .frame(width: geometry.size.width * 0.6, height: 8)
                        }
                    }
                    .frame(width: 100, height: 8)
                }
            }
            .padding(theme?.standardSpacing ?? 16)
            .background(
                RoundedRectangle(cornerRadius: previewTheme.cardCornerRadius)
                    .fill(previewTheme.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: previewTheme.cardCornerRadius)
                            .stroke(
                                isSelected ? previewTheme.primaryColor : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 4,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func themeDescription(for ageGroup: AgeGroup) -> String {
        switch ageGroup {
        case .k2:
            return "Colorful and playful design for young learners"
        case .g35:
            return "Fun and engaging for elementary students"
        case .g68:
            return "Modern and approachable for middle schoolers"
        case .g912:
            return "Clean and professional for high school students"
        }
    }

    private func colorPreview(for theme: ThemeProvider) -> [Color] {
        [theme.primaryColor, theme.secondaryColor, theme.accentColor, theme.successColor]
    }
}

// MARK: - Preview
struct ThemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSettingsView()
            .environmentObject(ThemePreference())
    }
}
