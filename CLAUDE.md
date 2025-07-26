# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a PDF and Text file reader project(SwiftUI) and aiming to use Apple's new foundation model apis to summarize the text content from PDF and Text files.

## Architecture

- **SwiftUI + SwiftData**: Modern Apple development stack
- **Model-View Pattern**: ContentView handles UI, Item model represents data
- **SwiftData Model Container**: Configured in TextAnalysisApp.swift with persistent storage
- **Navigation**: Uses NavigationSplitView for master-detail layout

## Key Components

- `TextAnalysisApp.swift`: App entry point with SwiftData model container setup
- `ContentView.swift`: Main UI with list/detail navigation and CRUD operations
- `Item.swift`: SwiftData model representing timestamped items
- Tests are split into unit tests (Testing framework) and UI tests (XCTest)

## Development Commands

**Build and Run:**
```bash
# Open in Xcode
open TextAnalysis.xcodeproj

# Build from command line
xcodebuild -project TextAnalysis.xcodeproj -scheme TextAnalysis build

# Run tests
xcodebuild -project TextAnalysis.xcodeproj -scheme TextAnalysis test
```

**Testing:**
- Unit tests use the new Swift Testing framework (`@Test` annotations)
- UI tests use XCTest framework (`XCTestCase` subclass)
- Run tests via Xcode Test Navigator (⌘+6) or xcodebuild command

## Code Patterns

- SwiftData models use `@Model` macro and require `import SwiftData`
- Views access model context via `@Environment(\.modelContext)`
- Data queries use `@Query` property wrapper
- UI updates wrapped in `withAnimation` for smooth transitions
- Preview providers include `.modelContainer(for: Item.self, inMemory: true)` for SwiftData models

## Swift Best Practices

- **Use `final` keyword for classes without inheritance**: All classes that don't need subclassing should be marked as `final` (e.g., `final class FileRepository: FileRepositoryProtocol`)
- **Prefer structs over classes**: Use structs for value types and data models when reference semantics aren't needed
- **Protocol-oriented design**: Define protocols for dependencies and use dependency injection for testability
- **Task cleanup with `defer`**: Always use `defer` to cleanup task references in async operations to ensure proper cleanup regardless of completion, error, or cancellation:
  ```swift
  // Good - guaranteed cleanup
  task = Task {
      defer { task = nil }
      await doWork()
  }
  
  // Bad - cleanup can be skipped on error/cancellation
  task = Task {
      await doWork()
      task = nil
  }
  ```
- **SwiftUI async exceptions**: 
  - The `.task {}` modifier is acceptable in SwiftUI views as it's a proper SwiftUI pattern for handling async work tied to view lifecycle
  - Brief `Task { }` blocks are acceptable in SwiftUI views for UI-related async work (animations, scroll positioning, etc.) but should not contain business logic

## Current State

The app is a basic template with minimal functionality - it can add/delete items with timestamps. The name "TextAnalysis" suggests this is intended to be expanded into a text analysis application.