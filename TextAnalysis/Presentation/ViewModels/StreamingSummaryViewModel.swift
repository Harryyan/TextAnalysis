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
    
    private let documentAnalysisUseCase: DocumentAnalysisUseCaseProtocol
    private let documentSummaryUseCase: DocumentSummaryUseCaseProtocol
    private var contentHash: String = ""
    private let document: FileDocument
    
    // MARK: - Public Properties for View
    var fileName: String {
        document.fileName
    }
    
    var fileTypeDisplayName: String {
        document.fileType.displayName
    }
    
    var contentCharacterCount: Int {
        document.content.count
    }
    
    var fileType: FileType {
        document.fileType
    }
    
    // MARK: - Task Management
    // Comprehensive task tracking for cancellation
    private var generationTask: Task<Void, Never>?
    private var analysisTask: Task<Void, Never>?
    private var loadingTask: Task<Void, Error>?
    private var cachingTask: Task<Void, Never>?
    
    init(document: FileDocument, documentAnalysisUseCase: some DocumentAnalysisUseCaseProtocol, documentSummaryUseCase: some DocumentSummaryUseCaseProtocol) {
        self.document = document
        self.documentAnalysisUseCase = documentAnalysisUseCase
        self.documentSummaryUseCase = documentSummaryUseCase
        self.contentHash = AnalysisResult.generateContentHash(for: document.content)
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
    
    func loadCachedData() {
        loadingTask?.cancel()
        loadingTask = Task {
            do {
                let cachedResult = try await documentAnalysisUseCase.getCachedAnalysis(for: contentHash)
                
                // Check for cancellation before updating UI
                try Task.checkCancellation()
                
                if let cachedResult = cachedResult {
                    if let cachedSummary = cachedResult.summary {
                        currentSummary = cachedSummary
                    }
                    if let cachedAnalysis = cachedResult.quickAnalysis {
                        quickAnalysis = cachedAnalysis
                    }
                }
                loadingTask = nil
            } catch is CancellationError {
                loadingTask = nil
            } catch {
                if let fileError = error as? FileError {
                    errorMessage = fileError.userFriendlyMessage
                } else {
                    errorMessage = "Failed to load cached data: \(error.localizedDescription)"
                }
                loadingTask = nil
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
            let result = await documentSummaryUseCase.streamingSummarize(for: document)
            
            switch result {
            case .success(let stream):
                do {
                    for try await partial in stream {
                        try Task.checkCancellation()
                        
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
                    
                    if let summary = currentSummary {
                        // Start caching task (tracked separately)
                        startCachingSummary(summary)
                    }
                    isGenerating = false
                    generationProgress = 1.0
                    generationTask = nil
                } catch is CancellationError {
                    isGenerating = false
                    generationTask = nil
                } catch {
                    errorMessage = handleAIError(error)
                    isGenerating = false
                    generationTask = nil
                }
                
            case .failure(let aiError):
                errorMessage = aiError.userFriendlyMessage
                isGenerating = false
                generationTask = nil
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
            let result = await documentSummaryUseCase.quickAnalyze(for: document)
            
            switch result {
            case .success(let analysis):
                // Check for cancellation
                guard !Task.isCancelled else {
                    isAnalyzing = false
                    analysisTask = nil
                    return
                }
                
                quickAnalysis = analysis
                isAnalyzing = false
                analysisTask = nil
                
                // Start caching task (tracked separately)
                startCachingQuickAnalysis(analysis)
                
            case .failure(let aiError):
                guard !Task.isCancelled else {
                    isAnalyzing = false
                    analysisTask = nil
                    return
                }
                
                errorMessage = aiError.userFriendlyMessage
                isAnalyzing = false
                analysisTask = nil
            }
        }
    }
    
    func switchDocument(to newDocument: FileDocument) {
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
        cachingTask?.cancel()
        cachingTask = Task {
            defer {
                cachingTask = nil
            }
            
            await cacheSummary(summary)
        }
    }
    
    private func startCachingQuickAnalysis(_ analysis: QuickAnalysis) {
        // Cancel any existing caching task
        cachingTask?.cancel()
        
        cachingTask = Task {
            defer {
                cachingTask = nil
            }
            
            await cacheQuickAnalysis(analysis)
        }
    }
    
    private func cacheSummary(_ summary: DocumentSummary) async {
        // Check for cancellation before database operations
        guard !Task.isCancelled else { return }
        
        do {
            let existingResult = try await documentAnalysisUseCase.getCachedAnalysis(for: contentHash)
            
            if let existingResult = existingResult {
                guard !Task.isCancelled else { return }
                let updateResult = await documentAnalysisUseCase.updateExistingSummary(existingResult: existingResult, summary: summary)
                if case .failure(let error) = updateResult {
                    errorMessage = error.userFriendlyMessage
                }
            } else {
                guard !Task.isCancelled else { return }
                let saveResult = await documentAnalysisUseCase.saveDocumentSummary(
                    contentHash: contentHash,
                    fileName: document.fileName,
                    fileType: document.fileType,
                    summary: summary
                )
                if case .failure(let error) = saveResult {
                    errorMessage = error.userFriendlyMessage
                }
            }
        } catch {
            if let fileError = error as? FileError {
                errorMessage = fileError.userFriendlyMessage
            } else {
                errorMessage = "Failed to cache summary: \(error.localizedDescription)"
            }
        }
    }
    
    private func cacheQuickAnalysis(_ analysis: QuickAnalysis) async {
        // Check for cancellation before database operations
        guard !Task.isCancelled else { return }
        
        do {
            let existingResult = try await documentAnalysisUseCase.getCachedAnalysis(for: contentHash)
            
            if let existingResult = existingResult {
                guard !Task.isCancelled else { return }
                let updateResult = await documentAnalysisUseCase.updateExistingQuickAnalysis(existingResult: existingResult, analysis: analysis)
                if case .failure(let error) = updateResult {
                    errorMessage = error.userFriendlyMessage
                }
            } else {
                guard !Task.isCancelled else { return }
                let saveResult = await documentAnalysisUseCase.saveQuickAnalysis(
                    contentHash: contentHash,
                    fileName: document.fileName,
                    fileType: document.fileType,
                    analysis: analysis
                )
                if case .failure(let error) = saveResult {
                    errorMessage = error.userFriendlyMessage
                }
            }
        } catch {
            if let fileError = error as? FileError {
                errorMessage = fileError.userFriendlyMessage
            } else {
                errorMessage = "Failed to cache analysis: \(error.localizedDescription)"
            }
        }
    }
    
    private func handleAIError(_ error: Error) -> String {
        // Handle AIError from domain layer
        if let aiError = error as? AIError {
            return aiError.userFriendlyMessage
        }
        
        // Handle Apple Foundation Models specific errors (fallback for direct errors)
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
        
        // Handle our custom service errors (fallback)
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
