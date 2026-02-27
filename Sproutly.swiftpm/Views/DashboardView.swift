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

    private var targetAgeMonth: Int {
        guard !milestones.isEmpty else { return 6 }
        let allAges = Set(milestones.map(\.ageMonth))
        return allAges.min(by: { abs($0 - correctedAge) < abs($1 - correctedAge) }) ?? 6
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

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            AmbientBackground(nightMode: theme.isNightMode)

            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                    progressCard
                    categoryOverview
                    recentMomentsCard
                    screeningCards
                    educationSection
                    growthTipCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 54)
                .padding(.bottom, 32)
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
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(theme.text)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)

            Text("\(childProfile.name.isEmpty ? "Little one" : childProfile.name)'s Growth")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(theme.text)

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary)
                Text(childProfile.humanReadableAge)
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
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
        VStack(spacing: 16) {
            ZStack {
                MilestoneRingView(
                    progress: currentStageProgress,
                    completedCount: currentStageCompleted,
                    totalCount: currentStageTotal,
                    nightMode: theme.isNightMode
                )
                .frame(width: 120, height: 120)

                VStack(spacing: 2) {
                    Text("\(currentStageCompleted)")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(theme.text)

                    Text("of \(currentStageTotal)")
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary)

                    Text("milestones")
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            Text("\(targetAgeMonth)-month milestones")
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .warmCard(nightMode: theme.isNightMode)
    }

    // =========================================================================
    // MARK: - Category Overview (Domain Progress Bars)
    // =========================================================================

    private var categoryOverview: some View {
        VStack(spacing: 12) {
            ForEach(MilestoneCategory.allCases, id: \.self) { category in
                let stats = categoryStats(category)
                let progress = stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(category.color(for: theme.isNightMode).opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: category.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(category.color(for: theme.isNightMode))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.gentleLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(theme.text)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(theme.text.opacity(0.06))
                                    .frame(height: 6)

                                Capsule()
                                    .fill(category.color(for: theme.isNightMode).opacity(0.6))
                                    .frame(width: max(0, geo.size.width * progress), height: 6)
                                    .animation(.easeInOut(duration: 0.4), value: progress)
                            }
                        }
                        .frame(height: 6)
                    }

                    Text("\(stats.completed)/\(stats.total)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.textSecondary)
                        .monospacedDigit()
                }
            }
        }
        .warmCard(nightMode: theme.isNightMode)
    }

    // =========================================================================
    // MARK: - Recent Moments
    // =========================================================================

    private var recentMomentsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Moments")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.text)

            if completedMilestones.isEmpty {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(theme.textSecondary)
                    Text("Moments you notice will appear here")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }
                .padding(.vertical, 12)
            } else {
                ForEach(completedMilestones.prefix(5)) { milestone in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(theme.green.opacity(0.15))
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(milestone.title)
                                .font(.subheadline)
                                .foregroundStyle(theme.text)

                            if let date = milestone.dateCompleted {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(.caption2)
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .warmCard(nightMode: theme.isNightMode)
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
    // MARK: - Education
    // =========================================================================

    private var educationSection: some View {
        EducationView(nightMode: theme.isNightMode)
    }

    // =========================================================================
    // MARK: - Growth Tip
    // =========================================================================

    private var growthTipCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(theme.green.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: "leaf.fill")
                    .foregroundStyle(theme.green)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Growth Tip")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.text)

                Text("Children learn best through everyday moments — bath time, walks, and shared meals are all opportunities for gentle growth.")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .warmCard(nightMode: theme.isNightMode)
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
