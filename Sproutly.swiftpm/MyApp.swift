//
//  MyApp.swift
//  Sproutly
//
//  Created by Jash Madhani on 03/02/26.
//

import SwiftUI
import SwiftData

// MARK: - Shared Container
//
// SEEDING STRATEGY
// Initialize the container and seed data directly into the `mainContext`.
// Because this happens synchronously before any SwiftUI view reads from `@Query`,
// the data is immediately present in the main context on the very first render,
// avoiding the need for complex save notification workarounds.

@MainActor
let sharedAppContainer: ModelContainer = {
    do {
        let schema = Schema([Milestone.self])
        let config = ModelConfiguration("SproutlyDB", isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [config])

        DataSeeder.seedIfNeeded(modelContext: container.mainContext)

        return container
    } catch {
        fatalError("Failed to build app container: \(error)")
    }
}()

// MARK: - App Entry Point

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

// MARK: - Root View

struct ContentView: View {
    @Environment(ChildProfile.self) private var childProfile
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    
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
        .task {
            // Seed directly into the environment's context so all @Query
            // properties instances immediately see the new data without needing remote notifications.
            DataSeeder.seedIfNeeded(modelContext: modelContext)
        }
    }
}
