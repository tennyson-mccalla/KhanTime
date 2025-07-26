# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

This is an **iPad-focused SwiftUI project** built with Xcode. 

**Build and Run:**
- Open `KhanTime.xcodeproj` in Xcode
- Use Xcode's build system (Cmd+B to build, Cmd+R to run)
- **Primary Target: iPad** (iOS 16.0+)
- Design for larger screens and touch-based learning interactions
- No external package managers (pure SwiftUI/Foundation)

**Critical Setup:**
```bash
# REQUIRED: Set up API credentials before building
cp Source/Utilities/Credentials.swift.template Source/Utilities/Credentials.swift
# Edit Credentials.swift with actual Alpha 1EdTech API credentials
```

**No testing framework is currently configured** - check with user before adding tests.

## Architecture Overview

**KhanTime** is a Khan Academy-style learning platform with modular, protocol-oriented architecture designed for swappable components.

### Core Architecture Principles

1. **Protocol-Oriented Design**: Every major component has a protocol contract
   - `ContentProvider`: Swap content sources (TimeBack, GitHub, etc.)
   - `ThemeProvider`: Age-appropriate UI themes (K-5, 6-8, 9-12)
   - `ProgressTracker`: 2-hour learning methodology tracking

2. **Modular Structure**: Components can be swapped without affecting other layers
   - UI themes are completely swappable for different age groups
   - Content providers can switch between TimeBack API, GitHub repos, mock data
   - Business logic is decoupled from data sources and UI

### Key File Structure

```
Source/
├── KhanTimeApp.swift              # Main app entry point
├── Models/                        # Data models (Course, User, Syllabus, etc.)
├── Networking/                    # API services (TimeBack/Alpha 1EdTech integration)
├── Protocols/                     # Protocol definitions for modularity
├── Providers/                     # Content provider implementations
├── UI/                           # Theme system and components
├── Utilities/                     # Credentials and utilities
├── ViewModels/                    # MVVM architecture
└── Views/                        # SwiftUI views
```

### Active APIs & Services

**Primary Integration**: Alpha 1EdTech / TimeBack Platform
- Base URL: `https://api.staging.alpha-1edtech.com` (staging)
- OAuth2 authentication with token refresh
- OneRoster API for courses/syllabi
- QTI API for assessments (QTI URLs may need validation)
- PowerPath API for content creation

**API Services**:
- `APIService`: Base OAuth2 authentication
- `CourseService`: Fetch courses and syllabi from OneRoster
- `ContentCreationService`: Create course components and QTI resources
- `GraphQLService`: Created but API appears to be REST-only

### Theme System

Complete age-appropriate theme system:
- `KidsTheme`: K-5 (playful colors, large buttons)
- `MiddleTheme`: 6-8 (modern balanced design)  
- `HighSchoolTheme`: 9-12 (professional, clean)
- `ThemeFactory`: Automatic theme selection
- `ThemePreference`: User preference persistence

Apply themes using: `.themed(with: theme)` or `.themedWithPreference(themePreference)`

### Current Implementation Status

✅ **Completed**:
- Protocol-oriented architecture foundation
- TimeBack API integration with course fetching
- Complete theme system for all age groups
- Basic UI (Dashboard, Syllabus, QTI viewer)
- OAuth2 authentication flow

❌ **Not Implemented**:
- Dependency injection (AppContainer)
- Progress tracking (2-hour learning methodology)
- Offline/caching support
- Additional content providers (GitHub, Mock)
- Video player, exercise views, markdown articles

### Known Issues

1. **QTI 404 Errors**: Hardcoded QTI URLs return 404 - need to fetch valid test URLs from QTI API
2. **API Data Quality**: Some courses have invalid grade formats requiring graceful error handling
3. **Content Duplication**: Creating test content multiple times adds duplicates

### Security Notes

- **Never commit** `Source/Utilities/Credentials.swift` (contains API secrets)
- Template file provided at `Credentials.swift.template`
- API credentials must be obtained from Alpha/TimeBack team
- See `SECRETS_SETUP.md` for detailed security setup

### Development Patterns

- **iPad-First Design**: Optimize layouts for larger screens and touch interactions
- Use existing protocols when adding new features
- Follow MVVM pattern with ViewModels for business logic
- Apply themes to all new UI components using theme environment
- Handle API errors gracefully (many endpoints have data quality issues)
- Use async/await for all network operations
- Consider split-screen and multitasking scenarios for iPad

### Key Reference Files

- `KHANTIME_MVP_ARCHITECTURE.md`: Complete architectural specification
- `KHANTIME_PROGRESS_HANDOFF.md`: Current implementation status and next steps
- `SECRETS_SETUP.md`: API credential setup and security practices