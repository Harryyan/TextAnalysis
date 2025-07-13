//
//  StreamingSummaryView.swift
//  TextAnalysis
//
//  Created by HarryYan on 13/07/2025.
//

import SwiftUI
import SwiftData
import FoundationModels

struct StreamingSummaryView: View {
    let document: FileDocument
    @Environment(\.modelContext) private var modelContext
    @State private var currentSummary: StreamingDocumentSummary?
    @State private var partialSummary: StreamingDocumentSummary.PartiallyGenerated?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var generationProgress: Double = 0.0
    @State private var foundationService = FoundationModelsService()
    @State private var analysisRepository: AnalysisRepository?
    @State private var contentHash: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                
                if isGenerating {
                    streamingProgressSection
                } else if let summary = currentSummary {
                    summaryDisplaySection(summary)
                } else {
                    generateButtonSection
                }
                
                if let error = errorMessage {
                    errorSection(error)
                }
            }
            .padding()
        }
        .navigationTitle("AI Summary")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupRepository()
            loadCachedSummary()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Document Analysis")
                .font(.title2)
                .bold()
            
            Text(document.fileName)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Label("Type: \(document.fileType.displayName)", systemImage: "doc.text")
                Spacer()
                Label("Size: \(document.content.count) chars", systemImage: "info.circle")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var generateButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: startStreamingGeneration) {
                HStack {
                    Image(systemName: currentSummary != nil ? "arrow.clockwise" : "brain")
                    Text(currentSummary != nil ? "Regenerate AI Summary" : "Generate AI Summary")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isGenerating)
            
            if currentSummary != nil {
                Text("Tap to regenerate with fresh analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("This will analyze your document using Apple's Foundation Models")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var streamingProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Generating summary...")
                    .font(.headline)
                Spacer()
            }
            
            ProgressView(value: generationProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
            
            if let partial = partialSummary {
                StreamingContentView(partial: partial)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func summaryDisplaySection(_ summary: StreamingDocumentSummary) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(summary.title)
                    .font(.title2)
                    .bold()
            }
            
            Divider()
            
            // Overview
            VStack(alignment: .leading, spacing: 8) {
                Text("Overview")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(summary.overview)
                    .font(.body)
            }
            
            Divider()
            
            // Key Points
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Points")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ForEach(Array(summary.keyPoints.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.body)
                            .foregroundColor(.blue)
                            .bold()
                        Text(point)
                            .font(.body)
                        Spacer()
                    }
                }
            }
            
            Divider()
            
            // Conclusion
            VStack(alignment: .leading, spacing: 8) {
                Text("Conclusion")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(summary.conclusion)
                    .font(.body)
            }
            
            // Reading Time
            HStack {
                Image(systemName: "clock")
                Text("Estimated reading time: \(summary.estimatedReadingTimeMinutes) minutes")
                Spacer()
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top)
            
            // Regenerate button
            Button(action: startStreamingGeneration) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Regenerate Summary")
                }
                .font(.callout)
                .foregroundColor(.blue)
            }
            .padding(.top)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func errorSection(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text(error)
                .font(.callout)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func startStreamingGeneration() {
        guard !isGenerating else { return }
        
        isGenerating = true
        errorMessage = nil
        generationProgress = 0.0
        
        Task {
            do {
                let stream = try await foundationService.streamingSummarize(document.content, fileType: document.fileType)
                
                for try await partial in stream {
                    await MainActor.run {
                        partialSummary = partial
                        updateProgress(partial)
                        
                        // If we have a complete summary, convert it
                        if let title = partial.title,
                           let overview = partial.overview,
                           let keyPoints = partial.keyPoints,
                           let conclusion = partial.conclusion,
                           let readingTime = partial.estimatedReadingTimeMinutes {
                            currentSummary = StreamingDocumentSummary(
                                title: title,
                                overview: overview,
                                keyPoints: keyPoints,
                                conclusion: conclusion,
                                estimatedReadingTimeMinutes: readingTime
                            )
                        }
                    }
                }
                
                await MainActor.run {
                    if let summary = currentSummary {
                        // Cache the completed summary
                        Task {
                            await cacheSummary(summary)
                        }
                    }
                    isGenerating = false
                    generationProgress = 1.0
                }
            } catch {
                await MainActor.run {
                    errorMessage = handleError(error)
                    isGenerating = false
                }
            }
        }
    }
    
    private func setupRepository() {
        analysisRepository = AnalysisRepository(modelContext: modelContext)
        contentHash = AnalysisResult.generateContentHash(for: document.content)
    }
    
    private func loadCachedSummary() {
        guard let repository = analysisRepository else { return }
        
        Task {
            if let cachedResult = await repository.getCachedResult(for: contentHash),
               let cachedSummary = cachedResult.summary {
                await MainActor.run {
                    currentSummary = cachedSummary
                }
            }
        }
    }
    
    private func cacheSummary(_ summary: StreamingDocumentSummary) async {
        guard let repository = analysisRepository else { return }
        
        do {
            if let existingResult = await repository.getCachedResult(for: contentHash) {
                try await repository.updateSummary(existingResult: existingResult, summary: summary)
            } else {
                let newResult = AnalysisResult(
                    contentHash: contentHash,
                    fileName: document.fileName,
                    fileType: document.fileType,
                    summary: summary
                )
                try await repository.saveAnalysisResult(newResult)
            }
        } catch {
            print("Failed to cache summary: \(error)")
        }
    }
    
    
    private func handleError(_ error: Error) -> String {
        // Handle Apple Foundation Models specific errors
        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .exceededContextWindowSize:
                return "Document is too long for analysis. The system will automatically handle this."
            case .assetsUnavailable:
                return "AI model is unavailable. Please ensure Apple Intelligence is enabled and try again later."
            case .guardrailViolation:
                return "Content violates safety guidelines. Please try with different content."
            case .unsupportedGuide:
                return "Unsupported analysis pattern. Please try again."
            case .unsupportedLanguageOrLocale:
                return "Unsupported language. Please try with English content."
            case .decodingFailure:
                return "Failed to process AI response. Please try again."
            case .rateLimited:
                return "Too many requests. Please wait and try again."
            case .concurrentRequests:
                return "Another analysis is in progress. Please wait and try again."
            @unknown default:
                return "Generic error occurred. Please try again."
            }
        }
        
        // Handle our custom service errors
        if let foundationError = error as? FoundationModelsError {
            switch foundationError {
            case .contextWindowExceeded:
                return "Document is too long for analysis."
            case .sessionTimeout:
                return "Generation timed out. Please try again."
            case .contentTooLong:
                return "Content is too long for processing."
            case .generationFailed(let message):
                return "Generation failed: \(message)"
            case .sessionNotInitialized:
                return "AI service not available. Please restart the app."
            case .invalidContent:
                return "Invalid document content."
            }
        }
        
        return "An unexpected error occurred: \(error.localizedDescription)"
    }
    
    private func updateProgress(_ partial: StreamingDocumentSummary.PartiallyGenerated) {
        var progress = 0.0
        
        if partial.title != nil { progress += 0.2 }
        if partial.overview != nil { progress += 0.3 }
        if let keyPoints = partial.keyPoints, !keyPoints.isEmpty {
            progress += 0.3 * (Double(keyPoints.count) / 5.0)
        }
        if partial.conclusion != nil { progress += 0.2 }
        
        generationProgress = min(progress, 1.0)
    }
}

struct StreamingContentView: View {
    let partial: StreamingDocumentSummary.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = partial.title {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(title)
                        .font(.headline)
                        .bold()
                }
            }
            
            if let overview = partial.overview {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(overview)
                        .font(.body)
                }
            }
            
            if let keyPoints = partial.keyPoints, !keyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Points (\(keyPoints.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(Array(keyPoints.enumerated()), id: \.offset) { index, point in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .foregroundColor(.blue)
                                .bold()
                            Text(point)
                                .font(.callout)
                        }
                    }
                }
            }
            
            if let conclusion = partial.conclusion {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Conclusion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(conclusion)
                        .font(.body)
                }
            }
            
            if let readingTime = partial.estimatedReadingTimeMinutes {
                HStack {
                    Image(systemName: "clock")
                    Text("Estimated reading time: \(readingTime) minutes")
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

