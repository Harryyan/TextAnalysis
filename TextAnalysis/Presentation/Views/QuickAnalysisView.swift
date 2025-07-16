//
//  QuickAnalysisView.swift
//  TextAnalysis
//
//  Created by Claude Code on 16/07/2025.
//

import SwiftUI

struct QuickAnalysisView: View {
    let analysis: QuickAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(.orange)
                Text("Quick Analysis")
                    .font(.headline)
                    .bold()
                Spacer()
                confidenceScoreView
            }
            
            // Analysis Content
            VStack(alignment: .leading, spacing: 12) {
                // Document Type & Complexity
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Document Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(analysis.documentType.rawValue.capitalized)
                            .font(.callout)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Complexity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(analysis.complexity.rawValue.capitalized)
                            .font(.callout)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(complexityColor.opacity(0.1))
                            .foregroundColor(complexityColor)
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                }
                
                // Main Topics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Main Topics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], alignment: .leading, spacing: 8) {
                        ForEach(analysis.mainTopics, id: \.self) { topic in
                            HStack {
                                Image(systemName: "tag.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text(topic)
                                    .font(.callout)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private var confidenceScoreView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Confidence")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Image(systemName: confidenceIcon)
                    .font(.caption)
                    .foregroundColor(confidenceColor)
                Text(String(format: "%.1f/10", analysis.confidenceScore))
                    .font(.caption)
                    .bold()
                    .foregroundColor(confidenceColor)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(confidenceColor.opacity(0.1))
            .cornerRadius(4)
        }
    }
    
    private var complexityColor: Color {
        switch analysis.complexity {
        case .simple:
            return .green
        case .moderate:
            return .orange
        case .complex:
            return .red
        case .advanced:
            return .purple
        }
    }
    
    private var confidenceColor: Color {
        switch analysis.confidenceScore {
        case 8.0...10.0:
            return .green
        case 6.0..<8.0:
            return .orange
        case 4.0..<6.0:
            return .yellow
        default:
            return .red
        }
    }
    
    private var confidenceIcon: String {
        switch analysis.confidenceScore {
        case 8.0...10.0:
            return "checkmark.circle.fill"
        case 6.0..<8.0:
            return "checkmark.circle"
        case 4.0..<6.0:
            return "exclamationmark.circle"
        default:
            return "xmark.circle"
        }
    }
}

#Preview {
    QuickAnalysisView(analysis: QuickAnalysis(
        documentType: .technical,
        complexity: .moderate,
        mainTopics: ["Swift Programming", "iOS Development", "Mobile Architecture", "Clean Code"],
        confidenceScore: 8.5
    ))
    .padding()
}