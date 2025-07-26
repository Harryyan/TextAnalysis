//
//  ContentChunker.swift
//  TextAnalysis
//
//  Created by HarryYan on 13/07/2025.
//

import Foundation

struct ContentChunk {
    let content: String
    let index: Int
    let totalChunks: Int
    let estimatedTokens: Int
}

final class ContentChunker {
    static let defaultMaxTokens = 3000
    static let overlapTokens = 200
    static let charactersPerToken = 4
    
    static func chunkContent(
        _ content: String,
        maxTokens: Int = defaultMaxTokens,
        preserveContext: Bool = true
    ) -> [ContentChunk] {
        let maxCharacters = maxTokens * charactersPerToken
        
        if content.count <= maxCharacters {
            return [ContentChunk(
                content: content,
                index: 0,
                totalChunks: 1,
                estimatedTokens: estimateTokenCount(content)
            )]
        }
        
        var chunks: [ContentChunk] = []
        let sentences = splitIntoSentences(content)
        var currentChunk = ""
        var currentSentences: [String] = []
        
        for sentence in sentences {
            let potentialChunk = currentChunk + sentence + " "
            
            if potentialChunk.count > maxCharacters && !currentChunk.isEmpty {
                // Finalize current chunk
                chunks.append(createChunk(
                    content: currentChunk.trimmingCharacters(in: .whitespacesAndNewlines),
                    index: chunks.count,
                    totalChunks: 0 // Will update later
                ))
                
                // Start new chunk with overlap if preserveContext is true
                if preserveContext && currentSentences.count > 1 {
                    let overlapSentences = Array(currentSentences.suffix(2))
                    currentChunk = overlapSentences.joined(separator: " ") + " "
                    currentSentences = overlapSentences
                } else {
                    currentChunk = ""
                    currentSentences = []
                }
            }
            
            currentChunk += sentence + " "
            currentSentences.append(sentence)
        }
        
        // Add final chunk if not empty
        if !currentChunk.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            chunks.append(createChunk(
                content: currentChunk.trimmingCharacters(in: .whitespacesAndNewlines),
                index: chunks.count,
                totalChunks: 0
            ))
        }
        
        // Update total chunks count
        let totalChunks = chunks.count
        chunks = chunks.map { chunk in
            ContentChunk(
                content: chunk.content,
                index: chunk.index,
                totalChunks: totalChunks,
                estimatedTokens: chunk.estimatedTokens
            )
        }
        
        return chunks
    }
    
    static func chunkByParagraphs(
        _ content: String,
        maxTokens: Int = defaultMaxTokens
    ) -> [ContentChunk] {
        let maxCharacters = maxTokens * charactersPerToken
        let paragraphs = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        var chunks: [ContentChunk] = []
        var currentChunk = ""
        
        for paragraph in paragraphs {
            let potentialChunk = currentChunk + paragraph + "\n\n"
            
            if potentialChunk.count > maxCharacters && !currentChunk.isEmpty {
                chunks.append(createChunk(
                    content: currentChunk.trimmingCharacters(in: .whitespacesAndNewlines),
                    index: chunks.count,
                    totalChunks: 0
                ))
                currentChunk = paragraph + "\n\n"
            } else {
                currentChunk = potentialChunk
            }
        }
        
        if !currentChunk.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            chunks.append(createChunk(
                content: currentChunk.trimmingCharacters(in: .whitespacesAndNewlines),
                index: chunks.count,
                totalChunks: 0
            ))
        }
        
        let totalChunks = chunks.count
        return chunks.map { chunk in
            ContentChunk(
                content: chunk.content,
                index: chunk.index,
                totalChunks: totalChunks,
                estimatedTokens: chunk.estimatedTokens
            )
        }
    }
    
    static func estimateTokenCount(_ content: String) -> Int {
        return content.count / charactersPerToken
    }
    
    static func estimateProcessingTime(_ content: String) -> TimeInterval {
        let tokenCount = estimateTokenCount(content)
        // Rough estimate: ~500 tokens per second for generation
        return Double(tokenCount) / 500.0
    }
    
    static func canProcessInSingleSession(_ content: String, maxTokens: Int = defaultMaxTokens) -> Bool {
        return estimateTokenCount(content) <= maxTokens
    }
    
    private static func splitIntoSentences(_ content: String) -> [String] {
        let sentenceDetector = try? NSRegularExpression(
            pattern: #"[.!?]+\s+"#,
            options: []
        )
        
        guard let detector = sentenceDetector else {
            // Fallback: split by periods
            return content.components(separatedBy: ". ")
        }
        
        let range = NSRange(content.startIndex..., in: content)
        let matches = detector.matches(in: content, options: [], range: range)
        
        var sentences: [String] = []
        var lastEnd = content.startIndex
        
        for match in matches {
            guard let matchRange = Range(match.range, in: content) else { continue }
            let sentence = String(content[lastEnd..<matchRange.lowerBound])
            if !sentence.trimmingCharacters(in: .whitespaces).isEmpty {
                sentences.append(sentence.trimmingCharacters(in: .whitespaces))
            }
            lastEnd = matchRange.upperBound
        }
        
        // Add remaining content
        let remaining = String(content[lastEnd...])
        if !remaining.trimmingCharacters(in: .whitespaces).isEmpty {
            sentences.append(remaining.trimmingCharacters(in: .whitespaces))
        }
        
        return sentences.filter { !$0.isEmpty }
    }
    
    private static func createChunk(content: String, index: Int, totalChunks: Int) -> ContentChunk {
        ContentChunk(
            content: content,
            index: index,
            totalChunks: totalChunks,
            estimatedTokens: estimateTokenCount(content)
        )
    }
}

extension ContentChunker {
    static func combineChunkSummaries(_ summaries: [DocumentSummary]) -> DocumentSummary {
        guard !summaries.isEmpty else {
            return DocumentSummary(
                title: "Empty Document",
                overview: "No content to summarize",
                keyPoints: [],
                conclusion: "Document appears to be empty",
                estimatedReadingTimeMinutes: 0
            )
        }
        
        if summaries.count == 1 {
            return summaries[0]
        }
        
        let combinedTitle = summaries.first?.title ?? "Combined Summary"
        let combinedOverview = "Summary combining \(summaries.count) document sections: " +
                              summaries.compactMap { $0.overview.prefix(100) }.joined(separator: "; ")
        
        let allKeyPoints = summaries.flatMap { $0.keyPoints }
        let uniqueKeyPoints = Array(Set(allKeyPoints)).prefix(5)
        
        let totalReadingTime = summaries.reduce(0) { $0 + $1.estimatedReadingTimeMinutes }
        
        let combinedConclusion = "This document contains multiple sections with varying themes and complexity. " +
                               "Key insights span across \(summaries.count) main areas of content."
        
        return DocumentSummary(
            title: combinedTitle,
            overview: combinedOverview,
            keyPoints: Array(uniqueKeyPoints),
            conclusion: combinedConclusion,
            estimatedReadingTimeMinutes: totalReadingTime
        )
    }
}
