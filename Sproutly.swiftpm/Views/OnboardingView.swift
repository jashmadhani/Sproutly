//
//  OnboardingView.swift
//  Sproutly
//
//  Created by Jash Madhani on 03/02/26.
//

import SwiftUI
import SwiftData

/// Emotionally supportive onboarding flow — under 60 seconds.
/// Four gentle screens: Welcome, How It Works, Reassurance, Profile Setup.
struct OnboardingView: View {
    @Environment(ChildProfile.self) private var childProfile
    @Environment(ThemeManager.self) private var theme
    
    @State private var step = 0
    @State private var childName = ""
    @State private var birthDate = Calendar.current.date(byAdding: .month, value: -4, to: Date()) ?? Date()
    @State private var isPremature = false
    @State private var gestationalWeeks = 40
    @State private var getStartedPressed = false
    
    private let totalSteps = 4
    
    var body: some View {
        ZStack {
            // Static warm background — no blur, no drawingGroup
            theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                progressDots
                
                // Use ZStack with opacity instead of .id() so
                // the profile step (and its TextField) is NEVER
                // destroyed / recreated mid-interaction.
                ZStack {
                    welcomeStep
                        .opacity(step == 0 ? 1 : 0)
                        .allowsHitTesting(step == 0)
                    howItWorksStep
                        .opacity(step == 1 ? 1 : 0)
                        .allowsHitTesting(step == 1)
                    reassuranceStep
                        .opacity(step == 2 ? 1 : 0)
                        .allowsHitTesting(step == 2)
                    profileStep
                        .opacity(step == 3 ? 1 : 0)
                        .allowsHitTesting(step == 3)
                }
                
                navigationButtons
            }
        }
    }
}

// MARK: - Progress Dots

private extension OnboardingView {
    var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(
                        i <= step
                            ? theme.blue
                            : theme.blue.opacity(0.25)
                    )
                    .frame(width: i == step ? 24 : 8, height: 8)
            }
        }
        .padding(.top, 60)
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.2), value: step)
    }
}

// MARK: - Steps

private extension OnboardingView {
    
    // Step 1: Welcome — "Every small moment matters"
    var welcomeStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                ZStack {
                    Circle()
                        .fill(theme.blue.opacity(0.12))
                        .frame(width: 130, height: 130)

                    Circle()
                        .fill(theme.blue.opacity(0.08))
                        .frame(width: 110, height: 110)

                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(theme.blue)
                }

                Text("Sproutly")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text)

                VStack(spacing: 8) {
                    Text("Every small moment matters")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(theme.text)

                    Text("Sproutly helps you notice the quiet,\nbeautiful growth happening every day.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.textSecondary)
                        .lineSpacing(4)
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
    }
    
    // Step 2: How It Works — Observe → Log → Reflect
    var howItWorksStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 24)

                Text("How Sproutly Works")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(theme.text)

                VStack(spacing: 16) {
                    onboardingPill(
                        icon: "eye",
                        title: "Observe",
                        subtitle: "Notice the little things your child does each day"
                    )

                    onboardingPill(
                        icon: "square.and.pencil",
                        title: "Log",
                        subtitle: "Tap once to record a milestone — it takes a second"
                    )

                    onboardingPill(
                        icon: "heart.text.square",
                        title: "Reflect",
                        subtitle: "Look back on your journey with warmth"
                    )
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
    }
    
    // Step 3: Reassurance — "There is no perfect timeline"
    var reassuranceStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                ZStack {
                    Circle()
                        .fill(theme.green.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 55))
                        .foregroundStyle(theme.green)
                }

                Text("There is no\nperfect timeline")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.text)

                Text("Every child blooms in their own time.\nSproutly is here to support you,\nnot to score or compare.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.textSecondary)
                    .lineSpacing(4)

                Spacer(minLength: 40)
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
    }
    
    // Step 4: Quick Profile Setup
    var profileStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 16)

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(theme.yellow.opacity(0.25))
                            .frame(width: 60, height: 60)

                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(theme.blue)
                    }

                    Text("About Your Little One")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(theme.text)
                }

                VStack(alignment: .leading, spacing: 20) {
                    // ── Name Field ──
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Child's Name", systemImage: "heart.fill")
                            .font(.subheadline)
                            .foregroundStyle(theme.blue)

                        TextField("Enter name", text: $childName)
                            .textFieldStyle(.plain)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.text.opacity(0.05))
                            )
                            .foregroundStyle(theme.text)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }

                    // ── Birth Date ──
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Birth Date", systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(theme.blue)

                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(theme.blue)
                    }

                    // ── Premature Toggle ──
                    Toggle(isOn: $isPremature) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Born Before 37 Weeks")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(theme.text)
                            Text("We'll adjust milestones gently")
                                .font(.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                    .tint(theme.green)

                    if isPremature {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Gestational Age at Birth", systemImage: "calendar.badge.clock")
                                .font(.subheadline)
                                .foregroundStyle(theme.blue)

                            Picker("Weeks", selection: $gestationalWeeks) {
                                ForEach(24...36, id: \.self) { week in
                                    Text("\(week) weeks").tag(week)
                                }
                            }
#if os(iOS)
                            .pickerStyle(.wheel)
#endif
                            .frame(height: 100)
                        }
                    }
                }
                .padding(24)
                .warmCard(nightMode: theme.isNightMode)

                Spacer(minLength: 24)
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
#if os(iOS)
        .scrollDismissesKeyboard(.interactively)
#endif
    }
    
    // Helper: Onboarding pill row
    func onboardingPill(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.blue.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(theme.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(theme.text)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .warmCard(nightMode: theme.isNightMode)
    }
}

// MARK: - Navigation

private extension OnboardingView {
    var navigationButtons: some View {
        HStack(spacing: 16) {
            if step > 0 {
                Button {
#if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
                    step -= 1
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(theme.textSecondary)
                }
                .buttonStyle(SoftCapsuleStyle(baseColor: theme.blue, nightMode: theme.isNightMode))
            }
            
            Spacer()
            
            Button {
#if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
                
                if step == totalSteps - 1 {
                    getStartedPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        completeOnboarding()
                    }
                } else {
                    step += 1
                }
            } label: {
                HStack(spacing: 8) {
                    Text(step == totalSteps - 1 ? "Begin Your Journey" : "Continue")
                        .fontWeight(.semibold)
                    
                    Image(systemName: step == totalSteps - 1 ? "heart.fill" : "chevron.right")
                }
                .foregroundStyle(step == totalSteps - 1 ? .white : theme.text)
            }
            .buttonStyle(
                SoftCapsuleStyle(
                    baseColor: step == totalSteps - 1 ? theme.blue : theme.green,
                    isAction: step == totalSteps - 1,
                    nightMode: theme.isNightMode
                )
            )
            .scaleEffect(getStartedPressed ? 1.05 : 1.0)
            .disabled(step == 3 && childName.isEmpty)
            .opacity(step == 3 && childName.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    func completeOnboarding() {
        childProfile.name = childName
        childProfile.birthDate = birthDate
        childProfile.isPremature = isPremature
        childProfile.gestationalWeeks = isPremature ? gestationalWeeks : 40
        childProfile.hasCompletedOnboarding = true
        childProfile.save()
    }
}

#Preview {
    OnboardingView()
        .environment(ChildProfile())
        .environment(ThemeManager())
        .modelContainer(previewContainer)
}
