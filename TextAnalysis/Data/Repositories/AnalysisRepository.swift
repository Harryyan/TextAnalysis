//
//  AnalysisRepository.swift
//  TextAnalysis
//
//  Created by HarryYan on 13/07/2025.
//

import Foundation
import SwiftData

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
    
    func updateQuickAnalysis(existingAnalysisResult: AnalysisResult, analysis: QuickAnalysis) async throws {
        existingAnalysisResult.quickAnalysis = analysis
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
