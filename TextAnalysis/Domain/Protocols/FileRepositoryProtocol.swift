//
//  FileRepositoryProtocol.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import Foundation

protocol FileRepositoryProtocol {
    func loadResourceFiles() async -> Result<[FileDocument], FileError>
    func getAllFiles() async -> Result<[FileDocument], FileError>
    func saveFile(_ file: FileDocument) async -> Result<Void, FileError>
    func deleteFile(_ file: FileDocument) async -> Result<Void, FileError>
}
