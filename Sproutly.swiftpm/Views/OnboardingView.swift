//
//  OnboardingView.swift
//  Sproutly
//
//  Created by Jash Madhani on 03/02/26.
//

import SwiftUI
import SwiftData

// ─────────────────────────────────────────────────────────────────────────────
// ROOT CAUSE ANALYSIS & FIXES
// ─────────────────────────────────────────────────────────────────────────────
//
// RC-1  Ghost hit-testing from ZStack-opacity pattern
//       .allowsHitTesting(false) does NOT remove views from the responder
//       chain for keyboard / focus purposes. All four ScrollViews + the
//       TextField coexist, causing SwiftUI's hit-test traversal to compete.
//   ▸ FIX: Conditional `if step == N` rendering — only the active step
//       exists in the view hierarchy at any time.
//
// RC-2  ScrollView gesture stealing first tap
//       The TextField lives inside a ScrollView. On the first tap, the
//       scroll gesture recognizer captures the touch for scroll-detection,
//       then yields to the text field only on the second attempt.
//   ▸ FIX: @FocusState + explicit .focused() binding so focus is
//       programmatic and not dependent on the gesture chain resolving.
//
// RC-3  Unguarded step mutation under rapid tapping
//       step += 1 / step -= 1 without clamping can push step out of
//       bounds under rapid tapping, especially when body re-evaluates
//       mid-gesture.
//   ▸ FIX: Clamp all step mutations to 0...(totalSteps - 1).
//
// RC-4  asyncAfter race on "Begin Your Journey" button
//       DispatchQueue.main.asyncAfter allows double-firing if the user
//       taps the button twice within the 200ms delay.
//   ▸ FIX: @State isProcessing guard + synchronous completeOnboarding().
// ─────────────────────────────────────────────────────────────────────────────

/// Emotionally supportive onboarding flow — under 60 seconds.
/// Four gentle screens: Welcome, How It Works, Reassurance, Profile Setup.
struct OnboardingView: View {
    @Environment(ChildProfile.self) private var childProfile
    @Environment(ThemeManager.self) private var theme

    // ── Step state ──
    @State private var step = 0
    @State private var isProcessing = false       // RC-4: double-tap guard

    // ── Profile fields ──
    @State private var childName = ""
    @State private var birthDate = Calendar.current.date(byAdding: .month, value: -4, to: Date()) ?? Date()
    @State private var isPremature = false
    @State private var gestationalWeeks = 40

    // ── Focus ──
    @FocusState private var isNameFieldFocused: Bool  // RC-2: explicit focus

    private let totalSteps = 4

    var body: some View {
        ZStack {
            // Warm background — lightweight, no blur
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                progressDots

                // RC-1 FIX: Only the active step is in the hierarchy.
                // No ghost hit areas, no competing gesture recognizers.
                Group {
                    if step == 0 {
                        welcomeStep
                    } else if step == 1 {
                        howItWorksStep
                    } else if step == 2 {
                        reassuranceStep
                    } else {
                        profileStep
                    }
                }
                .transition(.identity) // no animated transition

                navigationButtons
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside the text field
            isNameFieldFocused = false
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

                        // RC-2 FIX: .focused() binding ensures first-tap activation.
                        TextField("Enter name", text: $childName)
                            .focused($isNameFieldFocused)
                            .textFieldStyle(.plain)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.text.opacity(0.05))
                            )
                            .foregroundStyle(theme.text)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .onTapGesture {
                                isNameFieldFocused = true
                            }
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

    // RC-3 FIX: All step mutations clamped to valid range.
    func goBack() {
        isNameFieldFocused = false
        step = max(0, step - 1)
    }

    func goForward() {
        isNameFieldFocused = false
        step = min(totalSteps - 1, step + 1)
    }

    var navigationButtons: some View {
        HStack(spacing: 16) {
            if step > 0 {
                Button {
#if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
                    goBack()
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
                // RC-4 FIX: Guard against double-fire.
                guard !isProcessing else { return }

#if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif

                if step == totalSteps - 1 {
                    // Final step — synchronous completion, no asyncAfter race.
                    isProcessing = true
                    completeOnboarding()
                } else {
                    goForward()
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
            .disabled((step == totalSteps - 1 && childName.isEmpty) || isProcessing)
            .opacity((step == totalSteps - 1 && childName.isEmpty) ? 0.5 : 1)
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
