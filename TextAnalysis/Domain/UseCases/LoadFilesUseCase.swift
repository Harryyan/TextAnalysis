//
//  LoadFilesUseCase.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Foundation

protocol LoadFilesUseCaseProtocol {
    func loadResourceFiles() async -> [FileDocument]
    func getAllFiles() async -> [FileDocument]
    func deleteFile(_ file: FileDocument) async throws
    func saveFile(_ file: FileDocument) async throws
}

final class LoadFilesUseCase: LoadFilesUseCaseProtocol {
    private let fileRepository: FileRepositoryProtocol
    
    init(fileRepository: FileRepositoryProtocol) {
        self.fileRepository = fileRepository
    }
    
    func loadResourceFiles() async -> [FileDocument] {
        return await fileRepository.loadResourceFiles()
    }
    
    func getAllFiles() async -> [FileDocument] {
        return await fileRepository.getAllFiles()
    }
    
    func deleteFile(_ file: FileDocument) async throws {
        try await fileRepository.deleteFile(file)
    }
    
    func saveFile(_ file: FileDocument) async throws {
        try await fileRepository.saveFile(file)
    }
}