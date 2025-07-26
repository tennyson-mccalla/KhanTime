import Foundation

// MARK: - Interactive Lesson Data Models
// Mock Khan Academy-style content structure

struct InteractiveLesson: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let subject: Subject
    let gradeLevel: AgeGroup
    let estimatedDuration: TimeInterval // In seconds for 2-hour tracking
    let prerequisites: [String]
    let learningObjectives: [String]
    let content: [LessonStep]
    
    enum Subject: String, CaseIterable, Codable {
        case algebra = "Algebra"
        case geometry = "Geometry"
        case statistics = "Statistics"
        case calculus = "Calculus"
        case physics = "Physics"
        case chemistry = "Chemistry"
    }
}

struct LessonStep: Identifiable, Codable {
    let id: String
    let type: StepType
    let title: String
    let content: StepContent
    let hints: [String]
    let explanation: String?
    
    enum StepType: String, Codable {
        case introduction = "introduction"
        case example = "example"
        case practice = "practice"
        case assessment = "assessment"
    }
}

enum StepContent: Codable {
    case textContent(TextContent)
    case videoContent(VideoContent)
    case interactiveQuestion(InteractiveQuestion)
    case multiStepProblem(MultiStepProblem)
}

struct TextContent: Codable {
    let text: String
    let images: [String] // Image URLs or asset names
}

struct VideoContent: Codable {
    let videoURL: String
    let thumbnailURL: String
    let transcript: String?
}

struct InteractiveQuestion: Identifiable, Codable {
    let id: String
    let question: String
    let type: QuestionType
    let correctAnswer: AnswerValue
    let options: [String]? // For multiple choice
    let validation: ValidationRule
    let feedback: QuestionFeedback
    let points: Int
}

enum QuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case fillInBlank = "fill_in_blank"
    case dragAndDrop = "drag_and_drop"
    case graphing = "graphing"
    case equation = "equation"
}

enum AnswerValue: Codable {
    case text(String)
    case number(Double)
    case multipleChoice(Int) // Index
    case coordinates(x: Double, y: Double)
    case equation(String)
}

struct ValidationRule: Codable {
    let acceptableAnswers: [AnswerValue]
    let tolerance: Double? // For numeric answers
    let caseSensitive: Bool
}

struct QuestionFeedback: Codable {
    let correct: String
    let incorrect: String
    let hint: String
    let explanation: String
}

struct MultiStepProblem: Identifiable, Codable {
    let id: String
    let problemStatement: String
    let steps: [InteractiveQuestion]
    let finalAnswer: AnswerValue
}

// MARK: - Mock Data Generator
class MockLessonProvider {
    static func getBasicAlgebraLessons() -> [InteractiveLesson] {
        return [
            createSolvingLinearEquationsLesson(),
            createQuadraticEquationsLesson(),
            createSystemsOfEquationsLesson()
        ]
    }
    
