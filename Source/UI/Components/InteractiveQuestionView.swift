import SwiftUI
import Combine

struct InteractiveQuestionView: View {
    let question: InteractiveQuestion
    let onAnswerSubmitted: (AnswerValue, Bool) -> Void
    
    @Environment(\.theme) var theme
    @State private var userAnswer: AnswerValue?
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var selectedChoiceIndex: Int?
    @State private var textInput = ""
    @State private var showHint = false
    @State private var currentHintIndex = 0
    @FocusState private var isTextFieldFocused: Bool
    
    // Force view recreation when question changes
    private var questionId: String { question.id }
    
    var isAnswered: Bool {
        userAnswer != nil && showFeedback
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme?.standardSpacing ?? 16) {
            // Question text
            questionHeader
            
            // Question content based on type
            questionContent
            
            // Feedback section
            if showFeedback {
                feedbackView
            }
            
            // Action buttons
            actionButtons
        }
        .padding(theme?.standardSpacing ?? 16)
        .background(theme?.surfaceColor ?? Color(.systemBackground))
        .cornerRadius(theme?.cardCornerRadius ?? 12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            print("🎯 InteractiveQuestionView appeared with question: '\(question.question)'")
            print("🎯 Question type: \(question.type)")
            print("🎯 Expected answer: \(question.correctAnswer)")
            
            // Auto-focus text fields for immediate typing
            if question.type == .fillInBlank || question.type == .equation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    // MARK: - Question Header
    private var questionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.question)
                .font(theme?.headingFont ?? .title2)
                .foregroundColor(theme?.primaryColor ?? .primary)
                .multilineTextAlignment(.leading)
            
