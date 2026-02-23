//
//  OneTapLogButton.swift
//  Sproutly
//
//  Created by Jash Madhani on 03/02/26.
//

import SwiftUI

/// Gentle one-tap button to mark milestones complete.
/// Uses soft scale animation and haptic feedback.
struct OneTapLogButton: View {
    var isCompleted: Bool
    var nightMode: Bool = false
    var action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
#if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
#endif
            
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3)) {
                    isPressed = false
                }
            }
        } label: {
            ZStack {
                // Filled circle
                Circle()
                    .fill(
                        isCompleted
                            ? Theme.growthGreen(for: nightMode)
                            : Theme.accentBlue(for: nightMode).opacity(0.12)
                    )
                    .frame(width: 36, height: 36)
                    .shadow(
                        color: isCompleted
                            ? Theme.growthGreen(for: nightMode).opacity(0.25)
                            : .clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                
                // Outer ring when not completed
                if !isCompleted {
                    Circle()
                        .stroke(
                            Theme.accentBlue(for: nightMode).opacity(0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 36, height: 36)
                }
                
                // Icon
                Image(systemName: isCompleted ? "checkmark" : "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        isCompleted
                            ? .white
                            : Theme.accentBlue(for: nightMode)
                    )
            }
            .scaleEffect(isPressed ? 0.88 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color(hex: 0xFAF8F4).ignoresSafeArea()
        
        HStack(spacing: 30) {
            OneTapLogButton(isCompleted: false, action: {})
            OneTapLogButton(isCompleted: true, action: {})
        }
    }
}
