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

/// Main screen — calm, empathetic developmental companion.
/// Header → Progress Ring → Screening Cards → Milestone Groups → AI Assistant
struct DashboardView: View {
    @Query(sort: \Milestone.ageMonth) private var milestones: [Milestone]
    @Environment(\.modelContext) private var modelContext
    @Environment(ChildProfile.self) private var childProfile
    @Environment(ThemeManager.self) private var theme
    
    @State private var scrollOffset: CGFloat = 0
    @State private var celebrationText: String? = nil
    @State private var celebrationOpacity: Double = 0
    @State private var celebrationOffset: CGFloat = 12
    @State private var expandedCategories: Set<String> = Set(MilestoneCategory.allCases.map(\.rawValue))
    
    private var isCompactHeader: Bool { scrollOffset < -10 }
    
    // MARK: - Age-Based Filtering
    
    private var correctedAge: Int { childProfile.calculateCorrectedAge() }
    
    /// Finds milestones relevant to the child's current developmnetal stage (closest age window).
    private var targetAgeMonth: Int {
        // Get all unique milestone ages
        let allAges = Set(milestones.map(\.ageMonth))
        // Find closest age to correctedAge
        return allAges.min(by: { abs($0 - correctedAge) < abs($1 - correctedAge) }) ?? 6
    }
    
    private var currentMonthMilestones: [Milestone] {
        let target = uiTargetAge // Use computed property for stability
        return milestones.filter { $0.ageMonth == target }
    }
    
    private var uiTargetAge: Int {
        targetAgeMonth
    }
    
    private var pastMilestones: [Milestone] {
        milestones.filter { $0.ageMonth < uiTargetAge }
    }
    
    private var futureMilestones: [Milestone] {
        milestones.filter { $0.ageMonth > uiTargetAge }
    }
    
    private var currentMonthCompleted: Int {
        currentMonthMilestones.filter(\.isCompleted).count
    }
    
    private var currentMonthTotal: Int {
        currentMonthMilestones.count
    }
    
