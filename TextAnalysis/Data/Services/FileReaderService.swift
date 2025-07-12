//
//  FileReaderService.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Foundation
import PDFKit

protocol FileReaderServiceProtocol {
    func loadResourceFiles() async -> [FileDocument]
    func readFile(at url: URL) async -> String?
}

class FileReaderService: FileReaderServiceProtocol {
    
    func loadResourceFiles() async -> [FileDocument] {
        var documents: [FileDocument] = []
        
        // Define the resource files to load directly from bundle
        let resourceFiles = [
            ("sample", "txt"),
            ("Sample-Financial-Statements-1", "pdf")
        ]
        
        for (fileName, fileExtension) in resourceFiles {
            guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
                print("File not found in bundle: \(fileName).\(fileExtension)")
                continue
            }
            
            guard let fileType = FileType(rawValue: fileExtension) else { continue }
            
            let content = await readFile(at: fileURL) ?? ""
            let document = FileDocument(
                fileName: "\(fileName).\(fileExtension)",
                fileType: fileType,
                content: content,
                url: fileURL
            )
            documents.append(document)
        }
        
        return documents
    }
    
    func readFile(at url: URL) async -> String? {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "txt":
            return await readTextFile(at: url)
        case "pdf":
            return await readPDFFile(at: url)
        default:
            print("Unsupported file type: \(pathExtension)")
            return nil
        }
    }
    
    private func readTextFile(at url: URL) async -> String? {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return content
        } catch {
            print("Error reading text file: \(error)")
            return nil
        }
    }
    
    private func readPDFFile(at url: URL) async -> String? {
        guard let pdfDocument = PDFDocument(url: url) else {
            print("Error: Could not create PDF document from URL")
            return nil
        }
        
        var fullText = ""
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            if let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        return fullText.isEmpty ? "PDF content could not be extracted" : fullText
    }
}
