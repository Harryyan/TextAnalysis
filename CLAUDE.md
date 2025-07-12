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

## Current State

The app is a basic template with minimal functionality - it can add/delete items with timestamps. The name "TextAnalysis" suggests this is intended to be expanded into a text analysis application.