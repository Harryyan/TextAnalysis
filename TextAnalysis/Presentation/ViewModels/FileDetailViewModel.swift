//
//  FileDetailViewModel.swift
//  TextAnalysis
//
//  Created by Claude Code on 19/07/2025.
//

import Foundation

@MainActor
@Observable final class FileDetailViewModel {
    var showingSummary = false
    var isPrewarming = false
    
    private let file: FileDocument
    private let documentSummaryUseCase: DocumentSummaryUseCaseProtocol
    
    var fileName: String {
        file.fileName
    }
    
    var fileTypeDisplayName: String {
        file.fileType.displayName
    }
    
    var fileTimestamp: Date {
        file.timestamp
    }
    
    var isPDFFile: Bool {
        file.fileType == .pdf
    }
    
    var fileURL: URL? {
        file.url
    }
    
    var fileContent: String {
        file.content
    }
    
    var documentForSummary: FileDocument {
        file
    }
    
    var isModelAvailable: Bool {
        let result = documentSummaryUseCase.checkModelAvailability()
        switch result {
        case .success(let isAvailable):
            return isAvailable
        case .failure(_):
            return false
        }
    }
    
    var unavailabilityReason: String? {
        return documentSummaryUseCase.getUnavailabilityReason()
    }
    
    init(file: FileDocument, documentSummaryUseCase: DocumentSummaryUseCaseProtocol) {
        self.file = file
        self.documentSummaryUseCase = documentSummaryUseCase
    }
    
    func prewarmAndShowSummary() {
        isPrewarming = true
        
        Task {
            let result = await documentSummaryUseCase.prewarmModel()
            switch result {
            case .success():
                break // Success, no action needed
            case .failure(let error):
                print("Prewarming failed: \(error.userFriendlyMessage)")
            }
            
            isPrewarming = false
            showingSummary = true
        }
    }
}