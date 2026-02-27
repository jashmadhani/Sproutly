//
//  MilestoneRingView.swift
//  Sproutly
//
//  Created by Jash Madhani on 03/02/26.
//

import SwiftUI

/// Calm progress ring with blue-to-green gradient.
/// Shows current month's milestone progress without gamification.
struct MilestoneRingView: View {
    var progress: Double
    var completedCount: Int
    var totalCount: Int
    var nightMode: Bool = false

    @State private var animatedProgress: Double = 0

    private var ringBlue: Color { Theme.accentBlue(for: nightMode) }
    private var ringGreen: Color { Theme.growthGreen(for: nightMode) }

    var body: some View {
        ZStack {
            // Background track — stronger contrast
            Circle()
                .stroke(
                    ringBlue.opacity(nightMode ? 0.15 : 0.18),
                    lineWidth: 12
                )

            // Progress arc — rich 3-stop gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            ringBlue,
                            Color(red: 0.2, green: 0.7, blue: 0.75), // teal midpoint
                            ringGreen
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: ringBlue.opacity(0.2),
                    radius: 6,
                    x: 0,
                    y: 0
                )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.25)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: 0xFAF8F4).ignoresSafeArea()
        MilestoneRingView(progress: 0.65, completedCount: 4, totalCount: 6)
    }
}
