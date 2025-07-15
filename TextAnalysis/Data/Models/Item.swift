//
//  Item.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var fileName: String
    var fileType: String
    var content: String
    var fileURL: String?
    
    init(timestamp: Date, fileName: String, fileType: FileType, content: String, fileURL: URL? = nil) {
        self.timestamp = timestamp
        self.fileName = fileName
        self.fileType = fileType.rawValue
        self.content = content
        self.fileURL = fileURL?.absoluteString
    }
    
    var fileTypeEnum: FileType {
        FileType(rawValue: fileType) ?? .txt
    }
    
    var url: URL? {
        guard let fileURL = fileURL else { return nil }
        return URL(string: fileURL)
    }
}
