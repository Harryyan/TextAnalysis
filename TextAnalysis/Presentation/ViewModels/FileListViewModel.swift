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
        
        files = await loadFilesUseCase.getAllFiles()
        
        // If no files exist, automatically load resource files
        if files.isEmpty {
            await loadResourceFilesAutomatically()
        }
        
        isLoading = false
    }
    
    private func loadResourceFilesAutomatically() async {
        do {
            let resourceFiles = await loadFilesUseCase.loadResourceFiles()
            
            for file in resourceFiles {
                try await loadFilesUseCase.saveFile(file)
            }
            
            // Reload files after adding resource files
            files = await loadFilesUseCase.getAllFiles()
        } catch {
            errorMessage = "Failed to load resource files: \(error.localizedDescription)"
        }
    }
    
    func deleteFile(_ file: FileDocument) async {
        do {
            try await loadFilesUseCase.deleteFile(file)
            await loadFiles()
        } catch {
            errorMessage = "Failed to delete file: \(error.localizedDescription)"
        }
    }
    
    func deleteFiles(at offsets: IndexSet) async {
        for index in offsets {
            let file = files[index]
            await deleteFile(file)
        }
    }
}