            if !isAnswered {
                Text("\(question.points) points")
                    .font(theme?.captionFont ?? .caption)
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
            }
        }
    }
    
    // MARK: - Question Content
    @ViewBuilder
    private var questionContent: some View {
        switch question.type {
        case .multipleChoice:
            multipleChoiceView
        case .fillInBlank:
            fillInBlankView
        case .equation:
            equationView
        case .dragAndDrop:
            dragAndDropView
        case .graphing:
            graphingView
        }
    }
    
    // MARK: - Multiple Choice
    private var multipleChoiceView: some View {
        VStack(spacing: theme?.smallSpacing ?? 8) {
            ForEach(Array((question.options ?? []).enumerated()), id: \.offset) { index, option in
                Button(action: {
                    // Use haptic feedback for immediate tactile response
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    // Update state immediately 
                    selectedChoiceIndex = index
                    userAnswer = .multipleChoice(index)
                }) {
                    HStack {
                        // Choice indicator - optimized for performance
                        ZStack {
                            let isSelected = selectedChoiceIndex == index
                            let strokeColor = isSelected ? (theme?.accentColor ?? .blue) : (theme?.secondaryColor ?? .gray)
                            
                            Circle()
                                .stroke(strokeColor, lineWidth: 2)
                                .frame(width: 24, height: 24)
                            
                            if isSelected {
                                Circle()
                                    .fill(theme?.accentColor ?? .blue)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        
                        // Choice text
                        Text(option)
                            .font(theme?.bodyFont ?? .body)
                            .foregroundColor(theme?.primaryColor ?? .primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(theme?.smallSpacing ?? 12)
                    .background(
                        // Optimized background - pre-calculate values
                        choiceBackground(for: index)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isAnswered)
            }
        }
    }
    
    // MARK: - Fill in Blank
    private var fillInBlankView: some View {
        VStack(alignment: .leading, spacing: theme?.smallSpacing ?? 8) {
            Text("Enter your answer:")
                .font(theme?.bodyFont ?? .body)
                .foregroundColor(theme?.primaryColor ?? .primary)
            
            TextField("Your answer", text: $textInput)
                .textFieldStyle(.roundedBorder)
                .font(theme?.bodyFont ?? .body)
                .keyboardType(isNumericQuestion ? .numbersAndPunctuation : .default)
                .disabled(isAnswered)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .focused($isTextFieldFocused)
                .onChange(of: textInput) { _, newValue in
                    // Immediate update without extra processing
                    if isNumericQuestion {
                        if let number = Double(newValue) {
                            userAnswer = .number(number)
                        } else if !newValue.isEmpty {
                            userAnswer = .text(newValue)
                        } else {
                            userAnswer = nil
                        }
                    } else {
                        userAnswer = newValue.isEmpty ? nil : .text(newValue)
                    }
                }
                .submitLabel(.done)
                .onSubmit {
                    if userAnswer != nil && !isAnswered {
                        submitAnswer()
                    }
                }
        }
    }
    
    // MARK: - Equation View
    private var equationView: some View {
        VStack(alignment: .leading, spacing: theme?.smallSpacing ?? 8) {
            Text("Enter the equation:")
                .font(theme?.bodyFont ?? .body)
                .foregroundColor(theme?.primaryColor ?? .primary)
            
            TextField("Example: x = 5", text: $textInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .disabled(isAnswered)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .focused($isTextFieldFocused)
                .onChange(of: textInput) { _, newValue in
                    userAnswer = newValue.isEmpty ? nil : .equation(newValue)
                }
        }
    }
    
    // MARK: - Drag and Drop (Simplified)
    private var dragAndDropView: some View {
        VStack {
            Text("Drag and drop functionality")
                .font(theme?.bodyFont ?? .body)
                .foregroundColor(theme?.secondaryColor ?? .secondary)
            
            Text("(Feature coming soon)")
                .font(theme?.captionFont ?? .caption)
                .foregroundColor(theme?.secondaryColor ?? .secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Graphing (Simplified)
    private var graphingView: some View {
        VStack {
            Text("Interactive graphing")
                .font(theme?.bodyFont ?? .body)
                .foregroundColor(theme?.secondaryColor ?? .secondary)
            
            Text("(Feature coming soon)")
                .font(theme?.captionFont ?? .caption)
                .foregroundColor(theme?.secondaryColor ?? .secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Feedback View
    private var feedbackView: some View {
        VStack(alignment: .leading, spacing: theme?.smallSpacing ?? 8) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? (theme?.successColor ?? .green) : (theme?.errorColor ?? .red))
                    .font(.title2)
                
                Text(isCorrect ? "Correct!" : "Incorrect")
                    .font(theme?.headingFont ?? .headline)
                    .foregroundColor(isCorrect ? (theme?.successColor ?? .green) : (theme?.errorColor ?? .red))
                
                Spacer()
                
                if isCorrect {
                    Text("+\(question.points)")
                        .font(theme?.buttonFont ?? .headline)
                        .foregroundColor(theme?.successColor ?? .green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill((theme?.successColor ?? .green).opacity(0.1))
                        )
                }
            }
            
            Text(isCorrect ? question.feedback.correct : question.feedback.incorrect)
                .font(theme?.bodyFont ?? .body)
                .foregroundColor(theme?.primaryColor ?? .primary)
            
            if !isCorrect && !question.feedback.explanation.isEmpty {
                Text("Explanation: \(question.feedback.explanation)")
                    .font(theme?.bodyFont ?? .body)
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme?.cardCornerRadius ?? 8)
                .fill(isCorrect ? 
                      (theme?.successColor.opacity(0.1) ?? Color.green.opacity(0.1)) :
                      (theme?.errorColor.opacity(0.1) ?? Color.red.opacity(0.1)))
        )
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: theme?.smallSpacing ?? 12) {
            if !isAnswered {
                HStack(spacing: theme?.smallSpacing ?? 12) {
                    // Hint button
                    Button(action: {
                        showHint = true
                    }) {
                        HStack {
                            Image(systemName: "lightbulb")
                            Text("Hint")
                        }
                        .font(theme?.buttonFont ?? .headline)
                        .foregroundColor(theme?.secondaryColor ?? .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: theme?.buttonCornerRadius ?? 8)
                                .stroke(theme?.secondaryColor ?? .gray, lineWidth: 1)
                        )
                    }
                    .alert("Hint", isPresented: $showHint) {
                        Button("OK") { }
                    } message: {
                        Text(question.feedback.hint)
                    }
                    
                    Spacer()
                    
                    // Submit button - make it more prominent
                    Button(action: {
                        // Immediate haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        submitAnswer()
                    }) {
                        Text("Check Answer")
                            .font(theme?.buttonFont ?? .headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: theme?.buttonCornerRadius ?? 12)
                                    .fill(canSubmit ? (theme?.accentColor ?? .blue) : Color.gray)
                            )
                            .shadow(color: canSubmit ? .blue.opacity(0.3) : .clear, radius: 4)
                    }
                    .disabled(!canSubmit)
                }
                
            }
        }
        .padding(.top, theme?.standardSpacing ?? 16)
    }
    
    // MARK: - Helper Properties & Methods
    
    @ViewBuilder
    private func choiceBackground(for index: Int) -> some View {
        let isSelected = selectedChoiceIndex == index
        let cornerRadius = theme?.cardCornerRadius ?? 8
        let fillColor = isSelected ? (theme?.accentColor.opacity(0.1) ?? Color.blue.opacity(0.1)) : Color.clear
        let strokeColor = isSelected ? (theme?.accentColor ?? .blue) : Color.gray.opacity(0.3)
        let lineWidth: CGFloat = isSelected ? 2 : 1
        
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: lineWidth)
            )
    }
    
    private var isNumericQuestion: Bool {
        switch question.correctAnswer {
        case .number(_):
            return true
        default:
            return false
        }
    }
    
    private var canSubmit: Bool {
        userAnswer != nil
    }
    
    
    private func submitAnswer() {
        guard let answer = userAnswer else { return }
        
        isCorrect = validateAnswer(answer)
        showFeedback = true
        onAnswerSubmitted(answer, isCorrect)
    }
    
    private func validateAnswer(_ answer: AnswerValue) -> Bool {
        let acceptableAnswers = question.validation.acceptableAnswers
        
        for acceptableAnswer in acceptableAnswers {
            if answersMatch(answer, acceptableAnswer) {
                return true
            }
        }
        
        return false
    }
    
    private func answersMatch(_ answer1: AnswerValue, _ answer2: AnswerValue) -> Bool {
        switch (answer1, answer2) {
        case (.text(let text1), .text(let text2)):
            return question.validation.caseSensitive ? 
                text1 == text2 : 
                text1.lowercased() == text2.lowercased()
            
        case (.number(let num1), .number(let num2)):
            let tolerance = question.validation.tolerance ?? 0.01
            return abs(num1 - num2) <= tolerance
            
        case (.multipleChoice(let idx1), .multipleChoice(let idx2)):
            return idx1 == idx2
            
        case (.text(let text), .number(let num)),
             (.number(let num), .text(let text)):
            return Double(text) == num
            
        default:
            return false
        }
    }
}

#Preview {
    let sampleQuestion = InteractiveQuestion(
        id: "sample",
        question: "What is 2 + 3?",
        type: .fillInBlank,
        correctAnswer: .number(5),
        options: nil,
        validation: ValidationRule(
            acceptableAnswers: [.number(5)],
            tolerance: 0.01,
            caseSensitive: false
        ),
        feedback: QuestionFeedback(
            correct: "Great job!",
            incorrect: "Try again!",
            hint: "Add the numbers together",
            explanation: "2 + 3 = 5"
        ),
        points: 100
    )
    
    InteractiveQuestionView(question: sampleQuestion) { answer, isCorrect in
        print("Answer: \(answer), Correct: \(isCorrect)")
    }
    .padding()
}