//
//  LoadFilesUseCaseTests.swift
//  TextAnalysisTests
//
//  Created by HarryYan on 19/07/2025.
//

import Testing
import Foundation
@testable import TextAnalysis

@MainActor
final class LoadFilesUseCaseTests {
    
    @Test("LoadFilesUseCase should return success when repository succeeds")
    func testLoadFilesSuccess() async {
        let mockRepository = MockFileRepository()
        let useCase = LoadFilesUseCase(fileRepository: mockRepository)
        
        let testFile = FileDocument(fileName: "test.txt", fileType: .txt, content: "test content")
        mockRepository.mockFiles = [testFile]
        
        let result = await useCase.getAllFiles()
        
        switch result {
        case .success(let files):
            #expect(files.count == 1)
            #expect(files.first?.fileName == "test.txt")
        case .failure:
            #expect(Bool(false), "Expected success but got failure")
        }
    }
    
    @Test("LoadFilesUseCase should return failure when repository fails")
    func testLoadFilesFailure() async {
        let mockRepository = MockFileRepository()
        let useCase = LoadFilesUseCase(fileRepository: mockRepository)
        
        mockRepository.shouldFailGetAllFiles = true
        
        let result = await useCase.getAllFiles()
        
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure but got success")
        case .failure(let error):
            #expect(error == .storageError(reason: "Mock error"))
        }
    }
    
    @Test("LoadFilesUseCase should handle delete file success")
    func testDeleteFileSuccess() async {
        let mockRepository = MockFileRepository()
        let useCase = LoadFilesUseCase(fileRepository: mockRepository)
        
        let testFile = FileDocument(fileName: "test.txt", fileType: .txt, content: "test content")
        
        let result = await useCase.deleteFile(testFile)
        
        switch result {
        case .success:
            #expect(Bool(true))
        case .failure:
            #expect(Bool(false), "Expected success but got failure")
        }
    }
    
    @Test("LoadFilesUseCase should handle delete file failure")
    func testDeleteFileFailure() async {
        let mockRepository = MockFileRepository()
        let useCase = LoadFilesUseCase(fileRepository: mockRepository)
        
        mockRepository.shouldFailDeleteFile = true
        let testFile = FileDocument(fileName: "nonexistent.txt", fileType: .txt, content: "test content")
        
        let result = await useCase.deleteFile(testFile)
        
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure but got success")
        case .failure(let error):
            #expect(error == .fileNotFound(fileName: "nonexistent.txt"))
        }
    }
}

// MARK: - Mock Repository

private final class MockFileRepository: FileRepositoryProtocol {
    var mockFiles: [FileDocument] = []
    var shouldFailGetAllFiles = false
    var shouldFailDeleteFile = false
    var shouldFailSaveFile = false
    
    func loadResourceFiles() async -> Result<[FileDocument], FileError> {
        return .success([])
    }
    
    func getAllFiles() async -> Result<[FileDocument], FileError> {
        if shouldFailGetAllFiles {
            return .failure(.storageError(reason: "Mock error"))
        }
        return .success(mockFiles)
    }
    
    func saveFile(_ file: FileDocument) async -> Result<Void, FileError> {
        if shouldFailSaveFile {
            return .failure(.fileWritingFailed(fileName: file.fileName, reason: "Mock save error"))
        }
        mockFiles.append(file)
        return .success(())
    }
    
    func deleteFile(_ file: FileDocument) async -> Result<Void, FileError> {
        if shouldFailDeleteFile {
            return .failure(.fileNotFound(fileName: file.fileName))
        }
        mockFiles.removeAll { $0.fileName == file.fileName }
        return .success(())
    }
}