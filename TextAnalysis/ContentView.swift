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

struct FileDetailView: View {
    let file: FileDocument
    @State private var showingSummary = false
    @State private var modelAvailability = ModelAvailabilityService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with file info
            VStack(alignment: .leading, spacing: 8) {
                Text(file.fileName)
                    .font(.title2)
                    .bold()
                
                HStack {
                    Text("Type: \(file.fileType.displayName)")
                    Spacer()
                    Text("Loaded: \(file.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Content based on file type
            ZStack(alignment: .bottom) {
                if file.fileType == .pdf, let url = file.url {
                    PDFViewWrapper(url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        Text(file.content)
                            .font(.body)
                            .textSelection(.enabled)
                            .padding()
                            .padding(.bottom, 80) // Add space for button
                    }
                }
                
                // AI Summary button at bottom center (only if model is available)
                if modelAvailability.isAvailable {
                    Button(action: {
                        showingSummary = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Generate AI Summary")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 20)
                } else if let reason = modelAvailability.getUnavailabilityReason() {
                    // Show unavailability message
                    VStack(spacing: 8) {
                        Image(systemName: "apple.intelligence.badge.xmark")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("AI Features Unavailable")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("File Content")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSummary) {
            NavigationView {
                StreamingSummaryView(document: file)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showingSummary = false
                            }
                        }
                    }
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
