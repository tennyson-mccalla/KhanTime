import Foundation

// MARK: - ae.studio Content Provider
// Loads real 3rd grade language content from TimeBack platform

class AEStudioContentProvider {
    
    private let courseService = CourseService()
    
    // Default to ae.studio staging course ID, but allow override
    private let defaultCourseId = "b0cc4cd4-abe4-40e1-9aa5-9f1f1dad9395" // Carlos's ae.studio course
    
    // Allow setting a different course ID via UserDefaults (for Khan Academy testing)
    private var courseId: String {
        UserDefaults.standard.string(forKey: "KhanAcademyCourseId") ?? defaultCourseId
    }
    
    // MARK: - Public Interface
    
    /// Loads content from TimeBack (ae.studio by default, Khan Academy if course ID is set)
    func loadAEStudioLessons() async throws -> [InteractiveLesson] {
        let currentCourseId = courseId
        let isKhanAcademy = currentCourseId.hasPrefix("khan-pre-algebra")
        
        if isKhanAcademy {
            print("🔍 Loading Khan Academy Pre-algebra content from TimeBack...")
        } else {
            print("🔍 Loading ae.studio 3rd Grade Language content from TimeBack...")
        }
        
        // 1. Get the course details
        guard let course = try await courseService.fetchCourse(by: currentCourseId) else {
            throw ContentError.courseNotFound("Course not found: \(currentCourseId)")
        }
        
        print("✅ Found course: \(course.title)")
        
        // 2. Get the syllabus/components
        let syllabus = try await courseService.fetchSyllabus(for: currentCourseId)
        
        print("📋 Syllabus loaded with \(syllabus.components?.count ?? 0) components")
        
        // 3. Convert to InteractiveLessons
        let lessons = convertTimeBackToInteractiveLessons(
            course: course,
            syllabus: syllabus,
            isKhanAcademy: isKhanAcademy
        )
        
        print("🎯 Converted to \(lessons.count) interactive lessons")
        return lessons
    }
    
    // MARK: - Private Methods
    
    private func convertTimeBackToInteractiveLessons(
        course: Course,
        syllabus: Syllabus,
        isKhanAcademy: Bool
    ) -> [InteractiveLesson] {
        
        guard let components = syllabus.components else {
            print("⚠️ No components found in syllabus")
            return []
        }
        
        var lessons: [InteractiveLesson] = []
        
        for (index, component) in components.enumerated() {
            let lessonId = "aestudio-\(component.sourcedId)"
            
            // Create lesson steps from component
            var lessonSteps: [LessonStep] = []
            
            // Add introduction step
            lessonSteps.append(createIntroductionStep(for: component, index: index))
            
            // Add content steps based on component resources
            if let resources = component.resources {
                lessonSteps.append(contentsOf: createContentSteps(from: resources, componentIndex: index))
            }
            
            // Create the interactive lesson
            let lesson = InteractiveLesson(
                id: lessonId,
                title: component.title,
                description: isKhanAcademy ? 
                    "Khan Academy Pre-algebra: \(component.title)" : 
                    "3rd Grade Language lesson from ae.studio: \(component.title)",
                subject: isKhanAcademy ? .algebra : .english,
                gradeLevel: isKhanAcademy ? .g68 : .g35,
                estimatedDuration: estimateDuration(for: component),
                prerequisites: isKhanAcademy ? 
                    ["Basic arithmetic", "Understanding variables"] : 
                    ["Basic reading skills", "Letter recognition"],
                learningObjectives: generateLearningObjectives(for: component, isKhanAcademy: isKhanAcademy),
                content: lessonSteps
            )
            
            lessons.append(lesson)
        }
        
        return lessons
    }
    
    private func createIntroductionStep(for component: CourseComponent, index: Int) -> LessonStep {
        return LessonStep(
            id: "intro-\(component.sourcedId)",
            type: .introduction,
            title: "Welcome to \(component.title)",
            content: .textContent(TextContent(
                text: "Welcome to this 3rd grade language lesson! We'll explore key concepts and practice important skills together.",
                images: []
            )),
            hints: ["Read carefully", "Take your time", "Ask questions if you need help"],
            explanation: "This lesson is part of ae.studio's 3rd grade language curriculum"
        )
    }
    
    private func createContentSteps(from resources: [ComponentResource], componentIndex: Int) -> [LessonStep] {
        var steps: [LessonStep] = []
        
        for (index, resource) in resources.enumerated() {
            let stepId = "aestudio-\(componentIndex)-\(index)"
            
            // Determine step type based on resource metadata
            let stepType: LessonStep.StepType = determineStepType(from: resource)
            
            // Create appropriate content based on resource type
            let content = createStepContent(from: resource)
            
            let step = LessonStep(
                id: stepId,
                type: stepType,
                title: resource.title,
                content: content,
                hints: createHints(for: resource),
                explanation: "This content comes from ae.studio's TimeBack platform"
            )
            
            steps.append(step)
        }
        
        return steps
    }
    
