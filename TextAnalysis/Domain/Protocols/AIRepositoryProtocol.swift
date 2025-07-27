//
//  AIRepositoryProtocol.swift
//  TextAnalysis
//
//  Created by Claude Code on 26/07/2025.
//

import Foundation

protocol AIRepositoryProtocol {
    /// Generates a complete document summary for the given content
    func generateSummary(content: String, fileType: FileType) async -> Result<DocumentSummary, AIError>
    
    /// Streams a document summary generation, returning partial results
    func streamingSummarize(content: String, fileType: FileType) async -> Result<AsyncThrowingStream<DocumentSummary.PartiallyGenerated, Error>, AIError>
    
    /// Performs quick analysis of document content
    func quickAnalyze(content: String, fileType: FileType) async -> Result<QuickAnalysis, AIError>
    
    /// Prearms the AI model session for faster subsequent operations
    func prewarmModel() async -> Result<Void, AIError>
    
    /// Checks if the AI model is currently available
    func isModelAvailable() -> Bool
    
    /// Gets the reason why the model is unavailable, if applicable
    func getUnavailabilityReason() -> String?
}
