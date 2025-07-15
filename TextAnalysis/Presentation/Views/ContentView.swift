//
//  ContentView.swift
//  TextAnalysis
//
//  Created by HarryYan on 09/07/2025.
//

import SwiftUI
import SwiftData
import PDFKit
import FoundationModels

struct ContentView: View {
    @State var viewModel: FileListViewModel
    
    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedFile) {
                ForEach(viewModel.files) { file in
                    NavigationLink(value: file) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(file.fileName)
                                .font(.headline)
                            Text(file.fileType.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    Task {
                        await viewModel.deleteFiles(at: offsets)
                    }
                }
            }
            .navigationTitle("Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .task {
                await viewModel.loadFiles()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading files...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        } detail: {
            if let selectedFile = viewModel.selectedFile {
                FileDetailView(file: selectedFile)
            } else {
                Text("Select a file to view its content")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: configuration)
    let viewModel = DIContainer.shared.makeFileListViewModel(modelContext: container.mainContext)
    
    ContentView(viewModel: viewModel)
        .modelContainer(container)
}
