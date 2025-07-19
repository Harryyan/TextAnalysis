//
//  StreamingSummaryViewModel.swift
//  TextAnalysis
//
//  Created by HarryYan on 19/07/2025.
//

import Foundation
import SwiftData
import FoundationModels

@MainActor
@Observable final class StreamingSummaryViewModel {
    var currentSummary: DocumentSummary?
    var partialSummary: DocumentSummary.PartiallyGenerated?
    var quickAnalysis: QuickAnalysis?
    var isGenerating = false
    var isAnalyzing = false
    var errorMessage: String?
    var generationProgress: Double = 0.0
    
    private var analysisRepository: AnalysisRepositoryProtocol?
    private var contentHash: String = ""
    private let foundationService: FoundationModelsService
    private let document: FileDocument
    
    // Comprehensive task tracking for cancellation
    private var generationTask: Task<Void, Never>?
    private var analysisTask: Task<Void, Never>?
    private var loadingTask: Task<Void, Never>?
    private var cachingTask: Task<Void, Never>?
    
    init(document: FileDocument, foundationService: FoundationModelsService) {
        self.document = document
        self.foundationService = foundationService
    }
    
    func cancelAllTasks() {
        generationTask?.cancel()
        analysisTask?.cancel()
        loadingTask?.cancel()
        cachingTask?.cancel()
        
        generationTask = nil
        analysisTask = nil
        loadingTask = nil
        cachingTask = nil
        
        // Reset UI state when cancelling
        isGenerating = false
        isAnalyzing = false
    }
    
    func setupRepository(modelContext: ModelContext) {
        analysisRepository = AnalysisRepository(modelContext: modelContext)
        contentHash = AnalysisResult.generateContentHash(for: document.content)
    }
    
    func loadCachedData() {
        guard let repository = analysisRepository else { return }
        
        // Cancel any existing loading task
        loadingTask?.cancel()
        
        loadingTask = Task {
            do {
                if let cachedResult = await repository.getCachedResult(for: contentHash) {
                    // Check for cancellation before updating UI
                    try Task.checkCancellation()
                    
                    await MainActor.run {
                        if let cachedSummary = cachedResult.summary {
                            currentSummary = cachedSummary
                        }
                        if let cachedAnalysis = cachedResult.quickAnalysis {
                            quickAnalysis = cachedAnalysis
                        }
                        loadingTask = nil
                    }
                }
            } catch is CancellationError {
                await MainActor.run {
                    loadingTask = nil
                }
            } catch {
                await MainActor.run {
                    loadingTask = nil
                    print("Failed to load cached data: \(error)")
                }
            }
        }
    }
    
    func startStreamingGeneration() {
        guard !isGenerating else { return }
        
        // Cancel any existing generation task
        generationTask?.cancel()
        
        isGenerating = true
        errorMessage = nil
        generationProgress = 0.0
        
        generationTask = Task {
            do {
                let stream = try await foundationService.streamingSummarize(document.content, fileType: document.fileType)
                
                for try await partial in stream {
                    // Check for cancellation
                    try Task.checkCancellation()
                    
                    await MainActor.run {
                        partialSummary = partial
                        updateProgress(partial)
                        
                        // If we have a complete summary, convert it
                        if let title = partial.title,
                           let overview = partial.overview,
                           let keyPoints = partial.keyPoints,
                           let conclusion = partial.conclusion,
                           let readingTime = partial.estimatedReadingTimeMinutes {
                            currentSummary = DocumentSummary(
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
                        // Start caching task (tracked separately)
                        startCachingSummary(summary)
                    }
                    isGenerating = false
                    generationProgress = 1.0
                    generationTask = nil
                }
            } catch is CancellationError {
                await MainActor.run {
                    isGenerating = false
                    generationTask = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = handleError(error)
                    isGenerating = false
                    generationTask = nil
                }
            }
        }
    }
    
    func performQuickAnalysis() {
        guard !isAnalyzing else { return }
        
        // Cancel any existing analysis task
        analysisTask?.cancel()
        
        isAnalyzing = true
        errorMessage = nil
        
        analysisTask = Task {
            do {
                let analysis = try await foundationService.quickAnalyze(document.content, fileType: document.fileType)
                
                // Check for cancellation
                try Task.checkCancellation()
                
                await MainActor.run {
                    quickAnalysis = analysis
                    isAnalyzing = false
                    analysisTask = nil
                }
                
                // Start caching task (tracked separately)
                startCachingQuickAnalysis(analysis)
            } catch is CancellationError {
                await MainActor.run {
                    isAnalyzing = false
                    analysisTask = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = handleError(error)
                    isAnalyzing = false
                    analysisTask = nil
                }
            }
        }
    }
    
    func switchDocument(to newDocument: FileDocument, foundationService: FoundationModelsService) {
        // Cancel all ongoing tasks before switching
        cancelAllTasks()
        
        // Reset state
        currentSummary = nil
        partialSummary = nil
        quickAnalysis = nil
        errorMessage = nil
        generationProgress = 0.0
        
        // This would require reinitializing the ViewModel with new document
        // The caller should create a new ViewModel instance instead
    }
    
    private func startCachingSummary(_ summary: DocumentSummary) {
        // Cancel any existing caching task
        cachingTask?.cancel()
        
        cachingTask = Task {
            await cacheSummary(summary)
            await MainActor.run {
                cachingTask = nil
            }
        }
    }
    
    private func startCachingQuickAnalysis(_ analysis: QuickAnalysis) {
        // Cancel any existing caching task
        cachingTask?.cancel()
        
        cachingTask = Task {
            await cacheQuickAnalysis(analysis)
            await MainActor.run {
                cachingTask = nil
            }
        }
    }
    
    private func cacheSummary(_ summary: DocumentSummary) async {
        guard let repository = analysisRepository else { return }
        
        do {
            // Check for cancellation before database operations
            try Task.checkCancellation()
            
            if let existingResult = await repository.getCachedResult(for: contentHash) {
                try Task.checkCancellation()
                try await repository.updateSummary(existingResult: existingResult, summary: summary)
            } else {
                let newResult = AnalysisResult(
                    contentHash: contentHash,
                    fileName: document.fileName,
                    fileType: document.fileType,
                    summary: summary
                )
                try Task.checkCancellation()
                try await repository.saveAnalysisResult(newResult)
            }
        } catch is CancellationError {
            // Silently handle cancellation
        } catch {
            print("Failed to cache summary: \(error)")
        }
    }
    
    private func cacheQuickAnalysis(_ analysis: QuickAnalysis) async {
        guard let repository = analysisRepository else { return }
        
        do {
            // Check for cancellation before database operations
            try Task.checkCancellation()
            
            if let existingResult = await repository.getCachedResult(for: contentHash) {
                try Task.checkCancellation()
                try await repository.updateQuickAnalysis(existingAnalysisResult: existingResult, analysis: analysis)
            } else {
                let newResult = AnalysisResult(
                    contentHash: contentHash,
                    fileName: document.fileName,
                    fileType: document.fileType,
                    quickAnalysis: analysis
                )
                try Task.checkCancellation()
                try await repository.saveAnalysisResult(newResult)
            }
        } catch is CancellationError {
            // Silently handle cancellation
        } catch {
            print("Failed to cache quick analysis: \(error)")
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
                return "Apple's AI safety system detected potentially sensitive content and cannot analyze this document. Please try with different content."
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
                return "Foundation Models error (code: \(generationError._code)): \(generationError.localizedDescription). Please check if Apple Intelligence is enabled and try again."
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
    
    private func updateProgress(_ partial: DocumentSummary.PartiallyGenerated) {
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