    private static func createSolvingLinearEquationsLesson() -> InteractiveLesson {
        return InteractiveLesson(
            id: "linear-equations-101",
            title: "Solving Linear Equations",
            description: "Learn to solve linear equations with one variable using algebraic methods",
            subject: .algebra,
            gradeLevel: .g68,
            estimatedDuration: 1800, // 30 minutes
            prerequisites: ["Basic arithmetic", "Understanding variables"],
            learningObjectives: [
                "Solve linear equations using addition and subtraction",
                "Solve linear equations using multiplication and division",
                "Apply the distributive property to solve equations"
            ],
            content: [
                // Introduction step
                LessonStep(
                    id: "intro-1",
                    type: .introduction,
                    title: "What is a Linear Equation?",
                    content: .textContent(TextContent(
                        text: "A linear equation is an equation where the highest power of the variable is 1. For example: 2x + 5 = 11\n\nOur goal is to find the value of x that makes this equation true.",
                        images: []
                    )),
                    hints: [],
                    explanation: nil
                ),
                
                // Example step
                LessonStep(
                    id: "example-1",
                    type: .example,
                    title: "Solving x + 3 = 8",
                    content: .textContent(TextContent(
                        text: "Let's solve x + 3 = 8 step by step:\n\nStep 1: Subtract 3 from both sides\nx + 3 - 3 = 8 - 3\n\nStep 2: Simplify\nx = 5\n\nWe can check: 5 + 3 = 8 ✓",
                        images: []
                    )),
                    hints: ["What operation cancels out addition?", "Remember to do the same thing to both sides"],
                    explanation: "We subtract 3 because it's the opposite of adding 3, which isolates x."
                ),
                
                // Practice question 1
                LessonStep(
                    id: "practice-1",
                    type: .practice,
                    title: "Your turn: Solve x + 7 = 12",
                    content: .interactiveQuestion(InteractiveQuestion(
                        id: "q1",
                        question: "Solve for x: x + 7 = 12",
                        type: .fillInBlank,
                        correctAnswer: .number(5),
                        options: nil,
                        validation: ValidationRule(
                            acceptableAnswers: [.number(5), .text("5")],
                            tolerance: 0.01,
                            caseSensitive: false
                        ),
                        feedback: QuestionFeedback(
                            correct: "Excellent! x = 5 is correct. You subtracted 7 from both sides.",
                            incorrect: "Not quite. Remember to subtract 7 from both sides of the equation.",
                            hint: "What number plus 7 equals 12?",
                            explanation: "x + 7 = 12, so x = 12 - 7 = 5"
                        ),
                        points: 100
                    )),
                    hints: ["Subtract 7 from both sides", "12 - 7 = ?"],
                    explanation: "To isolate x, we need to 'undo' the +7 by subtracting 7 from both sides."
                ),
                
                // Practice question 2
                LessonStep(
                    id: "practice-2",
                    type: .practice,
                    title: "Multiple Choice: Solve 2x = 16",
                    content: .interactiveQuestion(InteractiveQuestion(
                        id: "q2",
                        question: "What is the value of x in the equation 2x = 16?",
                        type: .multipleChoice,
                        correctAnswer: .multipleChoice(1), // Index 1 = "8"
                        options: ["4", "8", "32", "2"],
                        validation: ValidationRule(
                            acceptableAnswers: [.multipleChoice(1)],
                            tolerance: nil,
                            caseSensitive: false
                        ),
                        feedback: QuestionFeedback(
                            correct: "Perfect! x = 8. You divided both sides by 2.",
                            incorrect: "Try again. To solve 2x = 16, divide both sides by 2.",
                            hint: "2 times what number equals 16?",
                            explanation: "2x = 16 means 2 × x = 16, so x = 16 ÷ 2 = 8"
                        ),
                        points: 100
                    )),
                    hints: ["Divide both sides by 2", "16 ÷ 2 = ?"],
                    explanation: "When x is multiplied by 2, we divide by 2 to isolate x."
                ),
                
                // Assessment
                LessonStep(
                    id: "assessment-1",
                    type: .assessment,
                    title: "Challenge: Solve 3x - 4 = 11",
                    content: .interactiveQuestion(InteractiveQuestion(
                        id: "q3",
                        question: "Solve for x: 3x - 4 = 11",
                        type: .fillInBlank,
                        correctAnswer: .number(5),
                        options: nil,
                        validation: ValidationRule(
                            acceptableAnswers: [.number(5), .text("5")],
                            tolerance: 0.01,
                            caseSensitive: false
                        ),
                        feedback: QuestionFeedback(
                            correct: "Outstanding! x = 5. You used multiple steps to solve this equation.",
                            incorrect: "This is a multi-step equation. Try adding 4 to both sides first, then dividing by 3.",
                            hint: "First, add 4 to both sides to get 3x = 15",
                            explanation: "3x - 4 = 11 → 3x = 15 → x = 5"
                        ),
                        points: 200
                    )),
                    hints: ["Add 4 to both sides first", "Then divide by 3", "Check: 3(5) - 4 = 15 - 4 = 11 ✓"],
                    explanation: "Multi-step equations require us to undo operations in reverse order."
                )
            ]
        )
    }
    
