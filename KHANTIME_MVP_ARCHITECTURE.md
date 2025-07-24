# KhanTime MVP Architecture Document

## Project Overview
**KhanTime**: A Khan Academy-style learning platform powered by TimeBack's 1EdTech standards implementation, designed for K-12 students with Alpha School's 2-hour learning methodology.

## Core Architecture Principles

### 1. Modular Design
Every component must be swappable without affecting other layers:
- **UI Layer**: Swap themes/components without touching business logic
- **Content Providers**: Switch between TimeBack, GitHub repos, or other sources
- **Standards Implementation**: Upgrade OneRoster/QTI versions independently

### 2. Protocol-Oriented Architecture
Use Swift protocols to define contracts between modules:
```swift
protocol ContentProvider {
    func fetchCourses() async throws -> [Course]
    func fetchLesson(id: String) async throws -> Lesson
}

protocol ThemeProvider {
    var primaryColor: Color { get }
    var fontScale: FontScale { get }
    var animations: AnimationSet { get }
}

protocol ProgressTracker {
    func recordProgress(lessonId: String, score: Double) async
    func getProgress(courseId: String) async -> CourseProgress
}
```

## Module Structure

### 1. UI Modules (Swappable Themes)

#### Age-Appropriate Themes
```
Source/UI/
├── Themes/
│   ├── KidsTheme.swift      // K-5: Colorful, playful, large buttons
│   ├── MiddleTheme.swift    // 6-8: Modern but approachable
│   ├── HighSchoolTheme.swift // 9-12: Clean, professional
│   └── ThemeProtocol.swift
├── Components/
│   ├── CourseCard/
│   ├── LessonNavigator/
│   ├── VideoPlayer/
│   └── ExerciseView/
└── Layouts/
    ├── DashboardLayout.swift
    └── LessonLayout.swift
```

#### Theme Implementation
```swift
// ThemeProtocol.swift
protocol Theme {
    // Colors
    var primaryColor: Color { get }
    var successColor: Color { get }
    var backgroundColor: Color { get }

    // Typography
    var headingFont: Font { get }
    var bodyFont: Font { get }

    // Spacing & Layout
    var cardCornerRadius: CGFloat { get }
    var standardPadding: CGFloat { get }

    // Animations
    var transitionStyle: AnyTransition { get }
    var feedbackAnimation: Animation { get }
}
```

### 2. Content Provider System

#### Provider Architecture
```
Source/Providers/
├── ContentProvider.swift        // Protocol definition
├── TimeBackProvider/
│   ├── TimeBackContent.swift
│   ├── QTIParser.swift
│   └── OneRosterMapper.swift
├── GitHubProvider/
│   ├── GitHubContent.swift
│   ├── RepoManager.swift
│   └── ContentParser.swift
└── MockProvider/
    └── MockContent.swift       // For testing
```

#### Content Models
```swift
// Unified content model that all providers must map to
struct Lesson {
    let id: String
    let title: String
    let duration: TimeInterval // For 2-hour learning tracking
    let ageGroup: AgeGroup
    let components: [LessonComponent]
}

enum LessonComponent {
    case video(VideoContent)
    case article(ArticleContent)
    case exercise(ExerciseContent)
    case quiz(QuizContent)
}
```

### 3. Business Logic Layer

#### ViewModels Structure
```
Source/ViewModels/
├── DashboardViewModel.swift
├── LessonViewModel.swift
├── ProgressViewModel.swift
└── SettingsViewModel.swift
```

#### Progress Tracking (2-Hour Learning)
```swift
class AlphaProgressManager {
    private let targetDuration: TimeInterval = 2 * 60 * 60 // 2 hours

    func trackLearningSession(courseId: String) -> LearningSession
    func calculateEfficiency() -> Double
    func suggestNextLesson() -> Lesson?
}
```

### 4. Data Layer

#### Service Architecture
```
Source/Services/
├── ContentService.swift      // Orchestrates providers
├── ProgressService.swift     // Local + TimeBack sync
├── AnalyticsService.swift    // Learning analytics
└── CacheService.swift        // Offline support
```

## Implementation Phases

### Phase 1: Foundation (Week 1)
1. Set up modular architecture
2. Implement protocol definitions
3. Create basic TimeBack provider
4. Build simple theme system

