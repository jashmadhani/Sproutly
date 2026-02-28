//
//  DevelopmentEvaluator.swift
//  Sproutly
//
//  Created by Jash Madhani on 23/02/26.
//

import SwiftUI

// MARK: - Domain Status


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
    

    func color(for nightMode: Bool) -> Color {
        switch self {
        case .onTrack:        return Theme.growthGreen(for: nightMode)
        case .emerging:       return Theme.accentBlue(for: nightMode)
        case .needsSupport:   return Theme.encourageYellow(for: nightMode)
        case .worthDiscussing: return Theme.cognitiveColor(for: nightMode)
        }
    }
    

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


struct DomainEvaluation: Identifiable {
    let id = UUID()
    let category: MilestoneCategory
    let completed: Int
    let total: Int
    let ratio: Double
    let status: DomainStatus
}

// MARK: - Development Evaluator

// centralized so dashboard and milestones stay in sync
struct DevelopmentEvaluator {
    

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
        // milestones up to current age
        let relevant = milestones.filter {
            $0.category == category.rawValue && $0.ageMonth <= correctedAge
        }
        
        let total = relevant.count
        let completed = relevant.filter(\.isCompleted).count
        

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
    
    // ≥0.75 on track, 0.5–0.74 emerging, 0.3–0.49 needs support, <0.3 worth discussing
    private static func classifyStatus(
        ratio: Double,
        total: Int,
        correctedAge: Int,
        category: MilestoneCategory
    ) -> DomainStatus {
        // No milestones expected yet → on track by default
        guard total > 0 else { return .onTrack }
        
        // language gets 1.2× weight so it's slightly more sensitive
        let adjustedRatio = ratio / category.focusWeight

        let effectiveRatio = min(adjustedRatio, 1.0)
        
        switch effectiveRatio {
        case 0.75...1.0:
            return .onTrack
        case 0.50..<0.75:
            return .emerging
        case 0.30..<0.50:
            return .needsSupport
        default:
            // only suggest discussing if ≥9 months
            return correctedAge >= 9 ? .worthDiscussing : .needsSupport
        }
    }
}
