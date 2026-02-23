//
//  ThemeManager.swift
//  Sproutly
//
//  Created by Jash Madhani on 19/02/26.
//

import SwiftUI

/// Manages the Night Mode state for the entire app.
/// Uses @AppStorage for persistent storage so the preference
/// survives app restarts.
@Observable
final class ThemeManager {
    
    // MARK: - Night Mode State
    
    /// Whether Night Mode is currently active.
    /// Stored in UserDefaults via @AppStorage pattern.
    var isNightMode: Bool {
        didSet {
            UserDefaults.standard.set(isNightMode, forKey: "nightModeEnabled")
        }
    }
    
    init() {
        self.isNightMode = UserDefaults.standard.bool(forKey: "nightModeEnabled")
    }
    
    // MARK: - Resolved Colors
    
    var background: Color { Theme.background(for: isNightMode) }
    var card: Color { Theme.cardBackground(for: isNightMode) }
    var text: Color { Theme.textPrimary(for: isNightMode) }
    var textSecondary: Color { Theme.textSecondary(for: isNightMode) }
    var blue: Color { Theme.accentBlue(for: isNightMode) }
    var green: Color { Theme.growthGreen(for: isNightMode) }
    var yellow: Color { Theme.encourageYellow(for: isNightMode) }
    
    // Domain colors (5 NCBI-aligned)
    var grossMotorColor: Color { Theme.grossMotorColor(for: isNightMode) }
    var fineMotorColor: Color { Theme.fineMotorColor(for: isNightMode) }
    var languageColor: Color { Theme.languageColor(for: isNightMode) }
    var cognitiveColor: Color { Theme.cognitiveColor(for: isNightMode) }
    var socialEmotionalColor: Color { Theme.socialEmotionalColor(for: isNightMode) }
    
    // MARK: - Color Scheme Override
    
    /// Returns the preferred color scheme to override system appearance.
    var preferredColorScheme: ColorScheme? {
        isNightMode ? .dark : .light
    }
}
