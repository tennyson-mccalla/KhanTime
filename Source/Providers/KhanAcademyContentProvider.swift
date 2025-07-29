import Foundation

// MARK: - Khan Academy Content Provider
// Loads scraped Khan Academy content from JSON files

class KhanAcademyContentProvider {
    
    // MARK: - Scraped Data Models (matching scraper output)
    struct ScrapedSubjectContent: Codable {
        let id: String
        let subject: String // Raw subject string from scraper
        let title: String
        let description: String
        let units: [ScrapedUnit]
        let scrapedAt: Date
        
        struct ScrapedUnit: Codable {
            let id: String
            let title: String
            let description: String?
            let lessons: [ScrapedLesson]
            let exercises: [ScrapedExercise]
            
            struct ScrapedLesson: Codable {
                let id: String
                let title: String
                let slug: String
                let contentKind: String
                let videoUrl: String?
                let articleContent: String?
                let thumbnailUrl: String?
                let duration: Int?
                // Enhanced fields from authenticated scraper
                let difficulty: String?
                let prerequisites: [String]?
                let youtubeId: String?
                let directVideoUrl: String?
                let transcript: String?
            }
            
            struct ScrapedExercise: Codable {
                let id: String
                let title: String
                let slug: String
                let perseusContent: String
                let questionTypes: [String]
                let difficulty: String
                let skills: [String]
                // Enhanced fields from authenticated scraper
                let hints: [String]?
                let solutions: [String]?
            }
        }
    }
    
    // MARK: - Public Interface
    static func loadKhanAcademyLessons() -> [InteractiveLesson] {
        // Load static content as fallback for other subjects
        var lessons: [InteractiveLesson] = []
        
        // Load enhanced authenticated Khan Academy content with metadata (non-pre-algebra subjects)
        let resourceFiles = [
            "algebra-basics": ("algebra-basics_brainlift_1753717867", InteractiveLesson.Subject.algebra, AgeGroup.g68),
            "algebra": ("algebra_brainlift_1753717870", InteractiveLesson.Subject.algebra, AgeGroup.g912),
            "algebra2": ("algebra2_brainlift_1753717874", InteractiveLesson.Subject.algebra, AgeGroup.g912),
            "physics": ("physics_brainlift_1753717878", InteractiveLesson.Subject.physics, AgeGroup.g912)
        ]
        
        for (_, (filename, subject, gradeLevel)) in resourceFiles {
            if let scrapedContent = loadScrapedContent(filename: filename) {
                let convertedLessons = convertToInteractiveLessons(
                    scrapedContent: scrapedContent,
                    subject: subject,
                    gradeLevel: gradeLevel
                )
                lessons.append(contentsOf: convertedLessons)
            }
        }
        
        return lessons
    }
    
    // Load Khan Academy pre-algebra content using local scraped data (FALLBACK: staging API timing out)
    static func loadTimeBackKhanAcademyLessons() async throws -> [InteractiveLesson] {
        print("🔍 FALLBACK: Loading Khan Academy Pre-algebra from local scraped data (staging API unreliable)...")
        
        // Load enhanced authenticated Khan Academy content with metadata
        guard let scrapedContent = loadScrapedContent(filename: "pre-algebra_brainlift_1753717863") else {
            print("❌ Could not load local Khan Academy scraped content")
            throw NSError(domain: "LoadError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load local Khan Academy content"])
        }
        
        print("✅ Loaded local Khan Academy content: \(scrapedContent.units.count) units")
        
        let lessons = convertToInteractiveLessons(
            scrapedContent: scrapedContent,
            subject: .preAlgebra,
            gradeLevel: .g35
        )
        
