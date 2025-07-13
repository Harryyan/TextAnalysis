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
            
            if let summary = currentSummary {
                summaryDisplaySection(summary)
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
                for try await summary in foundationService.streamingSummarize(document.content, fileType: document.fileType) {
                    await MainActor.run {
                        currentSummary = summary
                        generationProgress = 1.0 // Complete when we receive the summary
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
                try await repository.updateSummary(for: contentHash, summary: summary)
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
        if let foundationError = error as? FoundationModelsError {
            switch foundationError {
            case .contextWindowExceeded:
                return "Document is too long. Try with a shorter document or the system will automatically chunk it."
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
}