    private func determineStepType(from resource: ComponentResource) -> LessonStep.StepType {
        // Check resource metadata for type hints
        if let metadata = resource.resource.metadata {
            if metadata.type == "video" {
                return .example
            } else if metadata.type == "qti-question" {
                return .practice
            } else if metadata.type == "qti-test" {
                return .practice
            }
        }
        
        // Default based on title/description
        let title = resource.title.lowercased()
        if title.contains("practice") || title.contains("exercise") || title.contains("quiz") {
            return .practice
        } else if title.contains("video") || title.contains("example") {
            return .example
        } else {
            return .introduction
        }
    }
    
    private func createStepContent(from resource: ComponentResource) -> StepContent {
        // Check if it's a video resource
        if let url = resource.resource.metadata?.url, !url.isEmpty {
            // If it's a video URL, create video content
            if url.contains("video") || url.contains("youtube") || url.contains(".mp4") {
                return .videoContent(InteractiveVideoContent(
                    videoURL: url,
                    thumbnailURL: "",
                    transcript: nil
                ))
            }
        }
        
        // Check for QTI content
        if let metadata = resource.resource.metadata,
           let type = metadata.type,
           type.contains("qti") {
            
            // Create a practice question from QTI resource
            let question = createQuestionFromQTI(resource: resource)
            return .interactiveQuestion(question)
        }
        
        // Default to text content
        return .textContent(TextContent(
            text: "Content from ae.studio: \(resource.title)",
            images: []
        ))
    }
    
    private func createQuestionFromQTI(resource: ComponentResource) -> InteractiveQuestion {
        // Create a sample 3rd grade language question
        // In a full implementation, you'd parse the actual QTI content
        
        let questions = [
            ("What is the plural of 'cat'?", "cats"),
            ("Which word rhymes with 'bat'?", "hat"),
            ("What is the opposite of 'big'?", "small"),
            ("How do you spell the word for a furry pet that says 'meow'?", "cat"),
            ("What letter does 'apple' start with?", "A")
        ]
        
        let randomQuestion = questions.randomElement() ?? questions[0]
        
        return InteractiveQuestion(
            id: "aestudio-q-\(resource.sourcedId)",
            question: randomQuestion.0,
            type: .fillInBlank,
            correctAnswer: .text(randomQuestion.1),
            options: nil,
            validation: ValidationRule(
                acceptableAnswers: [.text(randomQuestion.1)],
                tolerance: 0.0,
                caseSensitive: false
            ),
            feedback: QuestionFeedback(
                correct: "Great job! You got it right! 🎉",
                incorrect: "Not quite right. Think about it and try again! 🤔",
                hint: "Think about what you've learned in class.",
                explanation: "This is a fundamental 3rd grade language concept."
            ),
            points: 50
        )
    }
    
    private func createHints(for resource: ComponentResource) -> [String] {
        var hints = ["Take your time", "Read carefully"]
        
        // Add specific hints based on resource type
        if let metadata = resource.resource.metadata,
           let type = metadata.type {
            switch type {
            case "video":
                hints.append("Watch the video to understand the concept")
                hints.append("You can pause and replay if needed")
            case "qti-question", "qti-test":
                hints.append("Think about what you've learned")
                hints.append("Check your spelling")
            default:
                hints.append("This will help you learn important language skills")
            }
        }
        
        return hints
    }
    
    private func estimateDuration(for component: CourseComponent) -> TimeInterval {
        // Estimate based on resources: 3 minutes per resource + 2 minutes intro
        let resourceCount = component.resources?.count ?? 1
        return TimeInterval(resourceCount * 180 + 120) // 3 min per resource + 2 min intro
    }
    
    private func generateLearningObjectives(for component: CourseComponent, isKhanAcademy: Bool = false) -> [String] {
        if isKhanAcademy {
            // Khan Academy math objectives
            return [
                "Master key concepts in \(component.title)",
                "Practice pre-algebra mathematical skills",
                "Apply problem-solving strategies",
                "Build confidence in mathematics"
            ]
        } else {
            // ae.studio language objectives
            return [
                "Understand key concepts in \(component.title)",
                "Practice 3rd grade language skills",
                "Demonstrate learning through interactive exercises",
                "Build confidence in reading and language arts"
            ]
        }
    }
}

// MARK: - Error Types

enum ContentError: Error {
    case courseNotFound(String)
    case syllabusNotFound(String)
    case invalidContent(String)
    
    var localizedDescription: String {
        switch self {
        case .courseNotFound(let message):
            return "Course not found: \(message)"
        case .syllabusNotFound(let message):
            return "Syllabus not found: \(message)"
        case .invalidContent(let message):
            return "Invalid content: \(message)"
        }
    }
}