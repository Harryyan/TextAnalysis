//
//  FileRepository.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Foundation
import SwiftData

class FileRepository: FileRepositoryProtocol {
    private let modelContext: ModelContext
    private let fileReaderService: FileReaderServiceProtocol
    
    init(modelContext: ModelContext, fileReaderService: FileReaderServiceProtocol) {
        self.modelContext = modelContext
        self.fileReaderService = fileReaderService
    }
    
    func loadResourceFiles() async -> [FileDocument] {
        return await fileReaderService.loadResourceFiles()
    }
    
    func getAllFiles() async -> [FileDocument] {
        let descriptor = FetchDescriptor<Item>()
        do {
            let items = try modelContext.fetch(descriptor)
            return items.map { item in
                FileDocument(
                    fileName: item.fileName,
                    fileType: item.fileTypeEnum,
                    content: item.content,
                    url: item.url,
                    timestamp: item.timestamp
                )
            }
        } catch {
            print("Error fetching files: \(error)")
            return []
        }
    }
    
    func saveFile(_ file: FileDocument) async throws {
        let item = Item(
            timestamp: file.timestamp,
            fileName: file.fileName,
            fileType: file.fileType,
            content: file.content,
            fileURL: file.url
        )
        modelContext.insert(item)
        try modelContext.save()
    }
    
    func deleteFile(_ file: FileDocument) async throws {
        let fileName = file.fileName
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.fileName == fileName }
        )
        
        do {
            let items = try modelContext.fetch(descriptor)
            for item in items {
                modelContext.delete(item)
            }
            try modelContext.save()
        } catch {
            throw error
        }
    }
}