//
//  DocumentSummaryUseCase.swift
//  TextAnalysis
//
//  Created by Claude Code on 26/07/2025.
//

import Foundation

protocol DocumentSummaryUseCaseProtocol {
    /// Generates a complete document summary for the given content
    func generateSummary(for document: FileDocument) async -> Result<DocumentSummary, AIError>
    
    /// Streams a document summary generation, returning partial results
    func streamingSummarize(for document: FileDocument) async -> Result<AsyncThrowingStream<DocumentSummary.PartiallyGenerated, Error>, AIError>
    
    /// Performs quick analysis of document content
    func quickAnalyze(for document: FileDocument) async -> Result<QuickAnalysis, AIError>
    
    /// Prearms the AI model session for faster subsequent operations
    func prewarmModel() async -> Result<Void, AIError>
    
    /// Checks if the AI model is currently available
    func checkModelAvailability() -> Result<Bool, AIError>
    
    /// Gets the reason why the model is unavailable, if applicable
    func getUnavailabilityReason() -> String?
}

final class DocumentSummaryUseCase: DocumentSummaryUseCaseProtocol {
    private let aiRepository: AIRepositoryProtocol
    
    init(aiRepository: AIRepositoryProtocol) {
        self.aiRepository = aiRepository
    }
    
    func generateSummary(for document: FileDocument) async -> Result<DocumentSummary, AIError> {
        // Validate document content
        guard !document.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidContent)
        }
        
        return await aiRepository.generateSummary(content: document.content, fileType: document.fileType)
    }
    
    func streamingSummarize(for document: FileDocument) async -> Result<AsyncThrowingStream<DocumentSummary.PartiallyGenerated, Error>, AIError> {
        // Validate document content
        guard !document.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidContent)
        }
        
        return await aiRepository.streamingSummarize(content: document.content, fileType: document.fileType)
    }
    
    func quickAnalyze(for document: FileDocument) async -> Result<QuickAnalysis, AIError> {
        // Validate document content
        guard !document.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidContent)
        }
        
        return await aiRepository.quickAnalyze(content: document.content, fileType: document.fileType)
    }
    
    func prewarmModel() async -> Result<Void, AIError> {
        return await aiRepository.prewarmModel()
    }
    
    func checkModelAvailability() -> Result<Bool, AIError> {
        let isAvailable = aiRepository.isModelAvailable()
        return .success(isAvailable)
    }
    
    func getUnavailabilityReason() -> String? {
        return aiRepository.getUnavailabilityReason()
    }
}