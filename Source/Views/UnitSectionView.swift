import SwiftUI

struct UnitSectionView: View {
    let unit: Unit
    let onLessonSelected: (InteractiveLesson) -> Void
    
    @Environment(\.theme) var theme
    @State private var isExpanded = true // Start expanded to show hierarchy by default
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme?.smallSpacing ?? 8) {
            // Unit header with collapse/expand toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(theme?.accentColor ?? .blue)
                        .font(.caption)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(unit.title)
                            .font(theme?.titleFont ?? .title3)
                            .foregroundColor(theme?.primaryColor ?? .primary)
                            .fontWeight(.semibold)
                        
                        Text(unit.description)
                            .font(theme?.captionFont ?? .caption)
                            .foregroundColor(theme?.secondaryColor ?? .secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(unit.lessons.count) lessons")
                            .font(theme?.captionFont ?? .caption)
                            .foregroundColor(theme?.secondaryColor ?? .secondary)
                        
                        Text(formatDuration(unit.estimatedDuration))
                            .font(theme?.captionFont ?? .caption)
                            .foregroundColor(theme?.secondaryColor ?? .secondary)
                    }
                }
                .padding(theme?.standardSpacing ?? 16)
                .background(
                    RoundedRectangle(cornerRadius: theme?.cardCornerRadius ?? 12)
                        .fill(theme?.surfaceColor ?? Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Lessons list (collapsible)
            if isExpanded {
                VStack(spacing: theme?.smallSpacing ?? 8) {
                    ForEach(unit.lessons) { lesson in
                        LessonRowView(lesson: lesson) {
                            onLessonSelected(lesson)
                        }
                    }
                }
                .padding(.leading, theme?.standardSpacing ?? 16)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

// Individual lesson row within a unit
struct LessonRowView: View {
    let lesson: InteractiveLesson
    let onTap: () -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme?.standardSpacing ?? 12) {
                // Lesson icon
                Image(systemName: "play.circle.fill")
                    .foregroundColor(theme?.accentColor ?? .blue)
                    .font(.title2)
                
                // Lesson info
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(theme?.bodyFont ?? .body)
                        .foregroundColor(theme?.primaryColor ?? .primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(lesson.description)
                        .font(theme?.captionFont ?? .caption)
                        .foregroundColor(theme?.secondaryColor ?? .secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Duration and steps info
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(formatDuration(lesson.estimatedDuration))
                            .font(theme?.captionFont ?? .caption)
                    }
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.caption2)
                        Text("\(lesson.content.count) steps")
                            .font(theme?.captionFont ?? .caption)
                    }
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                }
                
                // Navigation arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
            }
            .padding(theme?.standardSpacing ?? 12)
            .background(
                RoundedRectangle(cornerRadius: theme?.cardCornerRadius ?? 8)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme?.cardCornerRadius ?? 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

#Preview {
    let sampleUnit = Unit(
        id: "factors-multiples",
        title: "Factors and multiples",
        description: "Understanding and finding factors and multiples. After these videos, you'll be ready for fractions.",
        estimatedDuration: 1800,
        lessons: [
            InteractiveLesson(
                id: "factors-intro",
                title: "Factors and multiples",
                description: "Learn about factor pairs and identifying factors",
                estimatedDuration: 300,
                prerequisites: [],
                learningObjectives: ["Understand factors", "Find factor pairs"],
                content: []
            ),
            InteractiveLesson(
                id: "prime-numbers",
                title: "Prime and composite numbers",
                description: "Learn to identify prime and composite numbers",
                estimatedDuration: 420,
                prerequisites: [],
                learningObjectives: ["Identify prime numbers", "Identify composite numbers"],
                content: []
            )
        ]
    )
    
    UnitSectionView(unit: sampleUnit) { lesson in
        print("Selected lesson: \(lesson.title)")
    }
    .padding()
    .environmentObject(ThemePreference())
}