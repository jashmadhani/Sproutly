//
//  EducationView.swift
//  Sproutly
//
//  Created by Jash Madhani on 19/02/26.
//

import SwiftUI

/// Educational content about the five developmental domains,
/// surveillance vs screening, and why early identification matters.
/// Accessible from the Reflect tab.
struct EducationView: View {
    let nightMode: Bool
    
    @State private var expandedSection: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Understanding Growth", systemImage: "book.fill")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.accentBlue(for: nightMode))
            
            educationRow(
                id: "domains",
                icon: "square.grid.3x3.fill",
                title: "The Five Domains",
                body: """
                    Child development is often observed across five areas:
                    
                    • Gross Motor — Large movements like walking, running, climbing
                    • Fine Motor — Small movements like grasping, drawing, stacking
                    • Language — Understanding and using words, gestures, and sounds
                    • Cognitive — Thinking, problem-solving, learning, curiosity
                    • Social-Emotional — Relationships, emotions, behavior, empathy
                    
                    Every child develops across all five areas, but the pace is beautifully unique to each child.
                    """
            )
            
            educationRow(
                id: "surveillance",
                icon: "eye.fill",
                title: "Observation vs Screening",
                body: """
                    Developmental surveillance is the ongoing, gentle observation that happens naturally — noticing what your child can do at each age. This is what Sproutly helps with.
                    
                    Developmental screening uses brief, standardized tools at specific ages (9, 18, and 30 months) to check whether development is on track. Your pediatrician handles these.
                    
                    Both work together to support your child's growth.
                    """
            )
            
            educationRow(
                id: "early",
                icon: "heart.fill",
                title: "Why Early Matters",
                body: """
                    Research consistently shows that early identification of developmental differences leads to better outcomes. The brain is most adaptable in the earliest years.
                    
                    If a concern is identified, early intervention programs can provide support — and a referral does not require a confirmed diagnosis. These programs focus on building skills through everyday interactions.
                    
                    Early support is not about labels. It's about giving every child the best possible start.
                    """
            )
            
            educationRow(
                id: "when",
                icon: "stethoscope",
                title: "When to Ask",
                body: """
                    Trust your instincts. You know your child best. Some situations where a conversation with your pediatrician can be helpful:
                    
                    • If speech development seems slower than expected, a hearing screening can rule out simple causes
                    • If you notice differences in social engagement, early evaluation can open doors to support
                    • Any time you feel uncertain — pediatricians welcome these questions
                    
                    Well-child visits are the perfect time for these conversations.
                    """
            )
        }
        .warmCard(nightMode: nightMode)
    }
    
    private func educationRow(id: String, icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 1.0)) {
                    expandedSection = expandedSection == id ? nil : id
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(Theme.accentBlue(for: nightMode))
                        .frame(width: 20)

                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.textPrimary(for: nightMode))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary(for: nightMode))
                        .rotationEffect(.degrees(expandedSection == id ? 90 : 0))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(expandedSection == id ? "Double tap to collapse" : "Double tap to expand")

            if expandedSection == id {
                Text(body)
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary(for: nightMode))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .padding(.leading, 30)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 5)
        .clipped()
        .animation(.spring(response: 0.35, dampingFraction: 1.0), value: expandedSection)
    }
}
