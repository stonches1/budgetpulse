//
//  BudgetPulseApp.swift
//  BudgetPulse
//

import SwiftUI

@main
struct BudgetPulseApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var languageManager = LanguageManager.shared
    @State private var appearanceManager = AppearanceManager.shared

    init() {
        setupLanguageIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .id(languageManager.refreshID)
            .preferredColorScheme(appearanceManager.colorScheme)
        }
    }

    private func setupLanguageIfNeeded() {
        // Only apply language override if onboarding is complete and user chose a specific language
        let languageManager = LanguageManager.shared

        if hasCompletedOnboarding && languageManager.currentLanguage != .system {
            languageManager.applyLanguageOnLaunch()
            Bundle.setLanguage(languageManager.currentLanguage.rawValue)
        }
        // During onboarding, we use the system/phone language automatically
    }
}
