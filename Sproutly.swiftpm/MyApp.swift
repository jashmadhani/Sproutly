//
//  MyApp.swift
//  Sproutly
//
//  Created by Jash Madhani on 03/02/26.
//

import SwiftUI
import SwiftData

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
        .modelContainer(for: Milestone.self)
    }
}

/// Root view that routes between Onboarding and the Main Tab View.
/// No instructions view — onboarding covers everything in 4 screens.
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
                    .onAppear {
                        DataSeeder.loadSampleData(modelContext: modelContext)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: childProfile.hasCompletedOnboarding)
    }
}
