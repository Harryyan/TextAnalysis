//
//  AIRepository.swift
//  TextAnalysis
//
//  Created by Claude Code on 26/07/2025.
//

import Foundation
import FoundationModels

final class AIRepository: AIRepositoryProtocol {
    private let foundationService: FoundationModelsServiceProtocol
    private let modelAvailability: ModelAvailabilityService
    
    init(foundationService: some FoundationModelsServiceProtocol, modelAvailability: ModelAvailabilityService) {
        self.foundationService = foundationService
        self.modelAvailability = modelAvailability
    }
    
    func generateSummary(content: String, fileType: FileType) async -> Result<DocumentSummary, AIError> {
        guard isModelAvailable() else {
            return .failure(.modelUnavailable(reason: getUnavailabilityReason() ?? "Unknown reason"))
        }
        
        do {
            // For now, we'll use streaming and get the final result
            let streamResult = await streamingSummarize(content: content, fileType: fileType)
            switch streamResult {
            case .success(let stream):
                var finalSummary: DocumentSummary?
                
                do {
                    for try await partial in stream {
                        // Convert partial to complete summary when all fields are available
                        if let title = partial.title,
                           let overview = partial.overview,
                           let keyPoints = partial.keyPoints,
                           let conclusion = partial.conclusion,
                           let readingTime = partial.estimatedReadingTimeMinutes {
                            finalSummary = DocumentSummary(
                                title: title,
                                overview: overview,
                                keyPoints: keyPoints,
                                conclusion: conclusion,
                                estimatedReadingTimeMinutes: readingTime
                            )
                        }
                    }
                    
                    if let summary = finalSummary {
                        return .success(summary)
                    } else {
                        return .failure(.summaryGenerationFailed(reason: "Incomplete summary generated"))
                    }
                } catch {
                    return .failure(mapFoundationError(error))
                }
                
            case .failure(let error):
                return .failure(error)
            }
        }
    }
    
    func streamingSummarize(content: String, fileType: FileType) async -> Result<AsyncThrowingStream<DocumentSummary.PartiallyGenerated, Error>, AIError> {
        guard isModelAvailable() else {
            return .failure(.modelUnavailable(reason: getUnavailabilityReason() ?? "Unknown reason"))
        }
        
        do {
            let stream = try await foundationService.streamingSummarize(content, fileType: fileType)
            return .success(stream)
        } catch {
            return .failure(mapFoundationError(error))
        }
    }
    
    func quickAnalyze(content: String, fileType: FileType) async -> Result<QuickAnalysis, AIError> {
        guard isModelAvailable() else {
            return .failure(.modelUnavailable(reason: getUnavailabilityReason() ?? "Unknown reason"))
        }
        
        do {
            let analysis = try await foundationService.quickAnalyze(content, fileType: fileType)
            return .success(analysis)
        } catch {
            return .failure(mapFoundationError(error))
        }
    }
    
    func prewarmModel() async -> Result<Void, AIError> {
        guard isModelAvailable() else {
            return .failure(.modelUnavailable(reason: getUnavailabilityReason() ?? "Unknown reason"))
        }
        
        do {
            try await foundationService.prewarmSession()
            return .success(())
        } catch {
            return .failure(mapFoundationError(error))
        }
    }
    
    func isModelAvailable() -> Bool {
        return modelAvailability.isAvailable
    }
    
    func getUnavailabilityReason() -> String? {
        return modelAvailability.getUnavailabilityReason()
    }
    
    // MARK: - Private Methods
    
    private func mapFoundationError(_ error: Error) -> AIError {
        // Handle Apple Foundation Models specific errors
        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .exceededContextWindowSize:
                return .contextWindowExceeded
            case .assetsUnavailable:
                return .modelUnavailable(reason: "AI model assets are unavailable. Please ensure Apple Intelligence is enabled and try again later.")
            case .guardrailViolation:
                return .guardrailViolation
            case .unsupportedGuide:
                return .summaryGenerationFailed(reason: "Unsupported analysis pattern. Please try again.")
            case .unsupportedLanguageOrLocale:
                return .summaryGenerationFailed(reason: "Unsupported language. Please try with English content.")
            case .decodingFailure:
                return .summaryGenerationFailed(reason: "Failed to process AI response. Please try again.")
            case .rateLimited:
                return .rateLimited
            case .concurrentRequests:
                return .concurrentRequests
            @unknown default:
                return .unknown(reason: "Foundation Models error (code: \(generationError._code)): \(generationError.localizedDescription). Please check if Apple Intelligence is enabled and try again.")
            }
        }
        
        // Handle our custom service errors
        if let foundationError = error as? FoundationModelsError {
            switch foundationError {
            case .contextWindowExceeded:
                return .contextWindowExceeded
            case .sessionTimeout:
                return .sessionTimeout
            case .contentTooLong:
                return .contentTooLong
            case .generationFailed(let message):
                return .summaryGenerationFailed(reason: message)
            case .sessionNotInitialized:
                return .sessionNotInitialized
            case .invalidContent:
                return .invalidContent
            }
        }
        
        return .unknown(reason: error.localizedDescription)
    }
}