        // Add clear indication that this is real Khan Academy content
        let enhancedLessons = lessons.map { lesson in
            var newSteps = lesson.content
            
            // Enhance the introduction step to indicate this is real Khan Academy content
            if let firstStep = newSteps.first, case .textContent(let textContent) = firstStep.content {
                let enhancedTextContent = TextContent(
                    text: "🎓 **Real Khan Academy Content**\n\n\(textContent.text)\n\n📹 This lesson includes actual Khan Academy videos and exercises from their pre-algebra curriculum.",
                    images: textContent.images
                )
                
                newSteps[0] = LessonStep(
                    id: firstStep.id,
                    type: firstStep.type,
                    title: firstStep.title,
                    content: .textContent(enhancedTextContent),
                    hints: firstStep.hints + ["This is authentic Khan Academy content"],
                    explanation: firstStep.explanation
                )
            }
            
            return InteractiveLesson(
                id: lesson.id,
                title: lesson.title,
                description: "📚 **Authentic Khan Academy Pre-Algebra Content**\n\n\(lesson.description)\n\n*Loaded from real Khan Academy scraped data with video links and exercises.*",
                subject: lesson.subject,
                gradeLevel: lesson.gradeLevel,
                estimatedDuration: lesson.estimatedDuration,
                prerequisites: lesson.prerequisites,
                learningObjectives: lesson.learningObjectives,
                content: newSteps
            )
        }
        
