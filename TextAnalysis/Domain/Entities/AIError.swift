//
//  AIError.swift
//  TextAnalysis
//
//  Created by Claude Code on 26/07/2025.
//

import Foundation

enum AIError: Error, Equatable {
    case modelUnavailable(reason: String)
    case summaryGenerationFailed(reason: String)
    case prewarmingFailed(reason: String)
    case contextWindowExceeded
    case sessionTimeout
    case contentTooLong
    case invalidContent
    case sessionNotInitialized
    case rateLimited
    case concurrentRequests
    case guardrailViolation
    case unknown(reason: String)
    
    var userFriendlyMessage: String {
        switch self {
        case .modelUnavailable(let reason):
            return "AI model is unavailable: \(reason)"
        case .summaryGenerationFailed(let reason):
            return "Failed to generate summary: \(reason)"
        case .prewarmingFailed(let reason):
            return "Failed to prepare AI model: \(reason)"
        case .contextWindowExceeded:
            return "Document is too long for analysis. The system will automatically handle this."
        case .sessionTimeout:
            return "Generation timed out. Please try again."
        case .contentTooLong:
            return "Content is too long for processing."
        case .invalidContent:
            return "Invalid document content."
        case .sessionNotInitialized:
            return "AI service not available. Please restart the app."
        case .rateLimited:
            return "Too many requests. Please wait and try again."
        case .concurrentRequests:
            return "Another analysis is in progress. Please wait and try again."
        case .guardrailViolation:
            return "Apple's AI safety system detected potentially sensitive content and cannot analyze this document. Please try with different content."
        case .unknown(let reason):
            return "An unexpected error occurred: \(reason)"
        }
    }
    
    var technicalReason: String {
        switch self {
        case .modelUnavailable(let reason):
            return "Model unavailable: \(reason)"
        case .summaryGenerationFailed(let reason):
            return "Summary generation failed: \(reason)"
        case .prewarmingFailed(let reason):
            return "Prewarming failed: \(reason)"
        case .contextWindowExceeded:
            return "Context window size exceeded"
        case .sessionTimeout:
            return "Session timeout"
        case .contentTooLong:
            return "Content too long"
        case .invalidContent:
            return "Invalid content"
        case .sessionNotInitialized:
            return "Session not initialized"
        case .rateLimited:
            return "Rate limited"
        case .concurrentRequests:
            return "Concurrent requests"
        case .guardrailViolation:
            return "Guardrail violation"
        case .unknown(let reason):
            return reason
        }
    }
}