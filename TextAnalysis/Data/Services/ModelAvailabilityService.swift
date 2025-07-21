//
//  ModelAvailabilityService.swift
//  TextAnalysis
//
//  Created by HarryYan on 14/07/2025.
//

import Foundation
import FoundationModels

enum ModelAvailabilityStatus {
    case available
    case unavailable(reason: String)
}

@Observable final class ModelAvailabilityService: Sendable {
    static let shared = ModelAvailabilityService()
    
    private let availabilityStatus: ModelAvailabilityStatus
    private let systemModel = SystemLanguageModel.default
    
    private init() {
        switch systemModel.availability {
        case .available:
            availabilityStatus = .available
            
        case .unavailable(let reason):
            let reasonText = switch reason {
            case .appleIntelligenceNotEnabled:
                "Apple Intelligence is not enabled. Enable it in Settings > Apple Intelligence & Siri."
            case .deviceNotEligible:
                "This device doesn't support Apple Intelligence. Requires iPhone 15 Pro/Pro Max, M-series iPad, or M-series Mac."
            case .modelNotReady:
                "Apple Intelligence model is downloading. Please wait and try again."
            @unknown default:
                "Apple Intelligence is unavailable. Check device settings, battery level, and ensure Game Mode is disabled."
            }
            availabilityStatus = .unavailable(reason: reasonText)
        }
    }
    
    var isAvailable: Bool {
        if case .available = availabilityStatus {
            return true
        }
        return false
    }
    
    func getUnavailabilityReason() -> String? {
        if case .unavailable(let reason) = availabilityStatus {
            return reason
        }
        return nil
    }
}
