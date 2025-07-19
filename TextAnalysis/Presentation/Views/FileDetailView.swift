import SwiftUI

struct FileDetailView: View {
    @State private var viewModel: FileDetailViewModel
    
    init(file: FileDocument) {
        let foundationService = FoundationModelsService()
        let modelAvailability = ModelAvailabilityService()
        self._viewModel = State(wrappedValue: FileDetailViewModel(
            file: file,
            foundationService: foundationService,
            modelAvailability: modelAvailability
        ))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with file info
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.fileName)
                    .font(.title2)
                    .bold()
                
                HStack {
                    Text("Type: \(viewModel.fileTypeDisplayName)")
                    Spacer()
                    Text("Loaded: \(viewModel.fileTimestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Content based on file type
            ZStack(alignment: .bottom) {
                if viewModel.isPDFFile, let url = viewModel.fileURL {
                    PDFViewWrapper(url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        Text(viewModel.fileContent)
                            .font(.body)
                            .textSelection(.enabled)
                            .padding()
                            .padding(.bottom, 80) // Add space for button
                    }
                }
                
                // AI Summary button at bottom center (only if model is available)
                if viewModel.isModelAvailable {
                    Button(action: {
                        viewModel.prewarmAndShowSummary()
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
                } else if let reason = viewModel.unavailabilityReason {
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
        .sheet(isPresented: $viewModel.showingSummary) {
            NavigationView {
                StreamingSummaryView(document: viewModel.documentForSummary, foundationService: viewModel.foundationServiceForSummary)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                viewModel.showingSummary = false
                            }
                        }
                    }
            }
        }
    }
}
