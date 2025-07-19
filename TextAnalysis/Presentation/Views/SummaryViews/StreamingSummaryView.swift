//
//  StreamingSummaryView.swift
//  TextAnalysis
//
//  Created by HarryYan on 13/07/2025.
//

import SwiftUI
import SwiftData
import FoundationModels

struct StreamingSummaryView: View {
    let document: FileDocument
    let foundationService: FoundationModelsService
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StreamingSummaryViewModel
    
    init(document: FileDocument, foundationService: FoundationModelsService) {
        self.document = document
        self.foundationService = foundationService
        // Temporary placeholder - will be replaced in onAppear
        let tempModelContext: ModelContext
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Item.self, configurations: configuration)
            tempModelContext = container.mainContext
        } catch {
            // Fallback to a default configuration
            do {
                let fallbackContainer = try ModelContainer(for: Item.self)
                tempModelContext = fallbackContainer.mainContext
            } catch {
                // This should never happen in practice, but provides a safe fallback
                fatalError("Unable to create ModelContainer: \(error)")
            }
        }
        
        self._viewModel = State(wrappedValue: StreamingSummaryViewModel(
            document: document,
            foundationService: foundationService,
            documentAnalysisUseCase: DocumentAnalysisUseCase(analysisRepository: AnalysisRepository(modelContext: tempModelContext))
        ))
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    
                    // Quick Analysis Section
                    quickAnalysisSection
                    
                    if viewModel.isGenerating {
                        streamingProgressSection
                    } else if let summary = viewModel.currentSummary {
                        summaryDisplaySection(summary)
                            .id("completedSummary") // Add ID for scroll targeting
                    } else {
                        generateButtonSection
                    }
                    
                    if let error = viewModel.errorMessage {
                        errorSection(error)
                    }
                }
                .padding()
                .onChange(of: viewModel.partialSummary) { _, newPartial in
                    // Auto-scroll when new content is generated
                    if newPartial != nil && viewModel.isGenerating {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("streamingContent", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isGenerating) { _, generating in
                    // Auto-scroll when generation completes
                    if !generating && viewModel.currentSummary != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("completedSummary", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("AI Summary")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Replace the placeholder ViewModel with properly injected one
            viewModel = DIContainer.shared.makeStreamingSummaryViewModel(
                document: document,
                foundationService: foundationService,
                modelContext: modelContext
            )
            viewModel.loadCachedData()
        }
        .onDisappear {
            viewModel.cancelAllTasks()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Document Analysis")
                .font(.title2)
                .bold()
            
            Text(document.fileName)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Label("Type: \(document.fileType.displayName)", systemImage: "doc.text")
                Spacer()
                Label("Size: \(document.content.count) chars", systemImage: "info.circle")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var quickAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let analysis = viewModel.quickAnalysis {
                QuickAnalysisView(analysis: analysis)
            } else if viewModel.isAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Performing quick analysis...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Button(action: viewModel.performQuickAnalysis) {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal")
                        Text("Quick Analysis")
                    }
                    .font(.callout)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(viewModel.isGenerating || viewModel.isAnalyzing)
            }
        }
    }
    
    private var generateButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: viewModel.startStreamingGeneration) {
                HStack {
                    Image(systemName: viewModel.currentSummary != nil ? "arrow.clockwise" : "brain")
                    Text(viewModel.currentSummary != nil ? "Regenerate AI Summary" : "Generate AI Summary")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(viewModel.isGenerating)
            
            if viewModel.currentSummary != nil {
                Text("Tap to regenerate with fresh analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("This will analyze your document using Apple's Foundation Models")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var streamingProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Generating summary...")
                    .font(.headline)
                Spacer()
            }
            
            ProgressView(value: viewModel.generationProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
            
            if let partial = viewModel.partialSummary {
                StreamingContentView(partial: partial)
                    .id("streamingContent") // Add ID for scroll targeting
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func summaryDisplaySection(_ summary: DocumentSummary) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(summary.title)
                    .font(.title2)
                    .bold()
            }
            
            Divider()
            
            // Overview
            VStack(alignment: .leading, spacing: 8) {
                Text("Overview")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(summary.overview)
                    .font(.body)
            }
            
            Divider()
            
            // Key Points
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Points")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ForEach(Array(summary.keyPoints.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.body)
                            .foregroundColor(.blue)
                            .bold()
                        Text(point)
                            .font(.body)
                        Spacer()
                    }
                }
            }
            
            Divider()
            
            // Conclusion
            VStack(alignment: .leading, spacing: 8) {
                Text("Conclusion")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(summary.conclusion)
                    .font(.body)
            }
            
            // Reading Time
            HStack {
                Image(systemName: "clock")
                Text("Estimated reading time: \(summary.estimatedReadingTimeMinutes) minutes")
                Spacer()
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top)
            
            // Regenerate button
            Button(action: viewModel.startStreamingGeneration) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Regenerate Summary")
                }
                .font(.callout)
                .foregroundColor(.blue)
            }
            .padding(.top)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func errorSection(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text(error)
                .font(.callout)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}
