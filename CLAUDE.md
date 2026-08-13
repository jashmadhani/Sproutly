# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`Sproutly.swiftpm` — a Swift Playgrounds app package (`.iOSApplication` product via `AppleProductTypes`) for an offline child-development milestone tracker. iOS 17+, iPhone-only, portrait-only, Swift 6 strict concurrency, SwiftUI + SwiftData. No network calls anywhere in the app; everything (including the "Assistant") runs locally.

A separate, non-public XcodeGen repo at `~/Projects/Sproutly-App` holds the App Store build (same bundle id `com.jashmadhani.Sproutly`). That is one single app, shipped free, with "Sproutly Pro" as a $9.99 one-time non-consumable unlock inside it — not a second, pre-unlocked build. `PurchaseManager.isPro` is set only from verified StoreKit entitlements and there is no debug override; gates cover the second child, milestone photos, custom milestones, share cards, and the PDF report. This repo is the earlier Playgrounds-package lineage and has none of that; features added there do not flow back here.

## Building and testing

There is **no working command-line build**: `xcodebuild` requires full Xcode and the machine's active developer dir is CommandLineTools, and `swift build`/`swift test` can't resolve `AppleProductTypes`. Do not try to verify changes by compiling from the shell.

- Open `Sproutly.swiftpm` in Xcode 16+ (or Swift Playgrounds) and run on an iOS 17+ simulator.
- Tests live in `Tests/SproutlyTests.swift` (XCTest, `@testable import AppModule`) and run via ⌘U in Xcode; a single test runs from the diamond gutter icon.
- After making a change, ask the user to build/run in Xcode to verify — you cannot.

## Architecture

**Two persistence stores, deliberately split.**
- `Milestone` is the only SwiftData `@Model`. Views read it directly with `@Query(sort: \Milestone.ageMonth)` (Dashboard, Milestones, Assistant) — there is no repository layer.
- `ChildProfile` is a plain `@Observable` class persisted as a dictionary in `UserDefaults` under `sproutly_profile` (with a legacy `elitegrowth_profile` fallback read in `load()`/`reset()`). It is injected via `.environment(childProfile)`, not SwiftData.

**Container + seeding.** `MyApp.swift` builds `sharedAppContainer` at file scope (`@MainActor`) so `DataSeeder.seedIfNeeded` runs *before* first render and `@Query` isn't empty on launch; `ContentView.task` seeds again as a safety net. `seedIfNeeded` uses a count threshold (`< 80` milestones ⇒ wipe and reseed all) rather than a version flag — so adding milestones to `DataSeeder` means bumping that threshold, otherwise existing installs never pick them up, and reseeding **destroys user completion state**. Schema versioning is `SproutlySchemaV1` + `SproutlyMigrationPlan` (no stages yet); any `Milestone` field change needs a V2 schema and a migration stage.

**Corrected age is the app's central concept.** `ChildProfile.calculateCorrectedAge()` subtracts `(40 - gestationalWeeks) / 4.33` months for premature children. Almost all milestone logic keys off corrected age, not chronological age — `humanReadableAge` (chronological, for greetings) and `ageText` (corrected) are intentionally different.

**Domain scoring.** `Managers/DevelopmentObserver.swift` is the pure, testable core: given milestones + corrected age it produces per-domain completion ratios and a `DomainStatus` (`onTrack` ≥0.75, `emerging` ≥0.50, `needsSupport` ≥0.30, else `worthDiscussing`). Only milestones at or below corrected age count. Language carries a 1.2× sensitivity weight. `DashboardViewModel.update(milestones:childProfile:)` is a manual recompute guarded by a hash signature of the milestone list + corrected age — it is not reactive, so any code path that mutates milestones must let that `update` run again.

**Assistant is rule-based, not an LLM.** `Views/SupportAssistantView.swift` contains `WeightedDomainScorer` (a keyword→category→weight table, with negative-context words bumping weight) and one hand-written response function per `MilestoneCategory`. Adding coverage means extending the keyword table and the corresponding response function — never introduce a network call here.

**Theming.** `Theme.swift` exposes only `static func x(for nightMode: Bool) -> Color` — there are no adaptive asset colors. `ThemeManager` (`@Observable`, persisted to `UserDefaults` key `nightModeEnabled`) resolves those into properties and drives `.preferredColorScheme`. Views take `@Environment(ThemeManager.self)` and use `theme.card`, `.warmCard(nightMode:)`, `AmbientBackground`, etc. Never hardcode a `Color` in a view; add a token to `Theme.swift` and surface it on `ThemeManager`.

**Category strings.** `Milestone.category` is a `String` (SwiftData-friendly) bridged through `categoryType: MilestoneCategory`. Seeded values must exactly match the `MilestoneCategory` raw values (`"Gross Motor"`, `"Fine Motor"`, `"Language"`, `"Cognitive"`, `"Social-Emotional"`) — a typo silently falls back to `.grossMotor`.

## Product constraints

- App Store category is **Lifestyle**, not Health & Fitness — copy must stay educational and never diagnose. Onboarding step 4 is a required medical disclaimer.
- Tone is a hard requirement: reassuring, non-alarming ("Growth unfolds at its own pace"), never scorecard language. `PRIVACY_POLICY.md` claims no data leaves the device; keep that true.
- `README.md` documents every screen and the design tokens in detail — update it when screens or the palette change.
