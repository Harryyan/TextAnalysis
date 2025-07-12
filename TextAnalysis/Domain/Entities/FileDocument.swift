//
//  FileDocument.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Foundation

struct FileDocument: Identifiable, Equatable, Hashable {
    let id = UUID()
    let fileName: String
    let fileType: FileType
    let content: String
    let timestamp: Date
    let url: URL?
    
    init(fileName: String, fileType: FileType, content: String, url: URL? = nil, timestamp: Date = Date()) {
        self.fileName = fileName
        self.fileType = fileType
        self.content = content
        self.url = url
        self.timestamp = timestamp
    }
}

enum FileType: String, CaseIterable, Codable {
    case pdf = "pdf"
    case txt = "txt"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .txt: return "Text"
        }
    }
}