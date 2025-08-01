import SwiftUI

struct QTIExerciseView: View {
    let exercise: QTIExercise
    @State private var selectedChoices: Set<String> = []
    @State private var textInputs: [String: String] = [:]
    @State private var showResults = false
    @State private var isCorrect = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Exercise \(exercise.currentItem + 1) of \(exercise.items.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let currentItem = exercise.currentQTIItem {
                    // Question Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(currentItem.questionText)
                            .font(.body)
                            .lineLimit(nil)
                        
                        // Interactive Elements
                        if currentItem.type == .multipleChoice {
                            MultipleChoiceSection(
                                choices: currentItem.choices,
                                selectedChoices: $selectedChoices,
                                maxChoices: currentItem.maxChoices
                            )
                        } else if currentItem.type == .fillInBlank {
                            FillInBlankSection(
                                inputCount: currentItem.expectedInputs.count,
                                textInputs: $textInputs
                            )
                        }
                    }
                    
                    // Action Buttons
                    HStack {
                        Button("Check Answer") {
                            checkAnswer(currentItem)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(showResults)
                        
                        if showResults {
                            Button("Next") {
                                moveToNext()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        Button("Exit") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top)
                    
                    // Results
                    if showResults {
                        ResultsView(isCorrect: isCorrect, correctAnswers: currentItem.correctAnswers)
                    }
                }
            }
            .padding()
        }
        .navigationBarHidden(true)
    }
    
    private func checkAnswer(_ item: KhanQTIItem) {
        if item.type == .multipleChoice {
            let correctChoiceSet = Set(item.correctAnswers)
            isCorrect = selectedChoices == correctChoiceSet
        } else if item.type == .fillInBlank {
            let userAnswers = textInputs.values.compactMap { Double($0) }.map { String(Int($0)) }
            let correctAnswers = item.correctAnswers
            isCorrect = userAnswers.sorted() == correctAnswers.sorted()
        }
        
        showResults = true
    }
    
    private func moveToNext() {
        showResults = false
        selectedChoices.removeAll()
        textInputs.removeAll()
        // Note: In a real app, this would update the exercise's current item
        // For this demo, we'll just reset to show the same item
    }
}

struct MultipleChoiceSection: View {
    let choices: [QTIChoice]
    @Binding var selectedChoices: Set<String>
    let maxChoices: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(choices, id: \.id) { choice in
                HStack {
                    Button(action: {
                        if selectedChoices.contains(choice.id) {
                            selectedChoices.remove(choice.id)
                        } else if selectedChoices.count < maxChoices {
                            selectedChoices.insert(choice.id)
                        }
                    }) {
                        HStack {
                            Image(systemName: selectedChoices.contains(choice.id) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedChoices.contains(choice.id) ? .accentColor : .gray)
                            
                            Text(choice.content)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedChoices.contains(choice.id) ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selectedChoices.contains(choice.id) ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

struct FillInBlankSection: View {
    let inputCount: Int
    @Binding var textInputs: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fill in the missing values:")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(0..<inputCount, id: \.self) { index in
                HStack {
                    Text("Answer \(index + 1):")
                        .font(.body)
                    
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

struct ResultsView: View {
    let isCorrect: Bool
    let correctAnswers: [String]
    
    var body: some View {
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
                Text("The correct answers are: \(correctAnswers.joined(separator: ", "))")
                    .font(.body)
                    .foregroundColor(.secondary)
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
}

// MARK: - Data Models

struct QTIExercise {
    let id: String
    let title: String
    let items: [KhanQTIItem]
    var currentItem: Int = 0
    
    var currentQTIItem: KhanQTIItem? {
        guard currentItem >= 0 && currentItem < items.count else { return nil }
        return items[currentItem]
    }
}

struct KhanQTIItem {
    let id: String
    let title: String
    let questionText: String
    let type: QTIType
    let choices: [QTIChoice]
    let expectedInputs: [String]
    let correctAnswers: [String]
    let maxChoices: Int
}

struct QTIChoice {
    let id: String
    let content: String
    let isCorrect: Bool
}

enum QTIType {
    case multipleChoice
    case fillInBlank
    case textEntry
}

// MARK: - Preview

#Preview {
    NavigationView {
        QTIExerciseView(exercise: QTIExercise.sampleFactorPairs)
    }
}

extension QTIExercise {
    static let sampleFactorPairs = QTIExercise(
        id: "xe84a4d8f",
        title: "Factor pairs",
        items: [
            KhanQTIItem(
                id: "x6f16acaa06809dbc",
                title: "Factor pairs - Type 3",
                questionText: "Tyler is cleaning up his 36 toy cars. He wants to put every car in a toy bin, and he wants each bin to have the same number of cars.\n\nUse what you know about factor pairs to complete the table.\n\nNumber of bins | Cars per bin\n1 | 36\n2 | ___\n___ | 12\n4 | ___\n6 | 6",
                type: .fillInBlank,
                choices: [],
                expectedInputs: ["input_0", "input_1", "input_2"],
                correctAnswers: ["18", "3", "9"],
                maxChoices: 0
            ),
            KhanQTIItem(
                id: "x8d8303e4db09c251",
                title: "Factor pairs - Type 1",
                questionText: "Which of the following are factor pairs for 16?",
                type: .multipleChoice,
                choices: [
                    QTIChoice(id: "choice_0", content: "1 and 16", isCorrect: true),
                    QTIChoice(id: "choice_1", content: "2 and 8", isCorrect: true),
                    QTIChoice(id: "choice_2", content: "2 and 16", isCorrect: false),
                    QTIChoice(id: "choice_3", content: "3 and 6", isCorrect: false),
                    QTIChoice(id: "choice_4", content: "4 and 4", isCorrect: true)
                ],
                expectedInputs: [],
                correctAnswers: ["choice_0", "choice_1", "choice_4"],
                maxChoices: 3
            )
        ]
    )
}