//
//  AnalysisResult.swift
//  TextAnalysis
//
//  Created by HarryYan on 13/07/2025.
//

import Foundation
import SwiftData

@Model
final class AnalysisResult {
    var contentHash: String
    var fileName: String
    var fileType: String
    var summaryData: Data?
    var quickAnalysisData: Data?
    var entitiesData: Data?
    var createdAt: Date
    var lastUpdated: Date
    
    init(
        contentHash: String,
        fileName: String,
        fileType: FileType,
        summary: StreamingDocumentSummary? = nil,
        quickAnalysis: QuickAnalysis? = nil,
        entities: EntityExtraction? = nil
    ) {
        self.contentHash = contentHash
        self.fileName = fileName
        self.fileType = fileType.rawValue
        self.createdAt = Date()
        self.lastUpdated = Date()
        
        if let summary = summary {
            self.summaryData = try? JSONEncoder().encode(summary)
        }
        
        if let quickAnalysis = quickAnalysis {
            self.quickAnalysisData = try? JSONEncoder().encode(quickAnalysis)
        }
        
        if let entities = entities {
            self.entitiesData = try? JSONEncoder().encode(entities)
        }
    }
    
    var summary: StreamingDocumentSummary? {
        get {
            guard let data = summaryData else { return nil }
            return try? JSONDecoder().decode(StreamingDocumentSummary.self, from: data)
        }
        set {
            summaryData = try? JSONEncoder().encode(newValue)
            lastUpdated = Date()
        }
    }
    
    var quickAnalysis: QuickAnalysis? {
        get {
            guard let data = quickAnalysisData else { return nil }
            return try? JSONDecoder().decode(QuickAnalysis.self, from: data)
        }
        set {
            quickAnalysisData = try? JSONEncoder().encode(newValue)
            lastUpdated = Date()
        }
    }
    
    var entities: EntityExtraction? {
        get {
            guard let data = entitiesData else { return nil }
            return try? JSONDecoder().decode(EntityExtraction.self, from: data)
        }
        set {
            entitiesData = try? JSONEncoder().encode(newValue)
            lastUpdated = Date()
        }
    }
    
    static func generateContentHash(for content: String) -> String {
        return String(content.hashValue)
    }
    
    func isExpired(maxAge: TimeInterval = 7 * 24 * 60 * 60) -> Bool {
        return Date().timeIntervalSince(lastUpdated) > maxAge
    }
}