    private var currentMonthProgress: Double {
        guard currentMonthTotal > 0 else { return 0 }
        return Double(currentMonthCompleted) / Double(currentMonthTotal)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            AmbientBackground(nightMode: theme.isNightMode)
            
            if milestones.isEmpty {
                // Loading / Empty State
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(theme.textSecondary)
                    Text("Loading milestones...")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        progressCard
                        screeningCards
                        lateExploringCards
                        milestoneCategoryGroups
                        supportAssistant
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 54)
                    .padding(.bottom, 16)
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
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    scrollOffset = value
                }
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
            }
            
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
            
            // Celebration toast
            if celebrationText != nil {
                VStack {
                    Spacer()
                    Text(celebrationText ?? "")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.text)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(theme.green.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(theme.green.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .opacity(celebrationOpacity)
                        .offset(y: celebrationOffset)
                        .padding(.bottom, 16)
                }
                .ignoresSafeArea(.keyboard)
            }
        }
    }
    
    // =========================================================================
    // MARK: - Header Card
    // =========================================================================
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hi, \(childProfile.name.isEmpty ? "little one" : childProfile.name) 🌱")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(theme.text)
            
            Text(childProfile.humanReadableAge)
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard(nightMode: theme.isNightMode)
    }
    
    // =========================================================================
    // MARK: - Progress Ring (Reverted Design)
    // =========================================================================
    
    private var progressCard: some View {
        HStack(spacing: 20) {
            // Circular Ring
            MilestoneRingView(
                progress: currentMonthProgress,
                completedCount: currentMonthCompleted,
                totalCount: currentMonthTotal,
                nightMode: theme.isNightMode
            )
            .frame(width: 80, height: 80)
            
            // Text Summary
            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentMonthCompleted) of \(currentMonthTotal)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(theme.text)
                
                Text(milestoneSummaryText)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
        .shadow(color: theme.text.opacity(theme.isNightMode ? 0.05 : 0.03), radius: 10, x: 0, y: 4)
    }
    
    private var milestoneSummaryText: String {
        if currentMonthTotal == 0 { return "Loading steps..." }
        if currentMonthCompleted == 0 { return "milestones to explore" }
        if currentMonthCompleted == currentMonthTotal { return "All milestones celebrated!" }
        return "milestones completed"
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
    // MARK: - Late / Exploring Cards
    // =========================================================================
    
    private var lateExploringCards: some View {
        let lateMilestones = currentMonthMilestones.filter {
            $0.isSignificantlyLate(childAgeMonths: correctedAge)
        }
        
        return Group {
            if !lateMilestones.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.circle")
                            .foregroundStyle(theme.yellow)
                        Text("Still exploring")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(theme.text)
                    }
                    
                    Text(Theme.lateMilestoneMessage(ageMonth: correctedAge))
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(Theme.pediatricianReassurance)
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary.opacity(0.7))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                        .fill(theme.yellow.opacity(theme.isNightMode ? 0.06 : 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                        .stroke(theme.yellow.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }
    
    // =========================================================================
    // MARK: - Milestone Category Groups (5 Domains)
    // =========================================================================
    
    private var milestoneCategoryGroups: some View {
        VStack(spacing: 12) {
            ForEach(MilestoneCategory.allCases, id: \.self) { category in
                categoryGroup(category)
            }
        }
    }
    
    private func categoryGroup(_ category: MilestoneCategory) -> some View {
        let categoryMilestones = currentMonthMilestones.filter { $0.category == category.rawValue }
        // For expanding, show past/future only if current isn't empty, or just show standard logic.
        // Simplified to focus on current month logic first.
        let pastCategoryMilestones = pastMilestones.filter { $0.category == category.rawValue }
        let futureCategoryMilestones = futureMilestones.filter { $0.category == category.rawValue }
        
        let completedCount = categoryMilestones.filter(\.isCompleted).count
        let isExpanded = expandedCategories.contains(category.rawValue)
        
        return VStack(spacing: 0) {
            // Category header
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if isExpanded {
                        expandedCategories.remove(category.rawValue)
                    } else {
                        expandedCategories.insert(category.rawValue)
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
                        
                        Text("\(completedCount) of \(categoryMilestones.count) this month")
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
            
            // Expanded content — stable VStack with smooth collapse
            if isExpanded {
                VStack(spacing: 8) {
                    if categoryMilestones.isEmpty && pastCategoryMilestones.isEmpty && futureCategoryMilestones.isEmpty {
                        Text("No milestones for this stage yet.")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                            .padding(.bottom, 12)
                    } else {
                        ForEach(categoryMilestones) { milestone in
                            milestoneRow(milestone: milestone, opacity: 1.0)
                        }
                        
                        // Show next closest milestones if current empty?
                        // Or just standard past/future logic
                        if !pastCategoryMilestones.isEmpty {
                            ForEach(pastCategoryMilestones) { milestone in
                                milestoneRow(milestone: milestone, opacity: 0.5)
                            }
                        }
                        
                        if !futureCategoryMilestones.isEmpty {
                            ForEach(futureCategoryMilestones) { milestone in
                                milestoneRow(milestone: milestone, opacity: 0.35)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .warmCard(nightMode: theme.isNightMode)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
    
    // MARK: - Individual Milestone Row
    
    private func milestoneRow(milestone: Milestone, opacity: Double) -> some View {
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
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    milestone.isCompleted
                        ? theme.green.opacity(theme.isNightMode ? 0.06 : 0.04)
                        : theme.text.opacity(0.02)
                )
        )
        .opacity(opacity)
    }
    
    // =========================================================================
    // MARK: - Support Assistant
    // =========================================================================
    
    private var supportAssistant: some View {
        SupportAssistantView(
            milestones: milestones,
            correctedAge: correctedAge,
            nightMode: theme.isNightMode
        )
    }
    
    // =========================================================================
    // MARK: - Actions
    // =========================================================================
    
    private func toggleMilestone(_ milestone: Milestone) {
        milestone.isCompleted.toggle()
        
        if milestone.isCompleted {
            milestone.dateCompleted = Date()
            showCelebration()
        } else {
            milestone.dateCompleted = nil
            dismissCelebration()
        }
        
        try? modelContext.save()
    }
    
    /// Gentle fade+slide celebration: opacity 0→1, offset 12→0
    private func showCelebration() {
        celebrationText = Theme.randomCelebration()
        celebrationOpacity = 0
        celebrationOffset = 12
        
        // Fade in gently
        withAnimation(.easeInOut(duration: 0.4)) {
            celebrationOpacity = 1
            celebrationOffset = 0
        }
        
        // Hold for 2.5s then fade out gradually
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                celebrationOpacity = 0
                celebrationOffset = 6
            }
            // Clear text after fade completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                celebrationText = nil
            }
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeInOut(duration: 0.3)) {
            celebrationOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            celebrationText = nil
        }
    }
}

// MARK: - Preview

#Preview {
    let container: ModelContainer = {
        let container = try! ModelContainer(
            for: Milestone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        
        let samples: [(String, String, Int, Bool)] = [
            ("Sits with support", "Gross Motor", 6, true),
            ("Rolls over in both directions", "Gross Motor", 6, false),
            ("Rakes small objects toward self", "Fine Motor", 6, true),
            ("Babbles chains of consonants", "Language", 6, false),
            ("Explores objects by mouthing", "Cognitive", 6, true),
            ("Recognizes familiar faces", "Social-Emotional", 6, false),
        ]
        for (title, category, age, done) in samples {
            let m = Milestone(
                title: title,
                category: category,
                ageMonth: age,
                isCompleted: done,
                dateCompleted: done ? Date() : nil,
                tips: "Every little moment matters."
            )
            context.insert(m)
        }
        
        return container
    }()
    
    DashboardView()
        .environment(ChildProfile())
        .environment(ThemeManager())
        .modelContainer(container)
}
