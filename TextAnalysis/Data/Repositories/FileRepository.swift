//
//  FileRepository.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Foundation
import SwiftData

struct FileRepository: FileRepositoryProtocol {
    private let modelContext: ModelContext
    private let fileReaderService: FileReaderServiceProtocol
    
    init(modelContext: ModelContext, fileReaderService: some FileReaderServiceProtocol) {
        self.modelContext = modelContext
        self.fileReaderService = fileReaderService
    }
    
    func loadResourceFiles() async -> Result<[FileDocument], FileError> {
        let documents = await fileReaderService.loadResourceFiles()
        if documents.isEmpty {
            return .failure(.resourceLoadingFailed(reason: "No resource files found"))
        }
        return .success(documents)
    }
    
    func getAllFiles() async -> Result<[FileDocument], FileError> {
        let descriptor = FetchDescriptor<Item>()
        do {
            let items = try modelContext.fetch(descriptor)
            let documents = items.map { item in
                FileDocument(
                    fileName: item.fileName,
                    fileType: item.fileTypeEnum,
                    content: item.content,
                    url: item.url,
                    timestamp: item.timestamp
                )
            }
            return .success(documents)
        } catch {
            return .failure(.storageError(reason: "Failed to fetch files: \(error.localizedDescription)"))
        }
    }
    
    func saveFile(_ file: FileDocument) async -> Result<Void, FileError> {
        do {
            let item = Item(
                timestamp: file.timestamp,
                fileName: file.fileName,
                fileType: file.fileType,
                content: file.content,
                fileURL: file.url
            )
            modelContext.insert(item)
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(.fileWritingFailed(fileName: file.fileName, reason: error.localizedDescription))
        }
    }
    
    func deleteFile(_ file: FileDocument) async -> Result<Void, FileError> {
        let fileName = file.fileName
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.fileName == fileName }
        )
        
        do {
            let items = try modelContext.fetch(descriptor)
            if items.isEmpty {
                return .failure(.fileNotFound(fileName: fileName))
            }
            for item in items {
                modelContext.delete(item)
            }
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(.fileDeletionFailed(fileName: fileName, reason: error.localizedDescription))
        }
    }
}
