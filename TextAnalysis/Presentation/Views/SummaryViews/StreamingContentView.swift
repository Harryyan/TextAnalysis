//
//  s.swift
//  TextAnalysis
//
//  Created by HarryYan on 19/07/2025.
//

import SwiftUI

struct StreamingContentView: View {
    let partial: DocumentSummary.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = partial.title {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(title)
                        .contentTransition(.opacity)
                        .font(.headline)
                        .bold()
                }
            }
            
            if let overview = partial.overview {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(overview)
                        .contentTransition(.opacity)
                        .font(.body)
                }
            }
            
            if let keyPoints = partial.keyPoints, !keyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Points (\(keyPoints.count))")
                        .font(.caption)
                        .contentTransition(.opacity)
                        .foregroundColor(.secondary)
                    ForEach(Array(keyPoints.enumerated()), id: \.offset) { index, point in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .foregroundColor(.blue)
                                .bold()
                            Text(point)
                                .contentTransition(.opacity)
                                .font(.callout)
                        }
                    }
                }
            }
            
            if let conclusion = partial.conclusion {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Conclusion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(conclusion)
                        .contentTransition(.opacity)
                        .font(.body)
                }
            }
            
            if let readingTime = partial.estimatedReadingTimeMinutes {
                HStack {
                    Image(systemName: "clock")
                    Text("Estimated reading time: \(readingTime) minutes")
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
        }
        .animation(.easeInOut, value: partial)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

