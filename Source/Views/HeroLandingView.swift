import SwiftUI
import AVKit

struct HeroLandingView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var themePreference: ThemePreference
    @Environment(\.theme) var theme
    
    @State private var navigateToMainApp = false
    @State private var showAgeSelector = false
    @State private var selectedAge: AgeGroup = .g68
    @State private var animateContent = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background layer with gradient
                backgroundLayer
                
                // Main content overlay
                contentLayer
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Floating navigation
                floatingNavigation
            }
            .ignoresSafeArea(.all)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                    animateContent = true
                }
            }
            .onChange(of: viewModel.isAuthenticated) {
                if viewModel.isAuthenticated {
                    navigateToMainApp = true
                }
            }
            .fullScreenCover(isPresented: $navigateToMainApp) {
                DashboardView()
            }
        }
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        ZStack {
            // Primary gradient background
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated mathematical elements
            animatedMathBackground
            
            // Subtle overlay for text readability
            Color.black.opacity(0.2)
        }
    }
    
    // MARK: - Animated Math Background
    private var animatedMathBackground: some View {
        ZStack {
            // Floating mathematical symbols
            ForEach(0..<8, id: \.self) { index in
                mathSymbol(at: index)
            }
        }
    }
    
    private func mathSymbol(at index: Int) -> some View {
        let symbols = ["∑", "∫", "π", "√", "∆", "∞", "α", "β"]
        let positions = [
            CGPoint(x: 0.1, y: 0.2), CGPoint(x: 0.9, y: 0.3),
            CGPoint(x: 0.2, y: 0.7), CGPoint(x: 0.8, y: 0.8),
            CGPoint(x: 0.15, y: 0.5), CGPoint(x: 0.85, y: 0.6),
            CGPoint(x: 0.3, y: 0.15), CGPoint(x: 0.7, y: 0.9)
        ]
        
        return Text(symbols[index])
            .font(.system(size: 40, weight: .ultraLight, design: .serif))
            .foregroundColor(.white.opacity(0.1))
            .position(x: UIScreen.main.bounds.width * positions[index].x,
                     y: UIScreen.main.bounds.height * positions[index].y)
            .rotationEffect(.degrees(animateContent ? 360 : 0))
            .animation(.linear(duration: 20).repeatForever(autoreverses: false).delay(Double(index) * 0.5), value: animateContent)
    }
    
    // MARK: - Content Layer
    private var contentLayer: some View {
        HStack {
            // Main hero content (left side)
            VStack(alignment: .leading, spacing: 24) {
                Spacer()
                
                heroTitle
                
                heroSubtitle
                
                ctaButton
                
                Spacer()
                Spacer()
            }
            .padding(.leading, 60)
            .opacity(animateContent ? 1 : 0)
            .offset(x: animateContent ? 0 : -50)
            .animation(.easeOut(duration: 1.0).delay(0.8), value: animateContent)
            
            Spacer()
            
            // Right side decorative elements
            rightSideElements
        }
    }
    
    // MARK: - Hero Title
    private var heroTitle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Learn Anything")
                .font(.system(size: 64, weight: .light, design: .serif))
                .foregroundColor(.white)
                .tracking(-1)
            
            Text("in 2 Hours")
                .font(.system(size: 64, weight: .light, design: .serif))
                .foregroundColor(accentColor)
                .tracking(-1)
        }
        .lineLimit(nil)
        .multilineTextAlignment(.leading)
    }
    
    // MARK: - Hero Subtitle
    private var heroSubtitle: some View {
        Text("Master any subject with Alpha School's proven methodology. From basic algebra to advanced calculus, unlock your potential through focused, efficient learning.")
            .font(.system(size: 18, weight: .regular, design: .rounded))
            .foregroundColor(.white.opacity(0.8))
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: 500, alignment: .leading)
    }
    
    // MARK: - CTA Button
    private var ctaButton: some View {
        Button(action: {
            if viewModel.isLoading {
                return
            }
            viewModel.login()
        }) {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Text("Start Learning")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .foregroundColor(.black)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading)
        .scaleEffect(animateContent ? 1 : 0.8)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2), value: animateContent)
    }
    
    // MARK: - Right Side Elements
    private var rightSideElements: some View {
        VStack {
            Spacer()
            
            // Vertical text label
            Text("CHAPTER ONE")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(4)
                .rotationEffect(.degrees(90))
                .padding(.trailing, 40)
            
            Spacer()
            
            // Bottom right copyright
            Text("© KhanTime 2025")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .padding(.trailing, 40)
                .padding(.bottom, 40)
        }
        .opacity(animateContent ? 1 : 0)
        .animation(.easeOut(duration: 1.0).delay(1.5), value: animateContent)
    }
    
    // MARK: - Floating Navigation
    private var floatingNavigation: some View {
        VStack {
            HStack {
                // Left: KhanTime logo/brand
                HStack(spacing: 12) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text("KhanTime")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Right: Age group selector
                Button(action: {
                    showAgeSelector = true
                }) {
                    HStack(spacing: 8) {
                        Text(selectedAge.displayName)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            
            Spacer()
            
            // Bottom left: Founded text
            HStack {
                Text("✦ Founded in Learning, 2025")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.leading, 32)
                    .padding(.bottom, 32)
                
                Spacer()
            }
        }
        .opacity(animateContent ? 1 : 0)
        .animation(.easeOut(duration: 1.0).delay(1.8), value: animateContent)
        .actionSheet(isPresented: $showAgeSelector) {
            ActionSheet(
                title: Text("Select Your Grade Level"),
                buttons: AgeGroup.allCases.map { age in
                    .default(Text(age.displayName)) {
                        selectedAge = age
                        themePreference.selectedAgeGroup = age
                    }
                } + [.cancel()]
            )
        }
    }
    
    // MARK: - Theme-based Properties
    private var gradientColors: [Color] {
        switch selectedAge {
        case .k2:
            return [Color.purple.opacity(0.8), Color.pink.opacity(0.6), Color.orange.opacity(0.4)]
        case .g35:
            return [Color.blue.opacity(0.8), Color.teal.opacity(0.6), Color.green.opacity(0.4)]
        case .g68:
            return [Color.indigo.opacity(0.8), Color.blue.opacity(0.6), Color.cyan.opacity(0.4)]
        case .g912:
            return [Color.black.opacity(0.9), Color.gray.opacity(0.7), Color.blue.opacity(0.3)]
        }
    }
    
    private var accentColor: Color {
        switch selectedAge {
        case .k2: return .yellow
        case .g35: return .mint
        case .g68: return .cyan
        case .g912: return .white
        }
    }
}

// MARK: - Age Group Extension
extension AgeGroup {
    var displayName: String {
        switch self {
        case .k2: return "K-2"
        case .g35: return "3-5"
        case .g68: return "6-8"
        case .g912: return "9-12"
        }
    }
}

#Preview {
    HeroLandingView()
        .environmentObject(ThemePreference())
}