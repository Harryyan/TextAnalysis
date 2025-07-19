//
//  ErrorEntityTests.swift
//  TextAnalysisTests
//
//  Created by HarryYan on 19/07/2025.
//

import Testing
import Foundation
@testable import TextAnalysis

final class ErrorEntityTests {
    
    @Test("FileError should provide user-friendly messages")
    func testUserFriendlyMessages() {
        let fileNotFoundError = FileError.fileNotFound(fileName: "test.txt")
        #expect(fileNotFoundError.userFriendlyMessage == "File 'test.txt' not found")
        
        let readingError = FileError.fileReadingFailed(fileName: "document.pdf", reason: "Corrupted file")
        #expect(readingError.userFriendlyMessage == "Failed to read file 'document.pdf'")
        
        let writingError = FileError.fileWritingFailed(fileName: "output.txt", reason: "Disk full")
        #expect(writingError.userFriendlyMessage == "Failed to save file 'output.txt'")
        
        let deletionError = FileError.fileDeletionFailed(fileName: "temp.txt", reason: "File in use")
        #expect(deletionError.userFriendlyMessage == "Failed to delete file 'temp.txt'")
        
        let formatError = FileError.invalidFileFormat(fileName: "data.txt", expectedFormat: "PDF")
        #expect(formatError.userFriendlyMessage == "File 'data.txt' is not a valid PDF file")
        
        let storageError = FileError.storageError(reason: "Database connection failed")
        #expect(storageError.userFriendlyMessage == "Storage error occurred")
        
        let resourceError = FileError.resourceLoadingFailed(reason: "No resource files found")
        #expect(resourceError.userFriendlyMessage == "Failed to load resource files")
        
        let unknownError = FileError.unknown(reason: "Unexpected error")
        #expect(unknownError.userFriendlyMessage == "An unexpected error occurred")
    }
    
    @Test("FileError should provide technical reasons")
    func testTechnicalReasons() {
        let fileNotFoundError = FileError.fileNotFound(fileName: "test.txt")
        #expect(fileNotFoundError.technicalReason == "File not found: test.txt")
        
        let readingError = FileError.fileReadingFailed(fileName: "document.pdf", reason: "Corrupted file")
        #expect(readingError.technicalReason == "Corrupted file")
        
        let writingError = FileError.fileWritingFailed(fileName: "output.txt", reason: "Disk full")
        #expect(writingError.technicalReason == "Disk full")
        
        let deletionError = FileError.fileDeletionFailed(fileName: "temp.txt", reason: "File in use")
        #expect(deletionError.technicalReason == "File in use")
        
        let formatError = FileError.invalidFileFormat(fileName: "data.txt", expectedFormat: "PDF")
        #expect(formatError.technicalReason == "Expected PDF format for file: data.txt")
        
        let storageError = FileError.storageError(reason: "Database connection failed")
        #expect(storageError.technicalReason == "Database connection failed")
        
        let resourceError = FileError.resourceLoadingFailed(reason: "No resource files found")
        #expect(resourceError.technicalReason == "No resource files found")
        
        let unknownError = FileError.unknown(reason: "Unexpected error")
        #expect(unknownError.technicalReason == "Unexpected error")
    }
    
    @Test("FileError should be equatable")
    func testEquatable() {
        let error1 = FileError.fileNotFound(fileName: "test.txt")
        let error2 = FileError.fileNotFound(fileName: "test.txt")
        let error3 = FileError.fileNotFound(fileName: "other.txt")
        
        #expect(error1 == error2)
        #expect(error1 != error3)
        
        let readError1 = FileError.fileReadingFailed(fileName: "doc.pdf", reason: "corrupted")
        let readError2 = FileError.fileReadingFailed(fileName: "doc.pdf", reason: "corrupted")
        let readError3 = FileError.fileReadingFailed(fileName: "doc.pdf", reason: "different reason")
        
        #expect(readError1 == readError2)
        #expect(readError1 != readError3)
    }
}