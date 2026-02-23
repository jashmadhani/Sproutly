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
    
    var body: some View {
        ZStack {
            // Background ring — soft tint
            Circle()
                .stroke(
                    Theme.accentBlue(for: nightMode).opacity(0.12),
                    lineWidth: 10
                )
            
            // Progress arc — blue to green gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Theme.accentBlue(for: nightMode),
                            Theme.growthGreen(for: nightMode)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: Theme.accentBlue(for: nightMode).opacity(0.15),
                    radius: 4
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.4)) {
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
