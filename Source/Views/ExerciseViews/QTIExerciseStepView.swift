import SwiftUI

struct QTIExerciseStepView: View {
    let exercise: QTIExerciseContent
    let onCompletion: (Bool) -> Void
    
    @State private var selectedChoices: Set<String> = []
    @State private var textInputs: [String: String] = [:]
    @State private var showResults = false
    @State private var isCorrect = false
    @State private var currentItemIndex = 0
    @Environment(\.theme) var theme
    
    var currentItem: QTIExerciseItem? {
        guard currentItemIndex >= 0 && currentItemIndex < exercise.items.count else { return nil }
        return exercise.items[currentItemIndex]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Exercise Header
            exerciseHeader
            
            if let item = currentItem {
                // Question Content
                questionContent(item)
                
                // Interactive Elements
                interactiveElements(item)
                
                // Action Buttons
                actionButtons(item)
                
                // Results
                if showResults {
                    resultsView(item)
                }
            } else {
                Text("No exercise content available")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme?.backgroundColor ?? Color(.systemGroupedBackground))
        )
    }
    
    // MARK: - View Components
    
    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Khan Academy style icon
                Image(systemName: "books.vertical.fill")
                    .font(.title2)
                    .foregroundColor(theme?.accentColor ?? .blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("📚 Khan Academy Exercise")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme?.accentColor ?? .blue)
                    
                    Text(exercise.exerciseTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme?.primaryColor ?? .primary)
                }
                
                Spacer()
            }
            
            if exercise.items.count > 1 {
                HStack {
                    ForEach(0..<exercise.items.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentItemIndex ? (theme?.accentColor ?? .blue) : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer()
                    
                    Text("Problem \(currentItemIndex + 1) of \(exercise.items.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    private func questionContent(_ item: QTIExerciseItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Check if this is a table-based question (Tyler's toy cars)
            if item.questionText.contains("Number of bins") && item.questionText.contains("Cars per bin") {
                tableBasedQuestion(item)
            } else {
                // Regular question text
                Text(item.questionText)
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(theme?.primaryColor ?? .primary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func tableBasedQuestion(_ item: QTIExerciseItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question context
            Text("Tyler is cleaning up his 36 toy cars. He wants to put every car in a toy bin, and he wants each bin to have the same number of cars.")
                .font(.body)
                .foregroundColor(theme?.primaryColor ?? .primary)
                .lineSpacing(4)
            
            Text("Use what you know about factor pairs to complete the table.")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(theme?.accentColor ?? .blue)
            
            // Table representation
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Number of bins")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1)
                    
                    Text("Cars per bin")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                
                // Table rows
                tableRowWithInputs("1", "36", leftInputKey: nil, rightInputKey: nil)
                tableRowWithInputs("2", nil, leftInputKey: nil, rightInputKey: "input_0")
                tableRowWithInputs(nil, "12", leftInputKey: "input_1", rightInputKey: nil)
                tableRowWithInputs("4", nil, leftInputKey: nil, rightInputKey: "input_2")
                tableRowWithInputs("6", "6", leftInputKey: nil, rightInputKey: nil)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .cornerRadius(8)
        }
    }
    
    private func tableRowWithInputs(_ left: String?, _ right: String?, leftInputKey: String?, rightInputKey: String?) -> some View {
        HStack {
            // Left column
            Group {
                if let leftInputKey = leftInputKey {
                    TextField("", text: Binding(
                        get: { textInputs[leftInputKey] ?? "" },
                        set: { textInputs[leftInputKey] = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.body)
                } else if let left = left {
                    Text(left)
                        .font(.body)
                        .foregroundColor(.primary)
                } else {
                    Text("")
                        .font(.body)
                }
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1)
            
            // Right column
            Group {
                if let rightInputKey = rightInputKey {
                    TextField("", text: Binding(
                        get: { textInputs[rightInputKey] ?? "" },
                        set: { textInputs[rightInputKey] = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.body)
                } else if let right = right {
                    Text(right)
                        .font(.body)
                        .foregroundColor(.primary)
                } else {
                    Text("")
                        .font(.body)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .background(Color.clear)
    }
    
    private func tableRow(_ left: String, _ right: String, isComplete: Bool) -> some View {
        HStack {
            Text(left)
                .font(.body)
                .fontWeight(isComplete ? .regular : .semibold)
                .foregroundColor(isComplete ? .primary : (theme?.accentColor ?? .blue))
                .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1)
            
            Text(right)
                .font(.body)
                .fontWeight(isComplete ? .regular : .semibold)
                .foregroundColor(isComplete ? .primary : (theme?.accentColor ?? .blue))
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .background(Color.clear)
    }
    
    @ViewBuilder
    private func interactiveElements(_ item: QTIExerciseItem) -> some View {
        switch item.type {
        case .multipleChoice:
            multipleChoiceSection(item)
        case .fillInBlank:
            fillInBlankSection(item)
        case .textEntry:
            textEntrySection(item)
        }
    }
    
    private func multipleChoiceSection(_ item: QTIExerciseItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(item.choices) { choice in
                Button(action: {
                    if selectedChoices.contains(choice.id) {
                        selectedChoices.remove(choice.id)
                    } else if selectedChoices.count < item.maxChoices {
                        selectedChoices.insert(choice.id)
                    }
                }) {
                    HStack {
                        Image(systemName: selectedChoices.contains(choice.id) ? "checkmark.square.fill" : "square")
                            .foregroundColor(selectedChoices.contains(choice.id) ? (theme?.accentColor ?? .accentColor) : .gray)
                        
                        Text(choice.content)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedChoices.contains(choice.id) ? (theme?.accentColor ?? .accentColor).opacity(0.1) : Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selectedChoices.contains(choice.id) ? (theme?.accentColor ?? .accentColor) : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    private func fillInBlankSection(_ item: QTIExerciseItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // For table-based questions, don't show additional input section since inputs are in the table
            if item.questionText.contains("Number of bins") {
                EmptyView()
            } else {
                Text("Fill in the missing values:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme?.primaryColor ?? .primary)
                
                // Regular input layout for non-table exercises
                ForEach(0..<item.expectedInputs.count, id: \.self) { index in
                    HStack {
                        Text("Answer \(index + 1):")
                            .font(.body)
                            .foregroundColor(theme?.primaryColor ?? .primary)
                        
                        TextField("Enter number", text: Binding(
                            get: { textInputs["input_\(index)"] ?? "" },
                            set: { textInputs["input_\(index)"] = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(maxWidth: 100)
                    }
                }
            }
        }
    }
    
    private func inputRow(_ label: String, index: Int, placeholder: String) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.body)
                .foregroundColor(theme?.primaryColor ?? .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField(placeholder, text: Binding(
                get: { textInputs["input_\(index)"] ?? "" },
                set: { textInputs["input_\(index)"] = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numberPad)
            .frame(width: 80)
            .font(.body)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private func textEntrySection(_ item: QTIExerciseItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter your answer:")
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField("Type your answer here", text: Binding(
                get: { textInputs["text_entry"] ?? "" },
                set: { textInputs["text_entry"] = $0 }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }
    
    private func actionButtons(_ item: QTIExerciseItem) -> some View {
        HStack(spacing: 12) {
            Button(action: { checkAnswer(item) }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Check Answer")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(theme?.accentColor ?? .blue)
                .cornerRadius(10)
            }
            .disabled(showResults)
            .opacity(showResults ? 0.6 : 1.0)
            
            if showResults && (currentItemIndex + 1 < exercise.items.count) {
                Button(action: { moveToNext() }) {
                    HStack {
                        Text("Next Problem")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(.headline)
                    .foregroundColor(theme?.accentColor ?? .blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme?.accentColor ?? .blue, lineWidth: 2)
                    )
                }
            }
            
            Spacer()
        }
        .padding(.top, 16)
    }
    
    private func resultsView(_ item: QTIExerciseItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.title2)
                
                Text(isCorrect ? "Correct!" : "Not quite right")
                    .font(.headline)
                    .foregroundColor(isCorrect ? .green : .red)
            }
            
            if !isCorrect {
                Text("Try again! Review the hints below for help.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Show hints if available
            if !item.hints.isEmpty && !isCorrect {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hints:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(item.hints, id: \.self) { hint in
                        Text("• \(hint)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((isCorrect ? Color.green : Color.red).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCorrect ? Color.green : Color.red, lineWidth: 1)
        )
    }
    
    // MARK: - Actions
    
    private func checkAnswer(_ item: QTIExerciseItem) {
        switch item.type {
        case .multipleChoice:
            let correctChoiceSet = Set(item.correctAnswers)
            isCorrect = selectedChoices == correctChoiceSet
            
        case .fillInBlank:
            let userAnswers = textInputs.values
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
            let correctAnswers = item.correctAnswers.map { $0.lowercased() }
            isCorrect = userAnswers.sorted() == correctAnswers.sorted()
            
        case .textEntry:
            let userAnswer = textInputs["text_entry"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            isCorrect = item.correctAnswers.contains { $0.lowercased() == userAnswer.lowercased() }
        }
        
        showResults = true
        
        // Call completion handler
        onCompletion(isCorrect)
    }
    
    private func moveToNext() {
        if currentItemIndex + 1 < exercise.items.count {
            currentItemIndex += 1
            resetAnswers()
        }
    }
    
    private func resetAnswers() {
        showResults = false
        selectedChoices.removeAll()
        textInputs.removeAll()
        isCorrect = false
    }
}