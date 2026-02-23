//
//  MyApp.swift
//  Sproutly
//
//  Created by Jash Madhani on 03/02/26.
//

import SwiftUI
import SwiftData

/// Synchronously initialized and seeded app container.
/// Fixes the iOS 17 SwiftData bug where programmatic data seeding triggers after @Query evaluates,
/// preventing the UI from rendering "0 of 0" on the first launch.
@MainActor
let sharedAppContainer: ModelContainer = {
    do {
        let schema = Schema([Milestone.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [config])
        DataSeeder.seedIfNeeded(modelContext: container.mainContext)
        return container
    } catch {
        fatalError("Failed to build app container: \(error)")
    }
}()

@main
struct MyApp: App {
    @State private var childProfile = ChildProfile.load()
    @State private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(childProfile)
                .environment(themeManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
        .modelContainer(sharedAppContainer)
    }
}

/// Root view that routes between Onboarding and the Main Tab View.
struct ContentView: View {
    @Environment(ChildProfile.self) private var childProfile
    @Environment(ThemeManager.self) private var theme
    
    var body: some View {
        Group {
            if !childProfile.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: childProfile.hasCompletedOnboarding)
    }
}
