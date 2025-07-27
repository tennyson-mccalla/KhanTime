import SwiftUI

struct InteractiveLessonsBrowserView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themePreference: ThemePreference
    @State private var selectedSubject: InteractiveLesson.Subject = .algebra
    @State private var selectedLesson: InteractiveLesson?
    @State private var showLessonView = false
    
    private let mockLessons = MockLessonProvider.getBasicAlgebraLessons()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Subject selector
                subjectSelector
                
                // Lessons list
                ScrollView {
                    LazyVStack(spacing: theme?.standardSpacing ?? 16) {
                        ForEach(filteredLessons) { lesson in
                            LessonPreviewCard(lesson: lesson) {
                                print("🎯 Selected lesson: \(lesson.title)")
                                selectedLesson = lesson
                                showLessonView = true
                                print("🎯 showLessonView set to true")
                            }
                        }
                    }
                    .padding(theme?.standardSpacing ?? 16)
                }
                .background(theme?.backgroundColor ?? Color(.systemGroupedBackground))
            }
            .navigationTitle("Interactive Lessons")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showLessonView) {
            if let lesson = selectedLesson {
                InteractiveLessonView(lesson: lesson)
                    .environmentObject(themePreference)
                    .themedWithPreference(themePreference)
            }
        }
    }
    
    // MARK: - Subject Selector
    private var subjectSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme?.smallSpacing ?? 12) {
                ForEach(InteractiveLesson.Subject.allCases, id: \.self) { subject in
                    Button(action: {
                        selectedSubject = subject
                    }) {
                        Text(subject.rawValue)
                            .font(theme?.buttonFont ?? .headline)
                            .foregroundColor(
                                selectedSubject == subject ?
                                .white : (theme?.primaryColor ?? .primary)
                            )
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: theme?.buttonCornerRadius ?? 20)
                                    .fill(
                                        selectedSubject == subject ?
                                        (theme?.accentColor ?? .blue) :
                                        Color.clear
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme?.buttonCornerRadius ?? 20)
                                            .stroke(
                                                selectedSubject == subject ?
                                                Color.clear :
                                                (theme?.secondaryColor ?? .gray),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, theme?.standardSpacing ?? 16)
        }
        .padding(.vertical, theme?.smallSpacing ?? 12)
        .background(theme?.surfaceColor ?? Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Filtered Lessons
    private var filteredLessons: [InteractiveLesson] {
        mockLessons.filter { $0.subject == selectedSubject }
    }
}

// MARK: - Lesson Preview Card
struct LessonPreviewCard: View {
    let lesson: InteractiveLesson
    let onTap: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: theme?.standardSpacing ?? 12) {
                // Header with subject and duration
                HStack {
                    Text(lesson.subject.rawValue)
                        .font(theme?.captionFont ?? .caption)
                        .foregroundColor(theme?.accentColor ?? .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill((theme?.accentColor ?? .blue).opacity(0.1))
                        )
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(formatDuration(lesson.estimatedDuration))
                            .font(theme?.captionFont ?? .caption)
                    }
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                }
                
                // Title and description
                Text(lesson.title)
                    .font(theme?.titleFont ?? .title2)
                    .foregroundColor(theme?.primaryColor ?? .primary)
                    .multilineTextAlignment(.leading)
                
                Text(lesson.description)
                    .font(theme?.bodyFont ?? .body)
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                // Learning objectives
                if !lesson.learningObjectives.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You'll learn:")
                            .font(theme?.captionFont ?? .caption)
                            .foregroundColor(theme?.secondaryColor ?? .secondary)
                            .fontWeight(.medium)
                        
                        ForEach(Array(lesson.learningObjectives.prefix(3).enumerated()), id: \.offset) { index, objective in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(theme?.accentColor ?? .blue)
                                    .fontWeight(.bold)
                                
                                Text(objective)
                                    .font(theme?.captionFont ?? .caption)
                                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
                
                // Footer with grade level and content count
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                        Text("Grade \(lesson.gradeLevel.displayName)")
                            .font(theme?.captionFont ?? .caption)
                    }
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                        Text("\(lesson.content.count) steps")
                            .font(theme?.captionFont ?? .caption)
                    }
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme?.accentColor ?? .blue)
                }
            }
            .padding(theme?.standardSpacing ?? 16)
            .background(theme?.surfaceColor ?? Color(.systemBackground))
            .cornerRadius(theme?.cardCornerRadius ?? 12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
    InteractiveLessonsBrowserView()
        .environmentObject(ThemePreference())
}