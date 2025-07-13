//
//  TextAnalysisApp.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import SwiftUI
import SwiftData

@main
struct TextAnalysisApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: Item.self, AnalysisResult.self, configurations: configuration)
        } catch {
            print("Failed to create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentViewWrapper()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ContentView(viewModel: DIContainer.shared.makeFileListViewModel(modelContext: modelContext))
    }
}
