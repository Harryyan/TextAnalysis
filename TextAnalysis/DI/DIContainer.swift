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
        let foundationService = FoundationModelsService()
        let analysisRepository = AnalysisRepository(modelContext: modelContext)
        let documentAnalysisUseCase = DocumentAnalysisUseCase(analysisRepository: analysisRepository)
        
        return StreamingSummaryViewModel(
            document: document,
            foundationService: foundationService,
            documentAnalysisUseCase: documentAnalysisUseCase
        )
    }
    
    func makeFileDetailViewModel(file: FileDocument) -> FileDetailViewModel {
        let foundationService = FoundationModelsService()
        let modelAvailability = ModelAvailabilityService.shared
        
        return FileDetailViewModel(
            file: file,
            foundationService: foundationService,
            modelAvailability: modelAvailability
        )
    }
}
