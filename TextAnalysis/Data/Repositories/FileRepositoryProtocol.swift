//
//  FileRepositoryProtocol.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Foundation

protocol FileRepositoryProtocol {
    func loadResourceFiles() async -> [FileDocument]
    func getAllFiles() async -> [FileDocument]
    func saveFile(_ file: FileDocument) async throws
    func deleteFile(_ file: FileDocument) async throws
}