//
//  DocumentAnalysisUseCase.swift
//  TextAnalysis
//
//  Created by HarryYan on 19/07/2025.
//

import Foundation

protocol DocumentAnalysisUseCaseProtocol {
    func getCachedAnalysis(for contentHash: String) async -> Result<AnalysisResult?, FileError>
    func saveDocumentSummary(contentHash: String, fileName: String, fileType: FileType, summary: DocumentSummary) async -> Result<Void, FileError>
    func saveQuickAnalysis(contentHash: String, fileName: String, fileType: FileType, analysis: QuickAnalysis) async -> Result<Void, FileError>
    func updateExistingSummary(existingResult: AnalysisResult, summary: DocumentSummary) async -> Result<Void, FileError>
    func updateExistingQuickAnalysis(existingResult: AnalysisResult, analysis: QuickAnalysis) async -> Result<Void, FileError>
    func clearExpiredAnalysis(maxAge: TimeInterval) async -> Result<Void, FileError>
    func deleteAnalysis(for contentHash: String) async -> Result<Void, FileError>
}

final class DocumentAnalysisUseCase: DocumentAnalysisUseCaseProtocol {
    private let analysisRepository: AnalysisRepositoryProtocol
    
    init(analysisRepository: AnalysisRepositoryProtocol) {
        self.analysisRepository = analysisRepository
    }
    
    func getCachedAnalysis(for contentHash: String) async -> Result<AnalysisResult?, FileError> {
        do {
            let result = await analysisRepository.getCachedResult(for: contentHash)
            return .success(result)
        } catch {
            return .failure(.storageError(reason: "Failed to retrieve cached analysis: \(error.localizedDescription)"))
        }
    }
    
    func saveDocumentSummary(contentHash: String, fileName: String, fileType: FileType, summary: DocumentSummary) async -> Result<Void, FileError> {
        do {
            let analysisResult = AnalysisResult(
                contentHash: contentHash,
                fileName: fileName,
                fileType: fileType,
                summary: summary
            )
            try await analysisRepository.saveAnalysisResult(analysisResult)
            return .success(())
        } catch {
            return .failure(.fileWritingFailed(fileName: fileName, reason: "Failed to save summary: \(error.localizedDescription)"))
        }
    }
    
    func saveQuickAnalysis(contentHash: String, fileName: String, fileType: FileType, analysis: QuickAnalysis) async -> Result<Void, FileError> {
        do {
            let analysisResult = AnalysisResult(
                contentHash: contentHash,
                fileName: fileName,
                fileType: fileType,
                quickAnalysis: analysis
            )
            try await analysisRepository.saveAnalysisResult(analysisResult)
            return .success(())
        } catch {
            return .failure(.fileWritingFailed(fileName: fileName, reason: "Failed to save analysis: \(error.localizedDescription)"))
        }
    }
    
    func updateExistingSummary(existingResult: AnalysisResult, summary: DocumentSummary) async -> Result<Void, FileError> {
        do {
            try await analysisRepository.updateSummary(existingResult: existingResult, summary: summary)
            return .success(())
        } catch {
            return .failure(.fileWritingFailed(fileName: existingResult.fileName, reason: "Failed to update summary: \(error.localizedDescription)"))
        }
    }
    
    func updateExistingQuickAnalysis(existingResult: AnalysisResult, analysis: QuickAnalysis) async -> Result<Void, FileError> {
        do {
            try await analysisRepository.updateQuickAnalysis(existingAnalysisResult: existingResult, analysis: analysis)
            return .success(())
        } catch {
            return .failure(.fileWritingFailed(fileName: existingResult.fileName, reason: "Failed to update analysis: \(error.localizedDescription)"))
        }
    }
    
    func clearExpiredAnalysis(maxAge: TimeInterval) async -> Result<Void, FileError> {
        do {
            try await analysisRepository.clearExpiredResults(maxAge: maxAge)
            return .success(())
        } catch {
            return .failure(.storageError(reason: "Failed to clear expired analysis: \(error.localizedDescription)"))
        }
    }
    
    func deleteAnalysis(for contentHash: String) async -> Result<Void, FileError> {
        do {
            try await analysisRepository.deleteResult(for: contentHash)
            return .success(())
        } catch {
            return .failure(.fileDeletionFailed(fileName: "analysis", reason: "Failed to delete analysis: \(error.localizedDescription)"))
        }
    }
}