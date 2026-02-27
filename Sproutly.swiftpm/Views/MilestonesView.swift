//
//  MilestonesView.swift
//  Sproutly
//
//  Created by Jash Madhani on 27/02/26.
//

import SwiftUI
import SwiftData

// MARK: - Filter Mode

enum MilestoneFilter: String, CaseIterable {
    case thisStage = "This Stage"
    case all = "All"
    case completed = "Completed"
}

// MARK: - Milestones View

/// Dedicated browsing view for all developmental milestones.
/// Supports segmented filtering and domain-based collapsible grouping.
struct MilestonesView: View {
    @Query(sort: \Milestone.ageMonth) private var milestones: [Milestone]
    @Environment(\.modelContext) private var modelContext
    @Environment(ChildProfile.self) private var childProfile
    @Environment(ThemeManager.self) private var theme

    @State private var selectedFilter: MilestoneFilter = .thisStage
    @State private var expandedDomains: Set<String> = Set(MilestoneCategory.allCases.map(\.rawValue))
    @State private var scrollOffset: CGFloat = 0

    private var isCompactHeader: Bool { scrollOffset < -10 }

    // MARK: - Derived Data

    private var correctedAge: Int { max(0, childProfile.calculateCorrectedAge()) }

    private var targetAgeMonth: Int {
        guard !milestones.isEmpty else { return 6 }
        let allAges = Set(milestones.map(\.ageMonth))
        return allAges.min(by: { abs($0 - correctedAge) < abs($1 - correctedAge) }) ?? 6
    }

    private var filteredMilestones: [Milestone] {
        switch selectedFilter {
        case .thisStage:
            return milestones.filter { $0.ageMonth == targetAgeMonth }
        case .all:
            return milestones
        case .completed:
            return milestones
                .filter(\.isCompleted)
                .sorted { ($0.dateCompleted ?? .distantPast) > ($1.dateCompleted ?? .distantPast) }
        }
    }

    private func milestonesForDomain(_ category: MilestoneCategory) -> [Milestone] {
        filteredMilestones.filter { $0.category == category.rawValue }
    }

    private func domainStats(_ category: MilestoneCategory) -> (completed: Int, total: Int) {
        let domain = milestonesForDomain(category)
        return (domain.filter(\.isCompleted).count, domain.count)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            AmbientBackground(nightMode: theme.isNightMode)

            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    filterPicker
                    domainGroups
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("milestonesScroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "milestonesScroll")
            .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
            .scrollDismissesKeyboard(.interactively)
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 80)
                    Color.black
                }
                .ignoresSafeArea()
            )

            // Compact sticky header
            VStack {
                HStack {
                    Text("Milestones")
                        .font(.system(.subheadline, design: .rounded))
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
    }

    // =========================================================================
    // MARK: - Header
    // =========================================================================

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Milestones")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(theme.text)

            Text(ageDescription)
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private var ageDescription: String {
        let months = correctedAge
        if months < 24 {
            return "\(months) month\(months == 1 ? "" : "s") corrected age"
        } else {
            let years = months / 12
            let rem = months % 12
            if rem == 0 {
                return "\(years) year\(years == 1 ? "" : "s") corrected age"
            }
            return "\(years)y \(rem)m corrected age"
        }
    }

    // =========================================================================
    // MARK: - Filter Picker
    // =========================================================================

    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(MilestoneFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 4)
    }

    // =========================================================================
    // MARK: - Domain Groups
    // =========================================================================

    private var domainGroups: some View {
        VStack(spacing: 12) {
            ForEach(MilestoneCategory.allCases, id: \.self) { category in
                let domainMilestones = milestonesForDomain(category)
                let stats = domainStats(category)

                if !domainMilestones.isEmpty || selectedFilter == .thisStage || selectedFilter == .all {
                    domainSection(category: category, milestones: domainMilestones, stats: stats)
                }
            }

            if filteredMilestones.isEmpty {
                emptyState
            }
        }
    }

    private func domainSection(
        category: MilestoneCategory,
        milestones: [Milestone],
        stats: (completed: Int, total: Int)
    ) -> some View {
        let isExpanded = expandedDomains.contains(category.rawValue)

        return VStack(spacing: 0) {
            // Domain header
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    if isExpanded {
                        expandedDomains.remove(category.rawValue)
                    } else {
                        expandedDomains.insert(category.rawValue)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(category.color(for: theme.isNightMode).opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: category.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(category.color(for: theme.isNightMode))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.gentleLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(theme.text)

                        Text("\(stats.completed) of \(stats.total)")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expanded milestone rows
            if isExpanded {
                VStack(spacing: 8) {
                    if milestones.isEmpty {
                        Text("No milestones in this filter.")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                            .padding(.bottom, 12)
                    } else {
                        ForEach(milestones) { milestone in
                            milestoneRow(milestone)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity)
            }
        }
        .warmCard(nightMode: theme.isNightMode)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isExpanded)
    }

    // =========================================================================
    // MARK: - Milestone Row
    // =========================================================================

    private func milestoneRow(_ milestone: Milestone) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .foregroundStyle(theme.text)
                    .strikethrough(milestone.isCompleted, color: theme.green.opacity(0.4))

                Text(milestone.expectedAgeText)
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            OneTapLogButton(
                isCompleted: milestone.isCompleted,
                nightMode: theme.isNightMode
            ) {
                toggleMilestone(milestone)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    milestone.isCompleted
                        ? theme.green.opacity(theme.isNightMode ? 0.06 : 0.04)
                        : theme.text.opacity(0.02)
                )
        )
    }

    // =========================================================================
    // MARK: - Empty State
    // =========================================================================

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(theme.textSecondary)

            Text(selectedFilter == .completed
                 ? "No milestones completed yet.\nTap + to celebrate a moment!"
                 : "No milestones available.")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    // =========================================================================
    // MARK: - Actions
    // =========================================================================

    private func toggleMilestone(_ milestone: Milestone) {
        // Optimistic UI: update in memory instantly
        milestone.isCompleted.toggle()
        milestone.dateCompleted = milestone.isCompleted ? Date() : nil

        // Async save — don't block the main thread
        let ctx = modelContext
        Task.detached { @MainActor in
            try? ctx.save()
        }
    }
}

// MARK: - Preview

#Preview {
    let profile = ChildProfile()
    profile.birthDate = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    profile.name = "Preview"
    profile.hasCompletedOnboarding = true

    return MilestonesView()
        .environment(profile)
        .environment(ThemeManager())
        .modelContainer(previewContainer)
}
