//
//  LoadFilesUseCase.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Foundation

protocol LoadFilesUseCaseProtocol {
    func loadResourceFiles() async -> Result<[FileDocument], FileError>
    func getAllFiles() async -> Result<[FileDocument], FileError>
    func deleteFile(_ file: FileDocument) async -> Result<Void, FileError>
    func saveFile(_ file: FileDocument) async -> Result<Void, FileError>
}

final class LoadFilesUseCase: LoadFilesUseCaseProtocol {
    private let fileRepository: FileRepositoryProtocol
    
    init(fileRepository: FileRepositoryProtocol) {
        self.fileRepository = fileRepository
    }
    
    func loadResourceFiles() async -> Result<[FileDocument], FileError> {
        return await fileRepository.loadResourceFiles()
    }
    
    func getAllFiles() async -> Result<[FileDocument], FileError> {
        return await fileRepository.getAllFiles()
    }
    
    func deleteFile(_ file: FileDocument) async -> Result<Void, FileError> {
        return await fileRepository.deleteFile(file)
    }
    
    func saveFile(_ file: FileDocument) async -> Result<Void, FileError> {
        return await fileRepository.saveFile(file)
    }
}