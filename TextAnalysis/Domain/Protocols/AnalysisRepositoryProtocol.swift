//
//  AnalysisRepositoryProtocol.swift
//  TextAnalysis
//
//  Created by HarryYan on 16/07/2025.
//
import Foundation

protocol AnalysisRepositoryProtocol {
    func getCachedResult(for contentHash: String) async -> AnalysisResult?
    func saveAnalysisResult(_ result: AnalysisResult) async throws
    func updateSummary(existingResult: AnalysisResult, summary: DocumentSummary) async throws
    func updateQuickAnalysis(existingAnalysisResult: AnalysisResult, analysis: QuickAnalysis) async throws
    func clearExpiredResults(maxAge: TimeInterval) async throws
    func deleteResult(for contentHash: String) async throws
}
