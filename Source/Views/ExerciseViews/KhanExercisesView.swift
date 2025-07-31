import SwiftUI

struct KhanExercisesView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var themePreference: ThemePreference
    @State private var selectedExercise: QTIExercise?
    @State private var showExercise = false
    
    // Sample Khan Academy exercises converted from Perseus
    private let exercises: [QTIExercise] = [
        QTIExercise.sampleFactorPairs,
        // Add more exercises here as they are converted
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Khan Academy Exercises")
                            .font(.title)
                            .fontWeight(.bold)
                            .themedWithPreference(themePreference)
                        
                        Text("Pre-Algebra • Unit 1: Factors and Multiples")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    // Exercise Cards
                    ForEach(exercises, id: \.id) { exercise in
                        ExerciseCard(exercise: exercise) {
                            selectedExercise = exercise
                            showExercise = true
                        }
                        .themedWithPreference(themePreference)
                        .padding(.horizontal)
                    }
                    
                    // Coming Soon Section  
                    VStack(spacing: 12) {
                        Text("More exercises coming soon!")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("We're working on converting additional Khan Academy exercises from Perseus format to QTI 3.0. Check back soon for more practice problems.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .padding(.horizontal)
                    .padding(.top, 32)
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showExercise) {
                if let exercise = selectedExercise {
                    QTIExerciseView(exercise: exercise)
                }
            }
        }
    }
}

struct ExerciseCard: View {
    let exercise: QTIExercise
    let action: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(.plain)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            previewSection
            typeIndicators
        }
        .padding(16)
        .background(cardBackground)
        .overlay(cardBorder)
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(exercise.items.count) problem\(exercise.items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(.accentColor)
                .font(.title2)
        }
    }
    
    @ViewBuilder
    private var previewSection: some View {
        if let firstItem = exercise.items.first {
            Text(firstItem.questionText)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var typeIndicators: some View {
        HStack {
            let uniqueTypes = Array(Set(exercise.items.map(\.type)))
            ForEach(uniqueTypes, id: \.self) { type in
                ExerciseTypeTag(type: type)
            }
            
            Spacer()
            
            qtiLabel
        }
    }
    
    private var qtiLabel: some View {
        Text("QTI 3.0")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(4)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
    }
}

struct ExerciseTypeTag: View {
    let type: QTIType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconForType)
                .font(.caption2)
            
            Text(labelForType)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(colorForType.opacity(0.1))
        .foregroundColor(colorForType)
        .cornerRadius(4)
    }
    
    private var iconForType: String {
        switch type {
        case .multipleChoice:
            return "checkmark.square"
        case .fillInBlank:
            return "rectangle.and.pencil.and.ellipsis"
        case .textEntry:
            return "text.cursor"
        }
    }
    
    private var labelForType: String {
        switch type {
        case .multipleChoice:
            return "Multiple Choice"
        case .fillInBlank:
            return "Fill in Blank"
        case .textEntry:
            return "Text Entry"
        }
    }
    
    private var colorForType: Color {
        switch type {
        case .multipleChoice:
            return .green
        case .fillInBlank:
            return .orange
        case .textEntry:
            return .purple
        }
    }
}

#Preview {
    NavigationView {
        KhanExercisesView()
    }
    .environmentObject(ThemePreference())
}