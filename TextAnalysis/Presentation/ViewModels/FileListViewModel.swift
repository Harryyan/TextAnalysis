//
//  FileListViewModel.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Foundation
import SwiftUI

@MainActor
@Observable final class FileListViewModel {
    var files: [FileDocument] = []
    var selectedFile: FileDocument?
    var isLoading = false
    var errorMessage: String?
    
    private let loadFilesUseCase: LoadFilesUseCaseProtocol
    
    init(loadFilesUseCase: LoadFilesUseCaseProtocol) {
        self.loadFilesUseCase = loadFilesUseCase
    }
    
    func loadFiles() async {
        isLoading = true
        errorMessage = nil
        
        let result = await loadFilesUseCase.getAllFiles()
        switch result {
        case .success(let documents):
            files = documents
            // If no files exist, automatically load resource files
            if files.isEmpty {
                await loadResourceFilesAutomatically()
            }
        case .failure(let error):
            errorMessage = error.userFriendlyMessage
            files = []
        }
        
        isLoading = false
    }
    
    private func loadResourceFilesAutomatically() async {
        let resourceResult = await loadFilesUseCase.loadResourceFiles()
        switch resourceResult {
        case .success(let resourceFiles):
            var hasErrors = false
            for file in resourceFiles {
                let saveResult = await loadFilesUseCase.saveFile(file)
                if case .failure(let error) = saveResult {
                    errorMessage = error.userFriendlyMessage
                    hasErrors = true
                    break
                }
            }
            
            if !hasErrors {
                // Reload files after adding resource files
                let reloadResult = await loadFilesUseCase.getAllFiles()
                switch reloadResult {
                case .success(let documents):
                    files = documents
                case .failure(let error):
                    errorMessage = error.userFriendlyMessage
                }
            }
        case .failure(let error):
            errorMessage = error.userFriendlyMessage
        }
    }
    
    func deleteFile(_ file: FileDocument) async {
        let result = await loadFilesUseCase.deleteFile(file)
        switch result {
        case .success:
            await loadFiles()
        case .failure(let error):
            errorMessage = error.userFriendlyMessage
        }
    }
    
    func deleteFiles(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let file = files[index]
                await deleteFile(file)
            }
        }
    }
}
