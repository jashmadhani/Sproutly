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
        case dashboard = "Home"
        case milestones = "Milestones"
        case assistant = "Assistant"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .dashboard: return "leaf.circle"
            case .milestones: return "list.bullet.circle"
            case .assistant: return "bubble.left.and.bubble.right"
            case .settings: return "gearshape"
            }
        }

        var selectedIcon: String {
            switch self {
            case .dashboard: return "leaf.circle.fill"
            case .milestones: return "list.bullet.circle.fill"
            case .assistant: return "bubble.left.and.bubble.right.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .dashboard:
                DashboardView()
            case .milestones:
                MilestonesView()
            case .assistant:
                AssistantView()
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
#if os(iOS)
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
#endif
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
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular, design: .rounded))
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
        .padding(.horizontal, 16)
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
        .padding(.horizontal, 24)
        .padding(.bottom, 4)
    }
}

#Preview {
    let profile = ChildProfile()
    profile.birthDate = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    profile.name = "Preview"
    profile.hasCompletedOnboarding = true

    return MainTabView()
        .environment(profile)
        .environment(ThemeManager())
        .modelContainer(previewContainer)
}
