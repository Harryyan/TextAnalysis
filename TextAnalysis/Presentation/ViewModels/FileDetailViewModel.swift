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
    private let foundationService: FoundationModelsService
    private let modelAvailability: ModelAvailabilityService
    
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
        modelAvailability.isAvailable
    }
    
    var unavailabilityReason: String? {
        modelAvailability.getUnavailabilityReason()
    }
    
    var foundationServiceForSummary: FoundationModelsService {
        foundationService
    }
    
    init(file: FileDocument, foundationService: FoundationModelsService, modelAvailability: ModelAvailabilityService) {
        self.file = file
        self.foundationService = foundationService
        self.modelAvailability = modelAvailability
    }
    
    func prewarmAndShowSummary() {
        isPrewarming = true
        
        Task {
            do {
                try await foundationService.prewarmSession()
            } catch {
                print("Prewarming failed: \(error)")
            }
            
            isPrewarming = false
            showingSummary = true
        }
    }
}