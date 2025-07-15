//
//  DIContainer.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Foundation
import SwiftData

@MainActor
final class DIContainer {
    static let shared = DIContainer()
    
    private init() {}
    
    func makeFileListViewModel(modelContext: ModelContext) -> FileListViewModel {
        let fileReaderService = FileReaderService()
        let fileRepository = FileRepository(modelContext: modelContext, fileReaderService: fileReaderService)
        let loadFilesUseCase = LoadFilesUseCase(fileRepository: fileRepository)
        
        return FileListViewModel(loadFilesUseCase: loadFilesUseCase)
    }
}
