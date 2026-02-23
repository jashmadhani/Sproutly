//
//  MainTabView.swift
//  Sproutly
//
//  Created by Jash Madhani on 03/02/26.
//

import SwiftUI
import SwiftData

/// Main tab navigation with a floating warm dock.
/// Uses .safeAreaInset(edge: .bottom) so content never hides behind the dock.
struct MainTabView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case reflect = "Reflect"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .dashboard: return "leaf.circle"
            case .reflect: return "heart.text.square"
            case .settings: return "gearshape"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .dashboard: return "leaf.circle.fill"
            case .reflect: return "heart.text.square.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        Group {
            switch selectedTab {
            case .dashboard:
                DashboardView()
            case .reflect:
                ReflectView()
            case .settings:
                SettingsView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            floatingDock
        }
    }
    
    // MARK: - Floating Dock
    
    private var floatingDock: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 20))
                            .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.25), value: selectedTab)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .regular, design: .rounded))
                    }
                    .foregroundStyle(
                        selectedTab == tab
                            ? theme.blue
                            : theme.textSecondary
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    theme.isNightMode
                        ? Theme.nightCard.opacity(0.95)
                        : .white.opacity(0.95)
                )
                .shadow(
                    color: theme.isNightMode
                        ? Color.black.opacity(0.4)
                        : Theme.dayText.opacity(0.1),
                    radius: 20,
                    x: 0,
                    y: 8
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            theme.isNightMode
                                ? Color.white.opacity(0.06)
                                : Theme.dayText.opacity(0.05),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal, 40)
        .padding(.bottom, 4)
    }
}

// MARK: - Reflect View

/// Warm, growth-focused view: domain progress, recent milestones,
/// education sections, and growth tips.
struct ReflectView: View {
    @Query(sort: \Milestone.ageMonth) private var milestones: [Milestone]
    @Environment(ChildProfile.self) private var childProfile
    @Environment(ThemeManager.self) private var theme
    
    @State private var scrollOffset: CGFloat = 0
    
    private var isCompactHeader: Bool { scrollOffset < -10 }
    
    private var completedMilestones: [Milestone] {
        milestones.filter(\.isCompleted).sorted {
            ($0.dateCompleted ?? .distantPast) > ($1.dateCompleted ?? .distantPast)
        }
    }
    
    private func categoryStats(_ category: MilestoneCategory) -> (completed: Int, total: Int) {
        let categoryMilestones = milestones.filter { $0.category == category.rawValue }
        return (categoryMilestones.filter(\.isCompleted).count, categoryMilestones.count)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            AmbientBackground(nightMode: theme.isNightMode)
            
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    categoryOverview
                    recentMilestonesSection
                    educationSection
                    growthTipCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 54)
                .padding(.bottom, 16)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("reflectScroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "reflectScroll")
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
            
            // Compact header
            VStack {
                HStack {
                    Text("Reflect")
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
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reflect")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(theme.text)
            
            Text("Looking back on the beautiful moments")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
    
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
                                    .frame(width: geo.size.width * progress, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    
                    Text("\(stats.completed)/\(stats.total)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .warmCard(nightMode: theme.isNightMode)
    }
    
    private var recentMilestonesSection: some View {
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
                                Text(date, style: .relative)
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
    
    // MARK: - Education
    
    private var educationSection: some View {
        EducationView(nightMode: theme.isNightMode)
    }
    
    // MARK: - Growth Tip
    
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

#Preview {
    MainTabView()
        .environment(ChildProfile())
        .environment(ThemeManager())
}
