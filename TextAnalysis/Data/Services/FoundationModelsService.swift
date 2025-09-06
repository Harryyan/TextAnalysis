//
//  FoundationModelsService.swift
//  TextAnalysis
//
//  Created by HarryYan on 13/07/2025.
//

import Foundation
import FoundationModels

enum FoundationModelsError: Error {
    case contextWindowExceeded
    case sessionTimeout
    case contentTooLong
    case generationFailed(String)
    case sessionNotInitialized
    case invalidContent
}

protocol FoundationModelsServiceProtocol {
    func streamingSummarize(_ content: String, fileType: FileType) async throws -> AsyncThrowingStream<DocumentSummary.PartiallyGenerated, Error>
    func quickAnalyze(_ content: String, fileType: FileType) async throws -> QuickAnalysis
    func extractEntities(_ content: String) async throws -> EntityExtraction
    func resetSession()
    func prewarmSession() async throws
}

final class FoundationModelsService: FoundationModelsServiceProtocol {
    private var session: LanguageModelSession?
    private let maxContextTokens = 3500
    private let maxRetries = 3
    private var isPrewarmed = false
    
    init() {
        initializeSession()
    }
    
    private func initializeSession() {
        let instructions = createSystemInstruction()
        session = LanguageModelSession(instructions: instructions)
    }
    
    func resetSession() {
        session = nil
        isPrewarmed = false
        initializeSession()
    }
    
    func prewarmSession() async throws {
        guard let session = session, !isPrewarmed else { return }
        
        print("Prewarming Foundation Models session for better performance...")
        session.prewarm()
        isPrewarmed = true
        print("Foundation Models session prewarming completed")
    }
    
