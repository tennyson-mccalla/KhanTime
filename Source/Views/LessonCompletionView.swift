import SwiftUI

struct LessonCompletionView: View {
    let lesson: InteractiveLesson
    let score: Int
    let totalPossible: Int
    let timeElapsed: TimeInterval
    let userProfile: UserProfile
    let onContinue: () -> Void
    
    @Environment(\.theme) var theme
    @EnvironmentObject var progressManager: ProgressManager
    @State private var showCelebration = false
    @State private var animateScore = false
    @State private var animateStars = false
    @State private var showConfetti = false
    
    private var percentage: Double {
        guard totalPossible > 0 else { return 0 }
        return Double(score) / Double(totalPossible)
    }
    
    private var starCount: Int {
        if percentage >= 0.9 { return 3 }
        else if percentage >= 0.7 { return 2 }
        else if percentage >= 0.5 { return 1 }
        else { return 0 }
    }
    
    private var performanceMessage: String {
        if percentage >= 0.9 { return "Outstanding!" }
        else if percentage >= 0.7 { return "Great job!" }
        else if percentage >= 0.5 { return "Good work!" }
        else { return "Keep practicing!" }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    theme?.backgroundColor ?? Color(.systemGroupedBackground),
                    (theme?.accentColor ?? .blue).opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
            
            ScrollView {
                VStack(spacing: theme?.largeSpacing ?? 24) {
                    Spacer(minLength: 60)
                    
                    // Celebration header
                    celebrationHeader
                    
                    // Level & XP display
                    levelXPDisplay
                    
                    // Score display
                    scoreDisplay
                    
                    // Stars rating
                    starsDisplay
                    
                    // Progress breakdown
                    progressBreakdown
                    
                    // Action buttons
                    actionButtons
                    
                    Spacer(minLength: 40)
                }
                .padding(theme?.standardSpacing ?? 16)
            }
        }
        .onAppear {
            startCelebrationAnimation()
        }
    }
    
    // MARK: - Components
    
    private var celebrationHeader: some View {
        VStack(spacing: theme?.smallSpacing ?? 8) {
            // Trophy/Medal icon
            Image(systemName: starCount >= 3 ? "trophy.fill" : starCount >= 2 ? "medal.fill" : "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(starCount >= 3 ? .yellow : starCount >= 2 ? .orange : theme?.successColor ?? .green)
                .scaleEffect(showCelebration ? 1.2 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.4), value: showCelebration)
            
            Text("Lesson Complete!")
                .font(theme?.titleFont ?? .largeTitle)
                .fontWeight(.bold)
                .foregroundColor(theme?.primaryColor ?? .primary)
                .opacity(showCelebration ? 1 : 0)
                .animation(.easeIn(duration: 0.8).delay(0.3), value: showCelebration)
            
            Text(lesson.title)
                .font(theme?.headingFont ?? .title2)
                .foregroundColor(theme?.secondaryColor ?? .secondary)
                .multilineTextAlignment(.center)
                .opacity(showCelebration ? 1 : 0)
                .animation(.easeIn(duration: 0.8).delay(0.5), value: showCelebration)
        }
    }
    
    private var levelXPDisplay: some View {
        VStack(spacing: theme?.standardSpacing ?? 12) {
            // Level display
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Level \(userProfile.currentLevel)")
                        .font(theme?.headingFont ?? .title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme?.primaryColor ?? .primary)
                    
                    Text("\(userProfile.totalXP) total XP")
                        .font(theme?.bodyFont ?? .body)
                        .foregroundColor(theme?.secondaryColor ?? .secondary)
                }
                
                Spacer()
                
                // XP earned this lesson
                VStack(alignment: .trailing, spacing: 2) {
                    Text("+\(calculateXP()) XP")
                        .font(theme?.headingFont ?? .title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .scaleEffect(animateScore ? 1.2 : 0.8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(1.2), value: animateScore)
                    
                    Text("earned")
                        .font(theme?.captionFont ?? .caption)
                        .foregroundColor(theme?.secondaryColor ?? .secondary)
                }
            }
            
            // XP Progress bar towards next level
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress to Level \(userProfile.currentLevel + 1)")
                        .font(theme?.captionFont ?? .caption)
                        .foregroundColor(theme?.secondaryColor ?? .secondary)
                    
                    Spacer()
                    
                    Text("\(userProfile.xpProgressToNextLevel) / \(userProfile.xpForNextLevel)")
                        .font(theme?.captionFont ?? .caption)
                        .foregroundColor(theme?.secondaryColor ?? .secondary)
                }
                
                ProgressView(value: Double(userProfile.xpProgressToNextLevel), total: Double(userProfile.xpForNextLevel))
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                    .scaleEffect(y: 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme?.cardCornerRadius ?? 16)
                .fill(theme?.surfaceColor ?? Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var scoreDisplay: some View {
        VStack(spacing: theme?.smallSpacing ?? 8) {
            Text(performanceMessage)
                .font(theme?.headingFont ?? .title2)
                .fontWeight(.semibold)
                .foregroundColor(theme?.accentColor ?? .blue)
                .opacity(animateScore ? 1 : 0)
                .animation(.easeIn(duration: 0.6).delay(0.8), value: animateScore)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(theme?.primaryColor ?? .primary)
                    .scaleEffect(animateScore ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(1.0), value: animateScore)
                
                Text("/ \(totalPossible)")
                    .font(theme?.headingFont ?? .title2)
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                    .opacity(animateScore ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(1.3), value: animateScore)
                
                Text("pts")
                    .font(theme?.bodyFont ?? .body)
                    .foregroundColor(theme?.secondaryColor ?? .secondary)
                    .opacity(animateScore ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(1.3), value: animateScore)
            }
            
            // Percentage
            Text("\(Int(percentage * 100))% correct")
                .font(theme?.bodyFont ?? .body)
                .foregroundColor(theme?.secondaryColor ?? .secondary)
                .opacity(animateScore ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(1.5), value: animateScore)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme?.cardCornerRadius ?? 16)
                .fill(theme?.surfaceColor ?? Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var starsDisplay: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < starCount ? "star.fill" : "star")
                    .font(.title)
                    .foregroundColor(index < starCount ? .yellow : .gray.opacity(0.3))
                    .scaleEffect(animateStars && index < starCount ? 1.3 : 1.0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.5)
                        .delay(Double(index) * 0.1 + 1.8),
                        value: animateStars
                    )
            }
        }
    }
    
    private var progressBreakdown: some View {
        VStack(spacing: theme?.standardSpacing ?? 12) {
            // Time taken
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(theme?.accentColor ?? .blue)
                Text("Time: \(formatDuration(timeElapsed))")
                    .font(theme?.bodyFont ?? .body)
                Spacer()
            }
            
            // Steps completed
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(theme?.accentColor ?? .blue)
                Text("\(lesson.content.count) steps completed")
                    .font(theme?.bodyFont ?? .body)
                Spacer()
            }
            
            // Streak information  
            HStack {
                Image(systemName: userProfile.currentStreak > 1 ? "flame.fill" : "flame")
                    .foregroundColor(userProfile.currentStreak > 1 ? .orange : theme?.accentColor ?? .blue)
                Text("\(userProfile.currentStreak) day streak")
                    .font(theme?.bodyFont ?? .body)
                    .fontWeight(userProfile.currentStreak > 1 ? .medium : .regular)
                Spacer()
            }
            
            // Total lessons completed
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(theme?.accentColor ?? .blue)
                Text("\(userProfile.lessonsCompleted) lessons completed")
                    .font(theme?.bodyFont ?? .body)
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme?.cardCornerRadius ?? 12)
                .fill(theme?.surfaceColor ?? Color(.systemBackground))
                .opacity(0.7)
        )
    }
    
    private var actionButtons: some View {
        VStack(spacing: theme?.standardSpacing ?? 12) {
            // Continue button
            Button(action: onContinue) {
                HStack {
                    Text("Back to Lessons")
                    Image(systemName: "arrow.right")
                }
                .font(theme?.buttonFont ?? .headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: theme?.buttonCornerRadius ?? 12)
                        .fill(theme?.accentColor ?? .blue)
                )
                .shadow(color: (theme?.accentColor ?? .blue).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // Review lesson button
            Button(action: {
                // TODO: Implement lesson review
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Review Lesson")
                }
                .font(theme?.buttonFont ?? .headline)
                .foregroundColor(theme?.primaryColor ?? .primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: theme?.buttonCornerRadius ?? 12)
                        .stroke(theme?.primaryColor ?? .gray, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startCelebrationAnimation() {
        // Stagger animations for dramatic effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showCelebration = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            animateScore = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            animateStars = true
        }
        
        // Show confetti for high scores
        if percentage >= 0.7 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showConfetti = true
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    private func calculateXP() -> Int {
        // Base XP + bonus for performance + time bonus
        let baseXP = 50
        let performanceBonus = Int(Double(score) * 0.5)
        let timeBonus = timeElapsed < 60 ? 25 : timeElapsed < 120 ? 15 : 10
        return baseXP + performanceBonus + timeBonus
    }
}

// MARK: - Confetti Animation
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { index in
                ConfettiPiece()
                    .offset(y: animate ? 800 : -100)
                    .animation(
                        .linear(duration: Double.random(in: 2...4))
                        .delay(Double.random(in: 0...2)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    private let shapes: [String] = ["circle.fill", "star.fill", "heart.fill", "diamond.fill"]
    
    @State private var xOffset = Double.random(in: -200...200)
    @State private var rotation = Double.random(in: 0...360)
    @State private var scale = Double.random(in: 0.5...1.5)
    
    var body: some View {
        Image(systemName: shapes.randomElement() ?? "circle.fill")
            .foregroundColor(colors.randomElement() ?? .blue)
            .font(.system(size: 12))
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset)
    }
}

#Preview {
    let sampleLesson = LessonProvider.getBasicAlgebraLessons()[0]
    let sampleProfile = UserProfile(username: "Test User")
    let progressManager = ProgressManager()
    
    LessonCompletionView(
        lesson: sampleLesson,
        score: 400,
        totalPossible: 500,
        timeElapsed: 125,
        userProfile: sampleProfile
    ) {
        print("Continue tapped")
    }
    .environmentObject(ThemePreference())
    .environmentObject(progressManager)
}