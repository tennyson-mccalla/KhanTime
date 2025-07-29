import SwiftUI
import WebKit

struct InteractiveLessonView: View {
    let lesson: InteractiveLesson
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @StateObject private var lessonProgressManager = LessonProgressManager()
    @StateObject private var userProgressManager = ProgressManager()
    @State private var showCompletionCelebration = false
    
    init(lesson: InteractiveLesson) {
        self.lesson = lesson
        print("🏗️ InteractiveLessonView init with lesson: \(lesson.title)")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                progressBar
                
                // Main content
                ScrollView {
                    LazyVStack(spacing: theme?.standardSpacing ?? 16) {
                        // Lesson header
                        lessonHeader
                        
                        // Current step content
                        currentStepView
                        
                        // Navigation buttons
                        navigationButtons
                    }
                    .padding(theme?.standardSpacing ?? 16)
                }
                .background(theme?.backgroundColor ?? Color(.systemGroupedBackground))
            }
            .navigationTitle(lesson.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Lessons")
                        }
                        .foregroundColor(theme?.accentColor ?? .blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add lesson menu options
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(theme?.accentColor ?? .blue)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCompletionCelebration) {
            LessonCompletionView(
                lesson: lesson,
                score: lessonProgressManager.totalScore,
                totalPossible: lesson.content.compactMap { step in
                    if case .interactiveQuestion(let question) = step.content {
                        return question.points
                    }
                    return nil
                }.reduce(0, +),
                timeElapsed: lessonProgressManager.elapsedTime,
                userProfile: userProgressManager.userProfile
            ) {
                showCompletionCelebration = false
                dismiss()
            }
            .environmentObject(userProgressManager)
        }
        .onAppear {
            print("🎓 InteractiveLessonView appeared for lesson: \(lesson.title)")
            print("🎓 Lesson has \(lesson.content.count) steps")
            lessonProgressManager.startLesson(lesson)
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Step \(lessonProgressManager.currentStepIndex + 1) of \(lesson.content.count)")
                    .font(theme?.captionFont ?? .caption)
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                
                Spacer()
                
                Text(formatDuration(lessonProgressManager.elapsedTime))
                    .font(theme?.captionFont ?? .caption)
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
            }
            .padding(.horizontal, theme?.standardSpacing ?? 16)
            
            ProgressView(value: lessonProgressManager.progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: theme?.accentColor ?? .blue))
                .padding(.horizontal, theme?.standardSpacing ?? 16)
        }
        .padding(.vertical, theme?.smallSpacing ?? 8)
        .background(theme?.surfaceColor ?? Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Lesson Header
    private var lessonHeader: some View {
        VStack(alignment: .leading, spacing: theme?.smallSpacing ?? 8) {
            // Step type indicator
            HStack {
                stepTypeIcon
                
                Text(currentStep.type.displayName)
                    .font(theme?.captionFont ?? .caption)
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Spacer()
            }
            
            // Step title
            Text(currentStep.title)
                .font(theme?.titleFont ?? .largeTitle)
                .foregroundColor(theme?.primaryColor ?? .primary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(theme?.surfaceColor ?? Color(.systemBackground))
        .cornerRadius(theme?.cardCornerRadius ?? 12)
    }
    
    private var stepTypeIcon: some View {
        let (iconName, color) = stepTypeInfo
        
        return Image(systemName: iconName)
            .font(.title3)
            .foregroundColor(color)
    }
    
    private var stepTypeInfo: (String, Color) {
        switch currentStep.type {
        case .introduction:
            return ("book.fill", theme?.accentColor ?? .blue)
        case .example:
            return ("lightbulb.fill", theme?.warningColor ?? .orange)
        case .practice:
            return ("pencil.circle.fill", theme?.primaryColor ?? .primary)
        case .assessment:
            return ("checkmark.seal.fill", theme?.successColor ?? .green)
        }
    }
    
    // MARK: - Current Step View
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep.content {
        case .textContent(let textContent):
            TextContentView(content: textContent)
                .themed(with: theme!)
            
        case .videoContent(let videoContent):
            InteractiveVideoContentView(content: videoContent)
                .themed(with: theme!)
                .id("video-step-\(currentStep.id)")
                .onAppear {
                    print("🎞️ Rendering video content step with URL: '\(videoContent.videoURL)'")
                }
            
        case .interactiveQuestion(let question):
            InteractiveQuestionView(question: question) { answer, isCorrect in
                lessonProgressManager.answerQuestion(answer: answer, isCorrect: isCorrect, points: question.points)
            }
            .id("question-\(question.id)")  // Force recreation when question changes
            
        case .multiStepProblem(let problem):
            MultiStepProblemView(problem: problem) { answers, totalScore in
                lessonProgressManager.completeMultiStepProblem(totalScore: totalScore)
            }
            .themed(with: theme!)
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: theme?.standardSpacing ?? 16) {
            // Previous button
            if lessonProgressManager.canGoPrevious {
                Button(action: {
                    // Immediate haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    lessonProgressManager.previousStep()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(theme?.buttonFont ?? .headline)
                    .foregroundColor(theme?.primaryColor ?? .primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: theme?.buttonCornerRadius ?? 8)
                            .stroke(theme?.primaryColor ?? .gray, lineWidth: 1)
                    )
                }
            }
            
            Spacer()
            
            // Next/Finish button
            if lessonProgressManager.canGoNext {
                Button(action: {
                    // Immediate haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    if lessonProgressManager.isLastStep {
                        // Complete lesson, save progress, and show celebration
                        lessonProgressManager.completeLesson()
                        
                        // Calculate total possible points
                        let totalPossible = lesson.content.compactMap { step in
                            if case .interactiveQuestion(let question) = step.content {
                                return question.points
                            }
                            return nil
                        }.reduce(0, +)
                        
                        // Save to user progress system
                        userProgressManager.completeLesson(
                            lesson,
                            score: lessonProgressManager.totalScore,
                            totalPossible: totalPossible,
                            timeSpent: lessonProgressManager.elapsedTime
                        )
                        
                        showCompletionCelebration = true
                    } else {
                        lessonProgressManager.nextStep()
                    }
                }) {
                    HStack {
                        Text(lessonProgressManager.isLastStep ? "Finish Lesson" : "Continue")
                        
                        if !lessonProgressManager.isLastStep {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .font(theme?.buttonFont ?? .headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: theme?.buttonCornerRadius ?? 8)
                            .fill(theme?.accentColor ?? .blue)
                    )
                }
            }
        }
        .padding()
        .background(theme?.surfaceColor ?? Color(.systemBackground))
        .cornerRadius(theme?.cardCornerRadius ?? 12)
    }
    
    // MARK: - Helper Properties
    private var currentStep: LessonStep {
        lesson.content[lessonProgressManager.currentStepIndex]
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Step Type Extension
extension LessonStep.StepType {
    var displayName: String {
        switch self {
        case .introduction: return "Introduction"
        case .example: return "Example"
        case .practice: return "Practice"
        case .assessment: return "Assessment"
        }
    }
}

// MARK: - Supporting Views
struct TextContentView: View {
    let content: TextContent
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme?.standardSpacing ?? 16) {
            Text(content.text)
                .font(theme?.bodyFont ?? .body)
                .foregroundColor(theme?.primaryColor ?? .primary)
                .multilineTextAlignment(.leading)
            
            // Images would go here
            ForEach(content.images, id: \.self) { imageName in
                AsyncImage(url: URL(string: imageName)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Text("Loading image...")
                                .foregroundColor(.gray)
                        )
                }
                .cornerRadius(theme?.cardCornerRadius ?? 8)
            }
        }
        .padding()
        .background(theme?.surfaceColor ?? Color(.systemBackground))
        .cornerRadius(theme?.cardCornerRadius ?? 12)
    }
}

