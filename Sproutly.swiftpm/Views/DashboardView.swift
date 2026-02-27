//
//  DashboardView.swift
//  Sproutly
//
//  Created by Jash Madhani on 03/02/26.
//

import SwiftUI
import SwiftData

// MARK: - Scroll Offset Tracking

struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Dashboard View

/// Clean summary screen — header, progress ring, domain progress bars,
/// recent moments, screening reminders, education, and growth tip.
/// Milestone interaction lives in MilestonesView.
struct DashboardView: View {
    @Query(sort: \Milestone.ageMonth) private var milestones: [Milestone]
    @Environment(\.modelContext) private var modelContext
    @Environment(ChildProfile.self) private var childProfile
    @Environment(ThemeManager.self) private var theme

    @State private var scrollOffset: CGFloat = 0

    private var isCompactHeader: Bool { scrollOffset < -10 }

    // MARK: - Derived Data

    private var correctedAge: Int { max(0, childProfile.calculateCorrectedAge()) }

    /// All distinct age brackets in the seeded data, sorted ascending.
    private var allAgeBrackets: [Int] {
        Array(Set(milestones.map(\.ageMonth))).sorted()
    }

    /// Smart progression: stays on the most recent incomplete bracket
    /// (≤60% done) that the child's age has reached or passed.
    /// Only advances when >60% of the bracket is complete.
    private var targetAgeMonth: Int {
        guard !milestones.isEmpty else { return 6 }
        let brackets = allAgeBrackets
        // Find brackets the child has reached (age >= bracket)
        let reachedBrackets = brackets.filter { $0 <= correctedAge }
        // Walk backwards through reached brackets to find the first incomplete one
        for bracket in reachedBrackets.reversed() {
            let bracketMilestones = milestones.filter { $0.ageMonth == bracket }
            let completed = bracketMilestones.filter(\.isCompleted).count
            let total = bracketMilestones.count
            guard total > 0 else { continue }
            let progress = Double(completed) / Double(total)
            if progress <= 0.6 {
                return bracket
            }
        }
        // All reached brackets are >60% done — show the nearest bracket to current age
        return brackets.min(by: { abs($0 - correctedAge) < abs($1 - correctedAge) }) ?? 6
    }

    private var currentStageMilestones: [Milestone] {
        milestones.filter { $0.ageMonth == targetAgeMonth }
    }

    private var currentStageCompleted: Int {
        currentStageMilestones.filter(\.isCompleted).count
    }

    private var currentStageTotal: Int {
        currentStageMilestones.count
    }

    private var currentStageProgress: Double {
        guard currentStageTotal > 0 else { return 0 }
        return Double(currentStageCompleted) / Double(currentStageTotal)
    }

    private var completedMilestones: [Milestone] {
        milestones
            .filter(\.isCompleted)
            .sorted { ($0.dateCompleted ?? .distantPast) > ($1.dateCompleted ?? .distantPast) }
    }

    private func categoryStats(_ category: MilestoneCategory) -> (completed: Int, total: Int) {
        let cat = milestones.filter { $0.category == category.rawValue }
        return (cat.filter(\.isCompleted).count, cat.count)
    }

    // MARK: - Development Focus Engine

    /// Milestones flagged for review: incomplete and child age ≥ milestone age + 2 months.
    /// Uses 2-month threshold per AAP/CDC developmental surveillance guidance.
    private var flaggedMilestones: [Milestone] {
        milestones.filter { milestone in
            !milestone.isCompleted && correctedAge >= milestone.ageMonth + 2
        }
    }

    /// True when there are meaningful developmental gaps worth surfacing.
    private var hasDevelopmentFocus: Bool {
        flaggedMilestones.count >= 2
    }

    /// Tiered concern level based on count and domain spread.
    private var concernLevel: ConcernLevel {
        let domainCount = Set(flaggedMilestones.map(\.category)).count
        if flaggedMilestones.count >= 3 || domainCount >= 2 {
            return .needsAttention
        }
        return .reviewSuggested
    }

