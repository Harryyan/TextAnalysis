//
//  ErrorEntity.swift
//  TextAnalysis
//
//  Created by HarryYan on 19/07/2025.
//

import Foundation

enum FileError: Error, Equatable {
    case fileNotFound(fileName: String)
    case fileReadingFailed(fileName: String, reason: String)
    case fileWritingFailed(fileName: String, reason: String)
    case fileDeletionFailed(fileName: String, reason: String)
    case invalidFileFormat(fileName: String, expectedFormat: String)
    case storageError(reason: String)
    case resourceLoadingFailed(reason: String)
    case unknown(reason: String)
    
    var userFriendlyMessage: String {
        switch self {
        case .fileNotFound(let fileName):
            return "File '\(fileName)' not found"
        case .fileReadingFailed(let fileName, _):
            return "Failed to read file '\(fileName)'"
        case .fileWritingFailed(let fileName, _):
            return "Failed to save file '\(fileName)'"
        case .fileDeletionFailed(let fileName, _):
            return "Failed to delete file '\(fileName)'"
        case .invalidFileFormat(let fileName, let expectedFormat):
            return "File '\(fileName)' is not a valid \(expectedFormat) file"
        case .storageError(_):
            return "Storage error occurred"
        case .resourceLoadingFailed(_):
            return "Failed to load resource files"
        case .unknown(_):
            return "An unexpected error occurred"
        }
    }
    
    var technicalReason: String {
        switch self {
        case .fileNotFound(let fileName):
            return "File not found: \(fileName)"
        case .fileReadingFailed(_, let reason):
            return reason
        case .fileWritingFailed(_, let reason):
            return reason
        case .fileDeletionFailed(_, let reason):
            return reason
        case .invalidFileFormat(let fileName, let expectedFormat):
            return "Expected \(expectedFormat) format for file: \(fileName)"
        case .storageError(let reason):
            return reason
        case .resourceLoadingFailed(let reason):
            return reason
        case .unknown(let reason):
            return reason
        }
    }
}