// Removed old placeholder - using real InteractiveVideoContentView from Components folder

struct MultiStepProblemView: View {
    let problem: MultiStepProblem
    let onCompletion: ([AnswerValue], Int) -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme?.standardSpacing ?? 16) {
            Text(problem.problemStatement)
                .font(theme?.headingFont ?? .headline)
                .foregroundColor(theme?.primaryColor ?? .primary)
            
            Text("Multi-step problems coming soon!")
                .font(theme?.bodyFont ?? .body)
                .foregroundColor(theme?.secondaryColor ?? .secondary)
        }
        .padding()
        .background(theme?.surfaceColor ?? Color(.systemBackground))
        .cornerRadius(theme?.cardCornerRadius ?? 12)
    }
}

// MARK: - Lesson Progress Manager
class LessonProgressManager: ObservableObject {
    @Published var currentStepIndex = 0
    @Published var totalScore = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var stepAnswers: [String: AnswerValue] = [:]
    
    private var lesson: InteractiveLesson?
    private var startTime: Date?
    private var timer: Timer?
    
    var progress: Double {
        guard let lesson = lesson else { return 0 }
        return Double(currentStepIndex + 1) / Double(lesson.content.count)
    }
    
    var canGoPrevious: Bool {
        currentStepIndex > 0
    }
    
    var canGoNext: Bool {
        // Can go next if current step is not a question, or if question is answered
        guard let lesson = lesson else { return false }
        let currentStep = lesson.content[currentStepIndex]
        
        switch currentStep.content {
        case .interactiveQuestion(let question):
            return stepAnswers[question.id] != nil
        default:
            return true
        }
    }
    
    var isLastStep: Bool {
        guard let lesson = lesson else { return false }
        return currentStepIndex == lesson.content.count - 1
    }
    
    func startLesson(_ lesson: InteractiveLesson) {
        print("📚 ProgressManager starting lesson: \(lesson.title)")
        
        // Reset all state for new lesson
        self.lesson = lesson
        self.currentStepIndex = 0
        self.totalScore = 0
        self.elapsedTime = 0
        self.stepAnswers = [:] // Clear previous answers
        self.startTime = Date()
        
        // Start timer for elapsed time tracking - reduced frequency for better performance
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            DispatchQueue.main.async {
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
        print("📚 ProgressManager lesson started successfully")
    }
    
    func nextStep() {
        guard let lesson = lesson, currentStepIndex < lesson.content.count - 1 else { return }
        currentStepIndex += 1
    }
    
    func previousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }
    
    func answerQuestion(answer: AnswerValue, isCorrect: Bool, points: Int) {
        guard let lesson = lesson else { return }
        let currentStep = lesson.content[currentStepIndex]
        
        if case .interactiveQuestion(let question) = currentStep.content {
            stepAnswers[question.id] = answer
            
            if isCorrect {
                totalScore += points
            }
        }
    }
    
    func completeMultiStepProblem(totalScore: Int) {
        self.totalScore += totalScore
    }
    
    func completeLesson() {
        timer?.invalidate()
        timer = nil
        
        // Here you would typically save progress to backend
        print("Lesson completed! Score: \(totalScore), Time: \(formatTime(elapsedTime))")
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return "\(minutes)m \(seconds)s"
    }
    
    deinit {
        timer?.invalidate()
    }
}

#Preview {
    let sampleLesson = LessonProvider.getBasicAlgebraLessons()[0]
    
    InteractiveLessonView(lesson: sampleLesson)
        .environmentObject(ThemePreference())
}