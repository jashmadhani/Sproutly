//
//  GlassCardView.swift
//  Sproutly
//
//  Created by Jash Madhani on 03/02/26.
//

import SwiftUI

/// Soft card with warm styling that adapts to night mode.
struct GlassCardView<Content: View>: View {
    var nightMode: Bool = false
    var content: Content
    
    init(nightMode: Bool = false, @ViewBuilder content: () -> Content) {
        self.nightMode = nightMode
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(Theme.cardBackground(for: nightMode))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(
                color: nightMode
                    ? Color.black.opacity(0.3)
                    : Theme.dayText.opacity(0.06),
                radius: nightMode ? 6 : 10,
                x: 0,
                y: nightMode ? 3 : 5
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        nightMode
                            ? Color.white.opacity(0.06)
                            : Theme.dayText.opacity(0.04),
                        lineWidth: 1
                    )
            )
    }
}

#Preview {
    ZStack {
        Color(hex: 0xFAF8F4).ignoresSafeArea()
        
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "figure.walk")
                    .font(.title)
                    .foregroundStyle(Color(hex: 0x6FAED9))
                Text("Sample Milestone")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color(hex: 0x2F3A3F))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}