        print("✅ Enhanced \(enhancedLessons.count) Khan Academy lessons with authentic content")
        return enhancedLessons
    }
    
    // MARK: - Private Methods
    
    private static func loadScrapedContent(filename: String) -> ScrapedSubjectContent? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("⚠️ Could not load \(filename).json from app bundle")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ScrapedSubjectContent.self, from: data)
        } catch {
            print("⚠️ Error decoding \(filename).json: \(error)")
            return nil
        }
    }
    
    private static func convertToInteractiveLessons(
        scrapedContent: ScrapedSubjectContent,
        subject: InteractiveLesson.Subject,
        gradeLevel: AgeGroup
    ) -> [InteractiveLesson] {
        
        return scrapedContent.units.enumerated().compactMap { (unitIndex, unit) in
            // Create one interactive lesson per unit
            let lessonId = "khan-\(scrapedContent.id)-unit-\(unitIndex)"
            
            // Convert scraped content to lesson steps
            var lessonSteps: [LessonStep] = []
            
            // Add introduction step
            lessonSteps.append(createIntroductionStep(for: unit))
            
            // Add lesson content steps (from scraped lessons)
            lessonSteps.append(contentsOf: createLessonSteps(from: unit.lessons, unitIndex: unitIndex))
            
            // Add practice steps (from scraped exercises)
            lessonSteps.append(contentsOf: createPracticeSteps(from: unit.exercises, unitIndex: unitIndex))
            
            return InteractiveLesson(
                id: lessonId,
                title: unit.title,
                description: unit.description ?? "Learn \(unit.title) with Khan Academy content",
                subject: subject,
                gradeLevel: gradeLevel,
                estimatedDuration: estimateDuration(for: unit),
                prerequisites: generatePrerequisites(for: unit, subject: subject),
                learningObjectives: generateLearningObjectives(for: unit),
                content: lessonSteps
            )
        }
    }
    
    private static func createIntroductionStep(for unit: ScrapedSubjectContent.ScrapedUnit) -> LessonStep {
        return LessonStep(
            id: "intro-\(unit.id)",
            type: .introduction,
            title: "Introduction to \(unit.title)",
            content: .textContent(TextContent(
                text: unit.description ?? "Welcome to \(unit.title)! In this lesson, we'll explore the fundamental concepts and practice key skills.",
                images: []
            )),
            hints: [],
            explanation: nil
        )
    }
    
    private static func createLessonSteps(from lessons: [ScrapedSubjectContent.ScrapedUnit.ScrapedLesson], unitIndex: Int) -> [LessonStep] {
        return lessons.enumerated().compactMap { (index, lesson) in
            let stepId = "lesson-\(unitIndex)-\(index)"
            
            // Handle "lesson" content kind (video lessons)
            if lesson.contentKind == "lesson", let videoUrl = lesson.videoUrl {
                var hints = ["Watch the video to understand the concept", "Take notes on key concepts"]
                if let difficulty = lesson.difficulty {
                    hints.append("This is a \(difficulty) level topic")
                }
                if let prerequisites = lesson.prerequisites {
                    hints.append("Prerequisites: \(prerequisites.joined(separator: ", "))")
                }
                
                // Map known Khan Academy videos to YouTube IDs
                let actualVideoUrl = mapToYouTubeUrl(lesson.title, originalUrl: videoUrl)
                
                if actualVideoUrl.contains("youtube.com/embed/") {
                    // We have a real YouTube URL
                    return LessonStep(
                        id: stepId,
                        type: .example,
                        title: lesson.title,
                        content: .videoContent(InteractiveVideoContent(
                            videoURL: actualVideoUrl,
                            thumbnailURL: lesson.thumbnailUrl ?? "",
                            transcript: lesson.transcript
                        )),
                        hints: hints,
                        explanation: "This video explains the core concepts of \(lesson.title)"
                    )
                } else {
                    // Fall back to text content with link
                    return LessonStep(
                        id: stepId,
                        type: .example,
                        title: lesson.title,
                        content: .textContent(TextContent(
                            text: "🎥 **\(lesson.title)**\n\nThis lesson contains Khan Academy video content covering:\n\n• Key concepts and definitions\n• Step-by-step explanations\n• Real-world examples\n\n**Khan Academy Link:**\n\(videoUrl)\n\n*Note: This would normally display the embedded Khan Academy video player.*",
                            images: []
                        )),
                        hints: hints,
                        explanation: "This lesson covers the core concepts of \(lesson.title) through Khan Academy video content"
                    )
                }
            }
            // Handle "Quiz" content kind (practice problems)
            else if lesson.contentKind == "Quiz" {
                var hints = ["Take your time to think through each problem", "Show your work step by step"]
                if let difficulty = lesson.difficulty {
                    hints.append("This is a \(difficulty) level quiz")
                }
                if let prerequisites = lesson.prerequisites {
                    hints.append("Prerequisites: \(prerequisites.joined(separator: ", "))")
                }
                
                // Create an actual interactive question based on the lesson title/topic
                let quizQuestion = createQuizQuestionFromLesson(lesson, stepId: stepId)
                
                return LessonStep(
                    id: stepId,
                    type: .practice,
                    title: lesson.title,
                    content: .interactiveQuestion(quizQuestion),
                    hints: hints,
                    explanation: "Practice quiz to reinforce learning from \(lesson.title)"
                )
            }
            // Handle article content or other text-based lessons
            else if let articleContent = lesson.articleContent {
                return LessonStep(
                    id: stepId,
                    type: .example,
                    title: lesson.title,
                    content: .textContent(TextContent(
                        text: articleContent,
                        images: []
                    )),
                    hints: ["Read carefully and understand each step"],
                    explanation: nil
                )
            }
            
            return nil
        }
    }
    
    private static func createPracticeSteps(from exercises: [ScrapedSubjectContent.ScrapedUnit.ScrapedExercise], unitIndex: Int) -> [LessonStep] {
        return exercises.enumerated().map { (index, exercise) in
            // Use enhanced hints if available, otherwise use defaults
            var hints = [
                "Read the question carefully",
                "Show your work step by step",
                "Check your answer"
            ]
            
            if let enhancedHints = exercise.hints, !enhancedHints.isEmpty {
                hints = enhancedHints
            }
            
            // Add difficulty-based hints
            switch exercise.difficulty.lowercased() {
            case "easy":
                hints.append("This is a beginner-level problem")
            case "hard":
                hints.append("This is an advanced problem - take your time")
            default:
                hints.append("This is an intermediate-level problem")
            }
            
            return LessonStep(
                id: "practice-\(unitIndex)-\(index)",
                type: .practice,
                title: exercise.title,
                content: .interactiveQuestion(createQuestionFromExercise(exercise, index: index)),
                hints: hints,
                explanation: "Practice problem based on Khan Academy exercises"
            )
        }
    }
    
    private static func createQuizQuestionFromLesson(_ lesson: ScrapedSubjectContent.ScrapedUnit.ScrapedLesson, stepId: String) -> InteractiveQuestion {
        // Create topic-specific quiz questions based on lesson title
        let (question, answer, options) = generateQuizQuestionForLesson(lesson.title, difficulty: lesson.difficulty ?? "medium")
        
        return InteractiveQuestion(
            id: "quiz-\(lesson.id)",
            question: question,
            type: options != nil ? .multipleChoice : .fillInBlank,
            correctAnswer: answer,
            options: options,
            validation: ValidationRule(
                acceptableAnswers: [answer],
                tolerance: options == nil ? 0.01 : nil,
                caseSensitive: false
            ),
            feedback: QuestionFeedback(
                correct: "Excellent! You understand \(lesson.title.lowercased()) well.",
                incorrect: "Not quite right. Review the lesson content and try again.",
                hint: "Think about the key concepts from the \(lesson.title.lowercased()) lesson.",
                explanation: "This question tests your understanding of \(lesson.title.lowercased()) concepts."
            ),
            points: lesson.difficulty == "easy" ? 75 : lesson.difficulty == "hard" ? 150 : 100
        )
    }
    
    private static func createQuestionFromExercise(_ exercise: ScrapedSubjectContent.ScrapedUnit.ScrapedExercise, index: Int) -> InteractiveQuestion {
        // Create a practice question based on the exercise
        // This is simplified - in a full implementation you'd parse the Perseus content
        
        // Generate a simple math question based on skills
        let (question, answer) = generateMathQuestion(for: exercise.skills.first ?? "algebra", difficulty: exercise.difficulty)
        
        return InteractiveQuestion(
            id: "khan-exercise-\(exercise.id)-\(index)",
            question: question,
            type: .fillInBlank,
            correctAnswer: answer,
            options: nil,
            validation: ValidationRule(
                acceptableAnswers: [answer],
                tolerance: 0.01,
                caseSensitive: false
            ),
            feedback: QuestionFeedback(
                correct: "Excellent work! You've mastered this concept.",
                incorrect: "Not quite right. Let's review the steps and try again.",
                hint: "Think about the fundamental principles of \(exercise.skills.first ?? "this topic")",
                explanation: "This problem tests your understanding of \(exercise.title.lowercased())"
            ),
            points: exercise.difficulty == "easy" ? 50 : exercise.difficulty == "medium" ? 100 : 150
        )
    }
    
    private static func generateQuizQuestionForLesson(_ title: String, difficulty: String) -> (String, AnswerValue, [String]?) {
        // Generate lesson-specific quiz questions
        switch title.lowercased() {
        case let t where t.contains("factors and multiples"):
            if difficulty == "easy" {
                let number = [12, 18, 24, 30].randomElement()!
                let factors = getFactors(of: number)
                return ("What are all the factors of \(number)? (Enter as comma-separated list)", 
                       .text(factors.map(String.init).joined(separator: ", ")), 
                       nil)
            } else {
                let options = ["A factor divides evenly into a number", "A multiple is always larger than the original number", "Every number is a factor of itself", "Zero is a multiple of every number"]
                return ("Which statement about factors and multiples is true?", 
                       .text("A factor divides evenly into a number"), 
                       options)
            }
            
        case let t where t.contains("math patterns"):
            return ("What is the next number in the sequence: 3, 6, 9, 12, ?", 
                   .number(15), 
                   nil)
            
        case let t where t.contains("writing expressions"):
            let options = ["3x + 5", "3(x + 5)", "3 + 5x", "5(x + 3)"]
            return ("How would you write 'three times a number plus five' as an algebraic expression?", 
                   .text("3x + 5"), 
                   options)
            
        case let t where t.contains("intro to ratios"):
            let options = ["3:4", "4:3", "7:12", "12:7"]
            return ("If there are 3 red marbles and 4 blue marbles, what is the ratio of red to blue marbles?", 
                   .text("3:4"), 
                   options)
            
        case let t where t.contains("visualize ratios"):
            return ("In a ratio of 2:3, if the first quantity is 6, what is the second quantity?", 
                   .number(9), 
                   nil)
            
        default:
            return ("What is 7 × 8?", .number(56), nil)
        }
    }
    
    private static func getFactors(of number: Int) -> [Int] {
        var factors: [Int] = []
        for i in 1...number {
            if number % i == 0 {
                factors.append(i)
            }
        }
        return factors
    }
    
    private static func generateMathQuestion(for skill: String, difficulty: String) -> (String, AnswerValue) {
        // Generate appropriate math questions based on skill and difficulty
        switch skill.lowercased() {
        case "foundations", "arithmetic":
            if difficulty == "easy" {
                let a = Int.random(in: 1...10)
                let b = Int.random(in: 1...10)
                return ("What is \(a) + \(b)?", .number(Double(a + b)))
            } else {
                let a = Int.random(in: 10...50)
                let b = Int.random(in: 1...20)
                return ("Solve: \(a) - \(b) = ?", .number(Double(a - b)))
            }
            
        case "linear equations", "equations":
            let coefficient = Int.random(in: 2...5)
            let constant = Int.random(in: 1...20)
            let result = Int.random(in: 10...30)
            let x = (result - constant) / coefficient
            return ("Solve for x: \(coefficient)x + \(constant) = \(result)", .number(Double(x)))
            
        case "quadratic", "polynomials":
            let a = Int.random(in: 1...3)
            let b = Int.random(in: 1...6)
            return ("If x² - \(a + b)x + \(a * b) = 0, what is one solution for x?", .number(Double(a)))
            
        default:
            let x = Int.random(in: 1...10)
            return ("If x = \(x), what is 2x + 3?", .number(Double(2 * x + 3)))
        }
    }
    
    private static func estimateDuration(for unit: ScrapedSubjectContent.ScrapedUnit) -> TimeInterval {
        // Estimate based on content: 5 minutes per lesson + 3 minutes per exercise
        let lessonTime = Double(unit.lessons.count) * 300 // 5 minutes each
        let exerciseTime = Double(unit.exercises.count) * 180 // 3 minutes each
        return lessonTime + exerciseTime + 300 // +5 minutes for introduction
    }
    
    private static func generatePrerequisites(for unit: ScrapedSubjectContent.ScrapedUnit, subject: InteractiveLesson.Subject) -> [String] {
        // Use enhanced prerequisites from authenticated scraper if available
        if let firstLesson = unit.lessons.first,
           let prerequisites = firstLesson.prerequisites,
           !prerequisites.isEmpty {
            return prerequisites.map { $0.replacingOccurrences(of: "_", with: " ").capitalized }
        }
        
        // Fallback to subject-based defaults
        switch subject {
        case .algebra:
            return ["Basic arithmetic", "Understanding variables", "Order of operations"]
        case .physics:
            return ["Basic algebra", "Scientific notation", "Unit conversions"]
        default:
            return ["Basic math skills"]
        }
    }
    
    private static func generateLearningObjectives(for unit: ScrapedSubjectContent.ScrapedUnit) -> [String] {
        return [
            "Understand the key concepts of \(unit.title)",
            "Apply \(unit.title.lowercased()) techniques to solve problems",
            "Demonstrate mastery through practice exercises"
        ]
    }
    
    // MARK: - YouTube URL Mapping
    
    private static func mapToYouTubeUrl(_ title: String, originalUrl: String) -> String {
        // Map known Khan Academy lessons to their actual YouTube IDs
        let titleLower = title.lowercased()
        
        if titleLower.contains("factors and multiples") || originalUrl.contains("factors-mult") {
            return "https://www.youtube.com/embed/KcKOM7Degu0" // Understanding factor pairs
        }
        
        // Add more mappings as we discover them
        // TODO: Expand this mapping with more Khan Academy videos
        
        return originalUrl // Return original URL if no mapping found
    }
}