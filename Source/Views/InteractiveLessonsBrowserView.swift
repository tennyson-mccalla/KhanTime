import SwiftUI

struct InteractiveLessonsBrowserView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themePreference: ThemePreference
    @State private var selectedSubject: Subject.SubjectType = .preAlgebra
    @State private var selectedLesson: InteractiveLesson?
    @State private var showLessonView = false
    @State private var lessonToPresent: InteractiveLesson?
    @State private var allLessons: [InteractiveLesson] = []
    @State private var khanAcademySubjects: [Subject] = []
    @State private var isLoadingTimeBack = false
    @State private var timeBackError: String?
    
    private let aeProvider = AEStudioContentProvider()
    
    private var loadingMessage: String {
        return "Loading Khan Academy Content..."
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Interactive Lessons")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Dashboard")
                            }
                            .foregroundColor(theme?.accentColor ?? .blue)
                        }
                    }
                }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            subjectSelector
            
            if isLoadingTimeBack {
                loadingView
            } else if let error = timeBackError {
                errorView(error)
            } else {
                lessonsList
            }
        }
        .fullScreenCover(item: $lessonToPresent) { lesson in
            let _ = print("🚀 fullScreenCover presenting lesson: \(lesson.title)")
            InteractiveLessonView(lesson: lesson)
                .environmentObject(themePreference)
        }
        .onAppear {
            loadLessons()
        }
    }
    
    private var lessonsList: some View {
        ScrollView {
            LazyVStack(spacing: theme?.standardSpacing ?? 16) {
                if hasHierarchicalContent {
                    hierarchicalContentView
                } else {
                    flatLessonListView
                }
            }
            .padding(theme?.standardSpacing ?? 16)
        }
        .background(theme?.backgroundColor ?? Color(.systemGroupedBackground))
    }
    
    // MARK: - Hierarchical Content View (Subject > Unit > Lesson)
    private var hierarchicalContentView: some View {
        Group {
            if let subject = filteredSubject {
                ForEach(subject.units) { unit in
                    UnitSectionView(unit: unit) { lesson in
                        selectLesson(lesson)
                    }
                }
            }
        }
    }
    
    // MARK: - Flat Lesson List View (fallback for non-hierarchical content)
    private var flatLessonListView: some View {
        Group {
            // Show demo lessons for backward compatibility
            let demoLessons = EducationalContentManager.getOriginalDemoLessons()
            ForEach(demoLessons) { lesson in
                LessonPreviewCard(lesson: lesson) {
                    selectLesson(lesson)
                }
            }
        }
    }
    
    // MARK: - Lesson Selection
    private func selectLesson(_ lesson: InteractiveLesson) {
        // Immediate haptic feedback for responsiveness
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("🎯 Selected lesson: \(lesson.title)")
        print("🎯 Setting lessonToPresent to: \(lesson.title)")
        lessonToPresent = lesson
        print("🎯 lessonToPresent set successfully")
    }
    
    
    // MARK: - Subject Selector
    private var subjectSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme?.smallSpacing ?? 12) {
                ForEach(Subject.SubjectType.allCases, id: \.self) { subject in
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
    
    // MARK: - Loading Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: theme?.accentColor ?? .blue))
            
            Text(loadingMessage)
                .font(theme?.bodyFont ?? .body)
                .foregroundColor(theme?.secondaryColor ?? .secondary)
            
            Text("Loading from local content...")
                .font(theme?.captionFont ?? .caption)
                .foregroundColor(theme?.secondaryColor ?? .secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme?.backgroundColor ?? Color(.systemGroupedBackground))
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Failed to Load Content")
                .font(theme?.headingFont ?? .headline)
                .foregroundColor(theme?.primaryColor ?? .primary)
            
            Text(error)
                .font(theme?.bodyFont ?? .body)
                .foregroundColor(theme?.secondaryColor ?? .secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                loadLessons()
            }
            .buttonStyle(.borderedProminent)
            .tint(theme?.accentColor ?? .blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme?.backgroundColor ?? Color(.systemGroupedBackground))
    }
    
    // MARK: - Data Loading
    
    private func loadLessons() {
        guard !isLoadingTimeBack else { return }
        
        isLoadingTimeBack = true
        timeBackError = nil
        
        Task {
            print("📡 Loading lessons from local content (TimeBack API bypassed)...")
            
            // Load static lessons first
            var lessons = EducationalContentManager.getOriginalDemoLessons()
            lessons.append(contentsOf: KhanAcademyContentProvider.loadKhanAcademyLessons())
            
            // Load Khan Academy subjects using new hierarchy approach
            let khanSubjects = KhanAcademyContentProvider.loadKhanAcademySubjects()
            
            // Note: Descriptions could be enhanced with scraped content from external tools
            
            // DON'T flatten Khan Academy content - preserve hierarchy for proper UI display
            print("📊 Khan Academy hierarchy: \(khanSubjects.count) subjects, \(khanSubjects.flatMap { $0.units }.count) units")
            
            // Debug: Print hierarchical structure
            for subject in khanSubjects {
                print("🔍 Subject: '\(subject.title)' (\(subject.units.count) units)")
                for unit in subject.units {
                    print("  📁 Unit: '\(unit.title)' (\(unit.lessons.count) lessons)")
                }
            }
            
            // Skip ae.studio content loading - TimeBack API is unreliable
            // let aeStudioLessons = try await aeProvider.loadAEStudioLessons()
            // lessons.append(contentsOf: aeStudioLessons)
            
            await MainActor.run {
                self.allLessons = lessons
                self.khanAcademySubjects = khanSubjects
                self.isLoadingTimeBack = false
                print("✅ Loaded \(lessons.count) lessons from local content (TimeBack bypassed)")
            }
        }
    }
    
    // MARK: - Filtered Content
    private var filteredSubject: Subject? {
        guard !khanAcademySubjects.isEmpty else { return nil }
        
        // Find the selected subject
        return khanAcademySubjects.first { subject in
            switch selectedSubject {
            case .preAlgebra:
                return subject.id == "pre-algebra"
            case .algebra:
                return subject.id == "algebra-basics" || subject.id == "algebra" || subject.id == "algebra2"
            case .physics:
                return subject.id == "physics"
            default:
                return false
            }
        }
    }
    
    private var hasHierarchicalContent: Bool {
        filteredSubject != nil
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
                headerSection
                titleSection
                learningObjectivesSection
                footerSection
            }
            .padding(theme?.standardSpacing ?? 16)
            .background(backgroundView)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var headerSection: some View {
        HStack {
            subjectBadge
            Spacer()
            durationInfo
        }
    }
    
    private var subjectBadge: some View {
        Text("Interactive Lesson") // TODO: Get subject from parent hierarchy
            .font(theme?.captionFont ?? .caption)
            .foregroundColor(theme?.accentColor ?? .blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill((theme?.accentColor ?? .blue).opacity(0.1))
            )
    }
    
    private var durationInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
            Text(formatDuration(lesson.estimatedDuration))
                .font(theme?.captionFont ?? .caption)
        }
        .foregroundColor(theme?.secondaryColor ?? .secondary)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lesson.title)
                .font(theme?.titleFont ?? .title2)
                .foregroundColor(theme?.primaryColor ?? .primary)
                .multilineTextAlignment(.leading)
            
            Text(lesson.description)
                .font(theme?.bodyFont ?? .body)
                .foregroundColor(theme?.secondaryColor ?? .secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
    }
    
    private var learningObjectivesSection: some View {
        Group {
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
        }
    }
    
    private var footerSection: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text(formatDuration(lesson.estimatedDuration))
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
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: theme?.cardCornerRadius ?? 12)
            .fill(theme?.surfaceColor ?? Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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