    private static func createQuadraticEquationsLesson() -> InteractiveLesson {
        return InteractiveLesson(
            id: "quadratic-equations-101",
            title: "Introduction to Quadratic Equations",
            description: "Learn to identify and solve simple quadratic equations",
            subject: .algebra,
            gradeLevel: .g912,
            estimatedDuration: 2400, // 40 minutes
            prerequisites: ["Linear equations", "FOIL method", "Square roots"],
            learningObjectives: [
                "Identify quadratic equations",
                "Solve quadratic equations by factoring",
                "Use the quadratic formula"
            ],
            content: [
                LessonStep(
                    id: "quad-intro",
                    type: .introduction,
                    title: "What is a Quadratic Equation?",
                    content: .textContent(TextContent(
                        text: "A quadratic equation has the form ax² + bx + c = 0, where a ≠ 0.\n\nExamples:\n• x² - 5x + 6 = 0\n• 2x² - 8 = 0\n• x² + 4x = 0",
                        images: []
                    )),
                    hints: [],
                    explanation: nil
                ),
                
                LessonStep(
                    id: "quad-practice-1",
                    type: .practice,
                    title: "Solve by Factoring: x² - 5x + 6 = 0",
                    content: .interactiveQuestion(InteractiveQuestion(
                        id: "quad-q1",
                        question: "What are the solutions to x² - 5x + 6 = 0? (Enter the smaller solution)",
                        type: .fillInBlank,
                        correctAnswer: .number(2),
                        options: nil,
                        validation: ValidationRule(
                            acceptableAnswers: [.number(2), .text("2")],
                            tolerance: 0.01,
                            caseSensitive: false
                        ),
                        feedback: QuestionFeedback(
                            correct: "Correct! x = 2 is one solution. The other is x = 3.",
                            incorrect: "Try factoring: look for two numbers that multiply to 6 and add to -5.",
                            hint: "Factor as (x - ?)(x - ?) = 0",
                            explanation: "x² - 5x + 6 = (x - 2)(x - 3) = 0, so x = 2 or x = 3"
                        ),
                        points: 150
                    )),
                    hints: ["Look for factors of 6 that add to -5", "-2 and -3 work!", "So (x - 2)(x - 3) = 0"],
                    explanation: "When a product equals zero, at least one factor must be zero."
                )
            ]
        )
    }
    
    private static func createSystemsOfEquationsLesson() -> InteractiveLesson {
        return InteractiveLesson(
            id: "systems-equations-101",
            title: "Systems of Linear Equations",
            description: "Learn to solve systems of equations using substitution and elimination",
            subject: .algebra,
            gradeLevel: .g912,
            estimatedDuration: 2700, // 45 minutes
            prerequisites: ["Linear equations", "Graphing lines"],
            learningObjectives: [
                "Solve systems using substitution method",
                "Solve systems using elimination method",
                "Interpret solutions graphically"
            ],
            content: [
                LessonStep(
                    id: "systems-intro",
                    type: .introduction,
                    title: "What is a System of Equations?",
                    content: .textContent(TextContent(
                        text: "A system of equations is a set of equations with the same variables.\n\nExample:\nx + y = 5\n2x - y = 1\n\nWe need to find values of x and y that satisfy both equations.",
                        images: []
                    )),
                    hints: [],
                    explanation: nil
                ),
                
                LessonStep(
                    id: "systems-practice-1",
                    type: .practice,
                    title: "Solve the System",
                    content: .interactiveQuestion(InteractiveQuestion(
                        id: "sys-q1",
                        question: "Solve the system:\nx + y = 7\nx - y = 1\n\nWhat is the value of x?",
                        type: .fillInBlank,
                        correctAnswer: .number(4),
                        options: nil,
                        validation: ValidationRule(
                            acceptableAnswers: [.number(4), .text("4")],
                            tolerance: 0.01,
                            caseSensitive: false
                        ),
                        feedback: QuestionFeedback(
                            correct: "Excellent! x = 4. And y = 3 completes the solution.",
                            incorrect: "Try adding the equations together to eliminate y.",
                            hint: "Add the equations: (x + y) + (x - y) = 7 + 1",
                            explanation: "Adding gives 2x = 8, so x = 4. Then y = 7 - 4 = 3."
                        ),
                        points: 150
                    )),
                    hints: ["Add the equations to eliminate y", "2x = 8", "So x = 4"],
                    explanation: "Elimination method: add or subtract equations to eliminate one variable."
                )
            ]
        )
    }
}