//
//  DevelopmentEvaluator.swift
//  Sproutly
//
//  Created by Jash Madhani on 23/02/26.
//

import SwiftUI

// MARK: - Domain Status

/// Represents the developmental status of a single domain.
/// Language is intentionally supportive and non-diagnostic —
/// these are observational heuristics, not clinical assessments.
enum DomainStatus: String, CaseIterable {
    case onTrack       = "On Track"
    case emerging      = "Emerging"
    case needsSupport  = "Needs Support"
    case worthDiscussing = "Worth Discussing"
    
    var icon: String {
        switch self {
        case .onTrack:        return "checkmark.circle.fill"
        case .emerging:       return "leaf.fill"
        case .needsSupport:   return "heart.circle.fill"
        case .worthDiscussing: return "message.circle.fill"
        }
    }
    
    /// Soft, theme-aware accent color — never red, never alarming.
    func color(for nightMode: Bool) -> Color {
        switch self {
        case .onTrack:        return Theme.growthGreen(for: nightMode)
        case .emerging:       return Theme.accentBlue(for: nightMode)
        case .needsSupport:   return Theme.encourageYellow(for: nightMode)
        case .worthDiscussing: return Theme.cognitiveColor(for: nightMode)
        }
    }
    
    /// Warm, reassuring subtitle shown beneath the status label.
    var supportiveMessage: String {
        switch self {
        case .onTrack:        return "Growing beautifully"
        case .emerging:       return "Growth unfolds at its own pace"
        case .needsSupport:   return "A little extra encouragement helps"
        case .worthDiscussing: return "Consider discussing at your next visit"
        }
    }
}

// MARK: - Domain Evaluation Result

/// Holds the evaluation result for a single developmental domain.
struct DomainEvaluation: Identifiable {
    let id = UUID()
    let category: MilestoneCategory
    let completed: Int
    let total: Int
    let ratio: Double
    let status: DomainStatus
}

// MARK: - Development Evaluator

/// Centralized, deterministic evaluation engine.
///
/// Computes domain-level developmental status from milestone data
/// using the child's corrected age. Results are heuristic guidance,
/// not clinical diagnosis.
///
/// Architecture note: Views never compute status themselves —
/// they call `DevelopmentEvaluator.evaluate(...)` and consume the result.
struct DevelopmentEvaluator {
    
    /// Evaluates all five developmental domains.
    ///
    /// - Parameters:
    ///   - milestones: All milestones from the data store.
    ///   - correctedAge: The child's corrected age in months.
    /// - Returns: One `DomainEvaluation` per `MilestoneCategory`, in standard order.
    static func evaluate(
        milestones: [Milestone],
        correctedAge: Int
    ) -> [DomainEvaluation] {
        MilestoneCategory.allCases.map { category in
            evaluateDomain(
                category: category,
                milestones: milestones,
                correctedAge: correctedAge
            )
        }
    }
    
    // MARK: - Private
    
    private static func evaluateDomain(
        category: MilestoneCategory,
        milestones: [Milestone],
        correctedAge: Int
    ) -> DomainEvaluation {
        // Consider milestones up to and including the child's current age window.
        // This gives us the set of milestones the child "should" have encountered.
        let relevant = milestones.filter {
            $0.category == category.rawValue && $0.ageMonth <= correctedAge
        }
        
        let total = relevant.count
        let completed = relevant.filter(\.isCompleted).count
        
        // If no milestones are expected yet, the child is on track by default.
        let ratio = total > 0 ? Double(completed) / Double(total) : 1.0
        
        let status = classifyStatus(
            ratio: ratio,
            total: total,
            correctedAge: correctedAge,
            category: category
        )
        
        return DomainEvaluation(
            category: category,
            completed: completed,
            total: total,
            ratio: ratio,
            status: status
        )
    }
    
    /// Deterministic classification based on completion ratio and context.
    ///
    /// Thresholds:
    ///   ≥ 0.75 → onTrack
    ///   0.50–0.74 → emerging
    ///   0.30–0.49 → needsSupport
    ///   < 0.30 → worthDiscussing (only if child is ≥ 9 months)
    ///
    /// Language domains apply their 1.2× focus weight per NCBI guidance,
    /// making the threshold slightly more sensitive for communication delays.
    private static func classifyStatus(
        ratio: Double,
        total: Int,
        correctedAge: Int,
        category: MilestoneCategory
    ) -> DomainStatus {
        // No milestones expected yet → on track by default
        guard total > 0 else { return .onTrack }
        
        // Apply the category's focus weight (language = 1.2×).
        // A higher weight makes the effective ratio *lower*, increasing sensitivity.
        let adjustedRatio = ratio / category.focusWeight
        // Clamp to [0, 1] so categories with weight 1.0 aren't penalised.
        let effectiveRatio = min(adjustedRatio, 1.0)
        
        switch effectiveRatio {
        case 0.75...1.0:
            return .onTrack
        case 0.50..<0.75:
            return .emerging
        case 0.30..<0.50:
            return .needsSupport
        default:
            // Below 0.30 — only suggest discussing if the child is
            // meaningfully past the earliest age window (≥ 9 months).
            // For very young children, "needs support" is gentler.
            return correctedAge >= 9 ? .worthDiscussing : .needsSupport
        }
    }
}
