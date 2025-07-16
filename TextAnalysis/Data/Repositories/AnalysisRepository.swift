//
//  AnalysisRepository.swift
//  TextAnalysis
//
//  Created by HarryYan on 13/07/2025.
//

import Foundation
import SwiftData

protocol AnalysisRepositoryProtocol {
    func getCachedResult(for contentHash: String) async -> AnalysisResult?
    func saveAnalysisResult(_ result: AnalysisResult) async throws
    func updateQuickAnalysis(for contentHash: String, analysis: QuickAnalysis) async throws
    func updateEntities(for contentHash: String, entities: EntityExtraction) async throws
    func clearExpiredResults(maxAge: TimeInterval) async throws
    func deleteResult(for contentHash: String) async throws
}

struct AnalysisRepository: AnalysisRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getCachedResult(for contentHash: String) async -> AnalysisResult? {
        let predicate = #Predicate<AnalysisResult> { result in
            result.contentHash == contentHash
        }
        
        let descriptor = FetchDescriptor<AnalysisResult>(predicate: predicate)
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("Failed to fetch cached result: \(error)")
            return nil
        }
    }
    
    func saveAnalysisResult(_ result: AnalysisResult) async throws {
        modelContext.insert(result)
        try modelContext.save()
    }
    
    func updateSummary(existingResult: AnalysisResult, summary: DocumentSummary) async throws {
        existingResult.summary = summary
        try modelContext.save()
    }
    
    func updateQuickAnalysis(for contentHash: String, analysis: QuickAnalysis) async throws {
        guard let result = await getCachedResult(for: contentHash) else {
            throw AnalysisRepositoryError.resultNotFound
        }
        
        result.quickAnalysis = analysis
        try modelContext.save()
    }
    
    func updateEntities(for contentHash: String, entities: EntityExtraction) async throws {
        guard let result = await getCachedResult(for: contentHash) else {
            throw AnalysisRepositoryError.resultNotFound
        }
        
        result.entities = entities
        try modelContext.save()
    }
    
    func clearExpiredResults(maxAge: TimeInterval = 7 * 24 * 60 * 60) async throws {
        let cutoffDate = Date().addingTimeInterval(-maxAge)
        
        let predicate = #Predicate<AnalysisResult> { result in
            result.lastUpdated < cutoffDate
        }
        
        let descriptor = FetchDescriptor<AnalysisResult>(predicate: predicate)
        
        do {
            let expiredResults = try modelContext.fetch(descriptor)
            for result in expiredResults {
                modelContext.delete(result)
            }
            try modelContext.save()
        } catch {
            throw AnalysisRepositoryError.deleteFailed(error)
        }
    }
    
    func deleteResult(for contentHash: String) async throws {
        guard let result = await getCachedResult(for: contentHash) else {
            return // Already deleted or doesn't exist
        }
        
        modelContext.delete(result)
        try modelContext.save()
    }
}

enum AnalysisRepositoryError: Error {
    case resultNotFound
    case saveFailed(Error)
    case deleteFailed(Error)
    case fetchFailed(Error)
    
    var localizedDescription: String {
        switch self {
        case .resultNotFound:
            return "Analysis result not found"
        case .saveFailed(let error):
            return "Failed to save analysis: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete analysis: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch analysis: \(error.localizedDescription)"
        }
    }
}