### Phase 2: Content Pipeline (Week 2)
1. Connect to GitHub repos for content
2. Build content parsing system
3. Create QTI exercise renderer
4. Implement video player

### Phase 3: MVP Features (Week 3)
1. Build "Basic Algebra" course
2. Implement progress tracking
3. Add 2-hour learning timer
4. Create age-appropriate themes

### Phase 4: Polish (Week 4)
1. Animations and transitions
2. Offline support
3. Performance optimization
4. Testing and refinement

## Key Implementation Details

### 1. Dependency Injection
```swift
// AppContainer.swift
class AppContainer {
    lazy var contentProvider: ContentProvider = {
        // Easy to swap providers
        return TimeBackContentProvider(apiService: apiService)
        // return GitHubContentProvider(repos: ["math-content", "science-content"])
    }()

    lazy var theme: Theme = {
        // Dynamic theme based on user age
        return ThemeFactory.theme(for: userProfile.ageGroup)
    }()
}
```

### 2. Content Fetching Strategy
```swift
// Support multiple content sources
class HybridContentService: ContentProvider {
    private let providers: [ContentProvider]

    func fetchCourses() async throws -> [Course] {
        // Aggregate from all providers
        let allCourses = try await withThrowingTaskGroup(of: [Course].self) { group in
            for provider in providers {
                group.addTask { try await provider.fetchCourses() }
            }
            // Merge and deduplicate
        }
    }
}
```

### 3. Modular UI Components
```swift
// Reusable, themeable components
struct CourseCard: View {
    let course: Course
    @EnvironmentObject var theme: Theme

    var body: some View {
        // Component adapts to theme automatically
    }
}
```

## Testing Strategy

### 1. Provider Mocking
- Mock TimeBack responses
- Mock GitHub content
- Test provider switching

### 2. Theme Testing
- Preview all themes
- Test age-appropriate content filtering
- Verify accessibility

### 3. Progress Testing
- Test 2-hour tracking
- Verify sync with TimeBack
- Test offline scenarios

## Migration Path

### From Current State
1. Refactor existing services to use protocols
2. Extract UI components into modules
3. Create provider abstraction layer
4. Implement theme system

### Future Expandability
- New content sources: Just implement ContentProvider
- New standards: Swap TimeBackProvider implementation
- New themes: Add Theme implementation
- New features: Add to appropriate module

## Code Organization

```
KhanTime/
├── Source/
│   ├── App/
│   │   ├── KhanTimeApp.swift
│   │   └── AppContainer.swift
│   ├── UI/
│   │   ├── Themes/
│   │   ├── Components/
│   │   └── Screens/
│   ├── Business/
│   │   ├── ViewModels/
│   │   ├── Managers/
│   │   └── Models/
│   ├── Data/
│   │   ├── Services/
│   │   ├── Providers/
│   │   └── Cache/
│   └── Utilities/
├── Tests/
└── Resources/
```

## Next Conversation Checklist

When you return, you'll need to:

1. **Identify GitHub Repos**
   - Share repo URLs for content access
   - Confirm authentication method

2. **Content Mapping**
   - How is content structured in repos?
   - What format (Markdown, JSON, etc.)?

3. **Age Group Definition**
   - K-2, 3-5, 6-8, 9-12?
   - How to determine user age?

4. **Alpha School Integration**
   - Specific 2-hour learning rules?
   - Progress measurement criteria?

5. **Immediate Priorities**
   - Start with which subject?
   - Which age group first?

## Quick Start Commands

```bash
# Set up the modular structure
mkdir -p Source/{UI/{Themes,Components,Screens},Business/{ViewModels,Managers,Models},Data/{Services,Providers,Cache}}

# Create protocol files
touch Source/Data/Providers/ContentProvider.swift
touch Source/UI/Themes/ThemeProtocol.swift
touch Source/Business/Managers/ProgressTracker.swift
```

## Key Decisions Made

1. **SwiftUI + Combine**: For reactive UI and data flow
2. **Protocol-Oriented**: Every major component has a protocol
3. **Theme System**: Age-appropriate UI switching
4. **Provider Pattern**: For content source flexibility
5. **Local-First**: Cache everything, sync when possible

This architecture ensures you can swap any piece without breaking others, perfectly aligned with your modularity requirements.
