import SwiftUI

struct FileDetailView: View {
    let file: FileDocument
    @State private var showingSummary = false
    @State private var modelAvailability = ModelAvailabilityService()
    @State private var foundationService = FoundationModelsService()
    
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
                        Task {
                            do {
                                try await foundationService.prewarmSession()
                            } catch {
                                print("Prewarming failed: \(error)")
                            }
                        }
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
                StreamingSummaryView(document: file, foundationService: foundationService)
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