    /// Groups flagged milestones by domain for the breakdown display.
    private var domainConcerns: [DomainConcern] {
        let grouped = Dictionary(grouping: flaggedMilestones, by: \.category)
        return grouped.compactMap { categoryRaw, milestones in
            guard let category = MilestoneCategory(rawValue: categoryRaw) else { return nil }
            return DomainConcern(
                id: categoryRaw,
                category: category,
                milestoneCount: milestones.count
            )
        }
        .sorted { $0.milestoneCount > $1.milestoneCount }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            AmbientBackground(nightMode: theme.isNightMode)

            ScrollView {
                VStack(spacing: 28) {
                    headerCard
                    progressCard
                    if hasDevelopmentFocus {
                        developmentFocusCard
                    }
                    categoryOverview
                    recentMomentsCard
                    screeningCards
                    growthInsightsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("dashScroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "dashScroll")
            .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
            .scrollDismissesKeyboard(.interactively)
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [.clear, .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                    Color.black
                }
                .ignoresSafeArea()
            )

            // Compact sticky header
            VStack {
                HStack(spacing: 12) {
                    Text("Sproutly")
                        .font(.system(.callout, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(theme.text)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .opacity(isCompactHeader ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: isCompactHeader)

                Spacer()
            }
            .ignoresSafeArea()
        }
        .onAppear {
            if milestones.isEmpty {
                DataSeeder.seedIfNeeded(modelContext: modelContext)
            }
        }
    }

    // =========================================================================
    // MARK: - Header Card
    // =========================================================================

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingText)
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)

            Text(childProfile.name.isEmpty ? "Little one" : childProfile.name)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(theme.text)

            Text("You're \(childProfile.humanReadableAge)!")
                .font(.callout)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    // =========================================================================
    // MARK: - Progress Ring
    // =========================================================================

    private var progressCard: some View {
        VStack(spacing: 20) {
            ZStack {
                MilestoneRingView(
                    progress: currentStageProgress,
                    completedCount: currentStageCompleted,
                    totalCount: currentStageTotal,
                    nightMode: theme.isNightMode
                )
                .frame(width: 160, height: 160)

                VStack(spacing: 2) {
                    Text("\(currentStageCompleted)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.text)

                    Text("of \(currentStageTotal)")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)

                    Text("milestones")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            Text("\(targetAgeMonth)-month milestones")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }

    // =========================================================================
    // MARK: - Category Overview (Bento Grid)
    // =========================================================================

    private var categoryOverview: some View {
        let columns = [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ]

        return VStack(alignment: .leading, spacing: 14) {
            Text("Growth Domains")
                .font(.callout.weight(.semibold))
                .foregroundStyle(theme.text)
                .padding(.leading, 4)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(MilestoneCategory.allCases, id: \.self) { category in
                    domainTile(category)
                }
            }
        }
    }

    private func domainTile(_ category: MilestoneCategory) -> some View {
        let stats = categoryStats(category)
        let progress = stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0
        let domainColor = category.color(for: theme.isNightMode)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 17))
                    .foregroundStyle(domainColor)

                Spacer()

                Text("\(stats.completed)/\(stats.total)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text.opacity(0.7))
                    .monospacedDigit()
            }

            Text(category.gentleLabel)
                .font(.callout.weight(.medium))
                .foregroundStyle(theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.text.opacity(0.06))
                        .frame(height: 6)

                    Capsule()
                        .fill(domainColor.opacity(0.8))
                        .frame(width: max(0, geo.size.width * progress), height: 6)
                        .animation(.easeOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(domainColor.opacity(theme.isNightMode ? 0.16 : 0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(domainColor.opacity(0.12), lineWidth: 1)
        )
    }

    // =========================================================================
    // MARK: - Recent Moments
    // =========================================================================

    private var recentMomentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Moments")
                .font(.callout.weight(.semibold))
                .foregroundStyle(theme.text)
                .padding(.leading, 4)

            if completedMilestones.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(theme.textSecondary)
                    Text("Moments you notice will appear here")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(theme.isNightMode ? Theme.nightCard : .white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.text.opacity(0.04), lineWidth: 1)
                )
            } else {
                ForEach(completedMilestones.prefix(3)) { milestone in
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(theme.green)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(milestone.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(theme.text)
                                .lineLimit(1)

                            if let date = milestone.dateCompleted {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(.caption)
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.isNightMode ? Theme.nightCard : .white)
                    )
                    .shadow(
                        color: theme.isNightMode
                            ? Color.black.opacity(0.2)
                            : Theme.dayText.opacity(0.04),
                        radius: 8,
                        x: 0,
                        y: 3
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(theme.text.opacity(0.04), lineWidth: 1)
                    )
                }
            }
        }
    }

    // =========================================================================
    // MARK: - Screening Cards
    // =========================================================================

    private var screeningCards: some View {
        ScreeningCardView(
            correctedAge: correctedAge,
            nightMode: theme.isNightMode
        )
    }

    // =========================================================================
    // MARK: - Growth Insights (Merged)
    // =========================================================================

    private var growthInsightsSection: some View {
        GrowthInsightsView(nightMode: theme.isNightMode)
    }

    // =========================================================================
    // MARK: - Development Focus Card
    // =========================================================================

    private var developmentFocusCard: some View {
        DevelopmentFocusView(
            concernLevel: concernLevel,
            domainConcerns: domainConcerns,
            totalFlagged: flaggedMilestones.count,
            nightMode: theme.isNightMode
        )
    }
}

// MARK: - Preview

#Preview {
    let profile = ChildProfile()
    profile.birthDate = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    profile.name = "Preview"
    profile.hasCompletedOnboarding = true

    return DashboardView()
        .environment(profile)
        .environment(ThemeManager())
        .modelContainer(previewContainer)
}