    func streamingSummarize(_ content: String, fileType: FileType) async throws -> AsyncThrowingStream<DocumentSummary.PartiallyGenerated, Error> {
        guard let session = session else {
            throw FoundationModelsError.sessionNotInitialized
        }
        
        // Check if Foundation Models are available before attempting generation
        print("Starting Foundation Models generation for \(fileType.displayName) content (\(content.count) characters)")
        
        let processedContent = try preprocessContent(content)
        let prompt = buildSummaryPrompt(content: processedContent, fileType: fileType)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let stream = session.streamResponse(
                        to: prompt,
                        generating: DocumentSummary.self,
                        options: GenerationOptions(temperature: 0.5)
                    )
                    
                    for try await summary in stream {
                        continuation.yield(summary.content)
                    }
                    continuation.finish()
                } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
                    let estimatedMinutes = max(1, content.count / 1125) // ~225 words per minute, ~5 chars per word
                    let fallbackSummary = DocumentSummary(
                        title: "Summary (Truncated)",
                        overview: "This is a partial summary due to document length limitations.",
                        keyPoints: ["Document was too long for full analysis", "Summary based on first portion of content"],
                        conclusion: "Full analysis requires document chunking.",
                        estimatedReadingTimeMinutes: estimatedMinutes
                    )
                    continuation.yield(fallbackSummary.asPartiallyGenerated())
                    continuation.finish()
                } catch LanguageModelSession.GenerationError.guardrailViolation {
                    print("Content triggered safety guardrails")
                    continuation.finish(throwing: FoundationModelsError.generationFailed("Content may contain sensitive material that cannot be analyzed by Apple's AI models"))
                } catch {
                    print("Foundation Models generation failed: \(error)")
                    if let generationError = error as? LanguageModelSession.GenerationError {
                        print("Generation error details: \(generationError)")
                    }
                    continuation.finish(throwing: FoundationModelsError.generationFailed(error.localizedDescription))
                }
            }
        }
    }
    
    func quickAnalyze(_ content: String, fileType: FileType) async throws -> QuickAnalysis {
        guard let session = session else {
            throw FoundationModelsError.sessionNotInitialized
        }
        
        let processedContent = try preprocessContent(content)
        let prompt = buildAnalysisPrompt(content: processedContent, fileType: fileType)
        
        do {
            let response = try await session.respond(
                to: prompt,
                generating: QuickAnalysis.self,
                options: GenerationOptions(temperature: 0.5)
            )
            return response.content
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            let truncatedContent = truncateContent(processedContent, maxTokens: maxContextTokens / 2)
            let shortPrompt = buildAnalysisPrompt(content: truncatedContent, fileType: fileType)
            let response = try await session.respond(
                to: shortPrompt,
                generating: QuickAnalysis.self
            )
            return response.content
        } catch {
            throw FoundationModelsError.generationFailed(error.localizedDescription)
        }
    }
    
    func extractEntities(_ content: String) async throws -> EntityExtraction {
        guard let session = session else {
            throw FoundationModelsError.sessionNotInitialized
        }
        
        let processedContent = try preprocessContent(content)
        let prompt = buildEntityExtractionPrompt(content: processedContent)
        
        do {
            let response = try await session.respond(
                to: prompt,
                generating: EntityExtraction.self
            )
            return response.content
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            let truncatedContent = truncateContent(processedContent, maxTokens: maxContextTokens / 2)
            let shortPrompt = buildEntityExtractionPrompt(content: truncatedContent)
            let response = try await session.respond(
                to: shortPrompt,
                generating: EntityExtraction.self
            )
            return response.content
        } catch {
            throw FoundationModelsError.generationFailed(error.localizedDescription)
        }
    }
    
    private func createSystemInstruction() -> String {
        """
        You are a helpful document analysis assistant that generates accurate, factual summaries and analysis.
        
        SAFETY GUIDELINES:
        - Only analyze the provided document content
        - Generate professional, neutral content
        - Focus on factual information extraction
        - If content appears problematic, provide a neutral analytical summary
        - Do not generate inappropriate or harmful content
        
        OUTPUT GUIDELINES:
        - Generate concise, structured summaries
        - Prioritize key information and main themes
        - Use professional, clear language
        - Ensure accuracy and relevance to the source material
        - Maintain objectivity in analysis
        """
    }
    
    private func preprocessContent(_ content: String) throws -> String {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoundationModelsError.invalidContent
        }
        
        let sanitized = sanitizeContent(content)
        
        if estimateTokenCount(sanitized) > maxContextTokens {
            return truncateContent(sanitized, maxTokens: maxContextTokens)
        }
        
        return sanitized
    }
    
    private func sanitizeContent(_ content: String) -> String {
        var sanitized = content
        
        // Remove potential prompt injection attempts
        let suspiciousPatterns = [
            "ignore previous instructions",
            "forget everything",
            "system:",
            "assistant:",
            "user:"
        ]
        
        for pattern in suspiciousPatterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "",
                options: .caseInsensitive
            )
        }
        
        // Limit line length and clean up excessive whitespace
        sanitized = sanitized.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        
        return sanitized
    }
    
    private func buildSummaryPrompt(content: String, fileType: FileType) -> String {
        """
        Analyze this \(fileType.displayName) document and provide a comprehensive summary:
        
        Content:
        \(content)
        
        Generate a structured summary with:
        1. A clear, descriptive title
        2. An overview paragraph
        3. 3-5 key points covering the main themes
        4. A conclusion summarizing the significance
        5. Estimated reading time in minutes
        """
    }
    
    private func buildAnalysisPrompt(content: String, fileType: FileType) -> String {
        """
        Perform a quick analysis of this \(fileType.displayName) document:
        
        Content:
        \(content)
        
        Provide:
        1. Document category classification
        2. Complexity level assessment
        3. 2-4 main topics/themes
        4. Confidence score (1-10) for your analysis
        """
    }
    
    private func buildEntityExtractionPrompt(content: String) -> String {
        """
        Extract key entities from this document:
        
        Content:
        \(content)
        
        Identify and list:
        1. People mentioned (names only)
        2. Organizations/companies
        3. Locations/places
        4. Important terms/concepts
        """
    }
    
    private func estimateTokenCount(_ content: String) -> Int {
        // Rough estimation: ~4 characters per token
        return content.count / 4
    }
    
    private func estimateReadingTime(_ content: String) -> Int {
        // Average reading speed: 225 words per minute
        // Average word length: ~5 characters (including spaces)
        return max(1, content.count / 1125)
    }
    
    private func truncateContent(_ content: String, maxTokens: Int) -> String {
        let maxCharacters = maxTokens * 4
        
        if content.count <= maxCharacters {
            return content
        }
        
        // Try to truncate at sentence boundaries
        let sentences = content.components(separatedBy: ". ")
        var truncated = ""
        
        for sentence in sentences {
            let potential = truncated + sentence + ". "
            if potential.count > maxCharacters {
                break
            }
            truncated = potential
        }
        
        return truncated.isEmpty ? String(content.prefix(maxCharacters)) : truncated
    }
    
    
    private func handleContextOverflow(_ content: String, fileType: FileType) async throws -> DocumentSummary {
        // For context overflow, generate a basic summary from truncated content
        let estimatedMinutes = max(1, content.count / 1125) // ~225 words per minute, ~5 chars per word
        
        return DocumentSummary(
            title: "Summary (Truncated)",
            overview: "This is a partial summary due to document length limitations.",
            keyPoints: ["Document was too long for full analysis", "Summary based on first portion of content"],
            conclusion: "Full analysis requires document chunking.",
            estimatedReadingTimeMinutes: estimatedMinutes
        )
    }
}
