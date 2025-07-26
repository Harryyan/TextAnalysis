//
//  DIContainer.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class DIContainer: ObservableObject {
    static let shared = DIContainer()
    
    private init() {}
    
    func makeFileListViewModel(modelContext: ModelContext) -> FileListViewModel {
        let fileReaderService = FileReaderService()
        let fileRepository = FileRepository(modelContext: modelContext, fileReaderService: fileReaderService)
        let loadFilesUseCase = LoadFilesUseCase(fileRepository: fileRepository)
        
        return FileListViewModel(loadFilesUseCase: loadFilesUseCase)
    }
    
    func makeStreamingSummaryViewModel(document: FileDocument, modelContext: ModelContext) -> StreamingSummaryViewModel {
        // AI-related dependencies
        let foundationService = FoundationModelsService()
        let modelAvailability = ModelAvailabilityService.shared
        let aiRepository = AIRepository(foundationService: foundationService, modelAvailability: modelAvailability)
        let documentSummaryUseCase = DocumentSummaryUseCase(aiRepository: aiRepository)
        
        // Analysis-related dependencies
        let analysisRepository = AnalysisRepository(modelContext: modelContext)
        let documentAnalysisUseCase = DocumentAnalysisUseCase(analysisRepository: analysisRepository)
        
        return StreamingSummaryViewModel(
            document: document,
            documentAnalysisUseCase: documentAnalysisUseCase,
            documentSummaryUseCase: documentSummaryUseCase
        )
    }
    
    func makeFileDetailViewModel(file: FileDocument) -> FileDetailViewModel {
        // Create AI-related dependencies
        let foundationService = FoundationModelsService()
        let modelAvailability = ModelAvailabilityService.shared
        let aiRepository = AIRepository(foundationService: foundationService, modelAvailability: modelAvailability)
        let documentSummaryUseCase = DocumentSummaryUseCase(aiRepository: aiRepository)
        
        return FileDetailViewModel(
            file: file,
            documentSummaryUseCase: documentSummaryUseCase
        )
    }
}
