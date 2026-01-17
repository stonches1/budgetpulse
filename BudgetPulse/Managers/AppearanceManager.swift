//
//  AppearanceManager.swift
//  BudgetPulse
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .system: return L("appearance_system")
        case .light: return L("appearance_light")
        case .dark: return L("appearance_dark")
        }
    }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
@Observable
final class AppearanceManager {
    static let shared = AppearanceManager()

    private let appearanceKey = "appAppearance"

    var currentAppearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(currentAppearance.rawValue, forKey: appearanceKey)
        }
    }

    var colorScheme: ColorScheme? {
        currentAppearance.colorScheme
    }

    private init() {
        if let savedAppearance = UserDefaults.standard.string(forKey: appearanceKey),
           let appearance = AppAppearance(rawValue: savedAppearance) {
            self.currentAppearance = appearance
        } else {
            self.currentAppearance = .system
        }
    }

    func setAppearance(_ appearance: AppAppearance) {
        currentAppearance = appearance
    }
}
