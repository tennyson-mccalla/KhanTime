import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var themePreference: ThemePreference
    @Environment(\.theme) var theme
    @State private var showThemeSettings = false
    @State private var showInteractiveLessons = false

        var body: some View {
        NavigationStack {
            dashboardContent
                .navigationTitle("My Courses")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            print("Creating test course...")
                            viewModel.createTestCourse()
                        }) {
                            Label("Create Test Course", systemImage: "plus.circle")
                        }
                        Button(action: {
                            print("Navigate to API Explorer tapped")
                            viewModel.showAPIExplorer = true
                        }) {
                            Label("API Explorer", systemImage: "server.rack")
                        }
                        Button(action: {
                            print("Navigate to Content Creator tapped")
                            viewModel.showContentCreator = true
                        }) {
                            Label("Content Creator", systemImage: "doc.badge.plus")
                        }
                        Button(action: {
                            print("Navigate to Interactive Lessons tapped")
                            showInteractiveLessons = true
                        }) {
                            Label("Interactive Lessons", systemImage: "brain.head.profile")
                        }
                        Divider()
                        Button(action: {
                            showThemeSettings = true
                        }) {
                            Label("Theme Settings", systemImage: "paintbrush.fill")
                        }
                        Button(action: {
                            viewModel.loadCourses()
                        }) {
                            Label("Refresh Courses", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Sort by", selection: $viewModel.sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
            }
            .onAppear {
                // Load courses when the view first appears
                if viewModel.courses.isEmpty {
                    viewModel.loadCourses()
                }
            }
            .navigationDestination(isPresented: $viewModel.showAPIExplorer) {
                APIExplorerView()
            }
            .navigationDestination(isPresented: $viewModel.showContentCreator) {
                ContentView()
            }
            .sheet(isPresented: $showThemeSettings) {
                ThemeSettingsView()
            }
            .fullScreenCover(isPresented: $showInteractiveLessons) {
                InteractiveLessonsBrowserView()
            }
        }
    }

    @ViewBuilder
    private var dashboardContent: some View {
        VStack {
            if viewModel.isLoading {
                if let theme = theme {
                    // Use theme-specific loading indicator with bypass option
                    VStack(spacing: theme.standardSpacing) {
                        loadingIndicator(for: theme)
                        Text("Loading Courses...")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.primaryColor)
                            .padding(.top, theme.smallSpacing)
                        
                        Text("TimeBack staging API is slow...")
                            .font(theme.captionFont)
                            .foregroundColor(theme.secondaryColor)
                            .padding(.top, 4)
                        
                        // Bypass button to go directly to Interactive Lessons
                        Button(action: {
                            showInteractiveLessons = true
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                Text("Skip to Khan Academy Content")
                            }
                            .font(theme.buttonFont)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(theme.accentColor)
                            .cornerRadius(theme.buttonCornerRadius)
                        }
                        .padding(.top, theme.standardSpacing)
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView("Loading Courses...")
                        
                        Text("API is slow...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showInteractiveLessons = true
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                Text("Skip to Khan Academy Content")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.blue)
                            .cornerRadius(10)
                        }
                    }
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: theme?.standardSpacing ?? 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(theme?.errorColor ?? .red)

                    Text(errorMessage)
                        .font(theme?.bodyFont ?? .body)
                        .foregroundColor(theme?.errorColor ?? .red)
                        .multilineTextAlignment(.center)
                    
                    Text("TimeBack staging API is experiencing issues")
                        .font(theme?.captionFont ?? .caption)
                        .foregroundColor(theme?.secondaryColor ?? .secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Button(action: { viewModel.loadCourses() }) {
                            Text("Retry")
                                .font(theme?.buttonFont ?? .headline)
                        }
                        .buttonStyle(theme?.buttonStyle ?? AnyButtonStyle(DefaultButtonStyle()))
                        .frame(maxWidth: 120)
                        
                        Button(action: {
                            showInteractiveLessons = true
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                Text("Khan Academy")
                            }
                            .font(theme?.buttonFont ?? .headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(theme?.accentColor ?? .blue)
                            .cornerRadius(theme?.buttonCornerRadius ?? 8)
                        }
                    }
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: theme?.largeSpacing ?? 24) {
                        // Featured Interactive Lessons Section
                        featuredInteractiveLessonsCard
                        
                        // Courses Grid
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: theme?.standardSpacing ?? 16) {
                            ForEach(viewModel.courses) { course in
                            NavigationLink(destination: SyllabusView(course: course)) {
                                CourseCard(course: course)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .simultaneousGesture(
                                TapGesture()
                                    .onEnded { _ in
                                        print("Navigating to course: \(course.title)")
                                    }
                            )
                        }
                        }
                    }
                    .padding(theme?.standardSpacing ?? 16)
                }
                .background(theme?.backgroundColor ?? Color(.systemBackground))
                .refreshable {
                    viewModel.loadCourses()
                }
            }
        }
    }

    // MARK: - Featured Interactive Lessons Card
    private var featuredInteractiveLessonsCard: some View {
        Button(action: {
            showInteractiveLessons = true
        }) {
            VStack(alignment: .leading, spacing: theme?.standardSpacing ?? 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundColor(theme?.accentColor ?? .blue)
                            
                            Text("NEW")
                                .font(theme?.captionFont ?? .caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(theme?.accentColor ?? .blue)
                                )
                        }
                        
                        Text("Interactive Lessons")
                            .font(theme?.titleFont ?? .largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(theme?.primaryColor ?? .primary)
                        
                        Text("Khan Academy-style lessons with step-by-step practice problems")
                            .font(theme?.bodyFont ?? .body)
                            .foregroundColor(theme?.secondaryColor ?? .secondary)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "book.fill")
                                    .font(.caption)
                                Text("3 Lessons")
                                    .font(theme?.captionFont ?? .caption)
                            }
                            .foregroundColor(theme?.secondaryColor ?? .secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                Text("30-45 min each")
                                    .font(theme?.captionFont ?? .caption)
                            }
                            .foregroundColor(theme?.secondaryColor ?? .secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(theme?.accentColor ?? .blue)
                        
                        Spacer()
                    }
                }
            }
            .padding(theme?.standardSpacing ?? 20)
            .background(
                LinearGradient(
                    colors: [
                        (theme?.accentColor ?? .blue).opacity(0.1),
                        (theme?.surfaceColor ?? Color(.systemBackground))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(theme?.cardCornerRadius ?? 16)
            .overlay(
                RoundedRectangle(cornerRadius: theme?.cardCornerRadius ?? 16)
                    .stroke((theme?.accentColor ?? .blue).opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func loadingIndicator(for theme: ThemeProvider) -> some View {
        switch theme.targetAgeGroup {
        case .k2:
            if let kidsTheme = theme as? KidsTheme {
                kidsTheme.loadingSpinner()
            } else {
                ProgressView()
            }
        case .g35:
            // 3-5 uses ElementaryTheme
            if let elementaryTheme = theme as? ElementaryTheme {
                elementaryTheme.loadingDots()
            } else {
                ProgressView()
            }
        case .g68:
            if let middleTheme = theme as? MiddleTheme {
                middleTheme.loadingIndicator()
            } else {
                ProgressView()
            }
        case .g912:
            if let highSchoolTheme = theme as? HighSchoolTheme {
                highSchoolTheme.loadingSpinner()
            } else {
                ProgressView()
            }
        }
    }
}

#Preview {
    DashboardView()
}
