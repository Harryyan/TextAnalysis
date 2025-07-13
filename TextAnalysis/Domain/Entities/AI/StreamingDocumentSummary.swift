//
//  StreamingDocumentSummary.swift
//  TextAnalysis
//
//  Created by HarryYan on 13/07/2025.
//

import Foundation
import FoundationModels

@Generable
struct StreamingDocumentSummary: Codable, Equatable {
    let title: String
    let overview: String
    
    @Guide(.minimumCount(3))
    @Guide(.maximumCount(5))
    let keyPoints: [String]
    
    let conclusion: String
    
    @Guide(.range(1...100))
    let estimatedReadingTimeMinutes: Int
}

@Generable
struct QuickAnalysis: Codable, Equatable {
    let documentType: DocumentCategory
    let complexity: ComplexityLevel
    
    @Guide(.minimumCount(2))
    @Guide(.maximumCount(4))
    let mainTopics: [String]
    
    @Guide(.range(1.0...10.0))
    let confidenceScore: Double
}

@Generable
enum DocumentCategory: String, Codable, CaseIterable {
    case technical = "technical"
    case business = "business" 
    case academic = "academic"
    case creative = "creative"
    case legal = "legal"
    case personal = "personal"
    case financial = "financial"
    case other = "other"
}

@Generable
enum ComplexityLevel: String, Codable, CaseIterable {
    case simple = "simple"
    case moderate = "moderate"
    case complex = "complex"
    case advanced = "advanced"
}

@Generable
struct EntityExtraction: Codable, Equatable {
    @Guide(.minimumCount(0))
    @Guide(.maximumCount(10))
    let people: [String]
    
    @Guide(.minimumCount(0))
    @Guide(.maximumCount(10))
    let organizations: [String]
    
    @Guide(.minimumCount(0))
    @Guide(.maximumCount(10))
    let locations: [String]
    
    @Guide(.minimumCount(0))
    @Guide(.maximumCount(15))
    let keyTerms: [String]
}
