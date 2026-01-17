//
//  LanguageManager.swift
//  BudgetPulse
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case french = "fr"
    case spanish = "es"
    case portuguese = "pt"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return L("language_system")
        case .english:
            return L("language_english")
        case .french:
            return L("language_french")
        case .spanish:
            return L("language_spanish")
        case .portuguese:
            return L("language_portuguese")
        }
    }

    var nativeName: String {
        switch self {
        case .system:
            return L("language_system")
        case .english:
            return "English"
        case .french:
            return "Français"
        case .spanish:
            return "Español"
        case .portuguese:
            return "Português"
        }
    }
}

@MainActor
@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    private let userDefaultsKey = "AppLanguageOverride"

    var currentLanguage: AppLanguage {
        didSet {
            saveLanguagePreference()
        }
    }

    var showRestartAlert = false
    var refreshID = UUID()
    private var previousLanguage: AppLanguage?

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }
        applyLanguageOnLaunch()
    }

    private func saveLanguagePreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: userDefaultsKey)
    }

    func changeLanguage(to language: AppLanguage) {
        if language != currentLanguage {
            previousLanguage = currentLanguage
            currentLanguage = language
            applyLanguageImmediately(language)
        }
    }

    func applyLanguageImmediately(_ language: AppLanguage) {
        if language != .system {
            Bundle.setLanguage(language.rawValue)
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        } else {
            Bundle.setLanguage(nil)
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()

        // Trigger UI refresh
        refreshID = UUID()
    }

    func applyLanguageOnLaunch() {
        guard currentLanguage != .system else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            Bundle.setLanguage(nil)
            return
        }

        UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        Bundle.setLanguage(currentLanguage.rawValue)
    }

    var effectiveLocale: Locale {
        switch currentLanguage {
        case .system:
            return Locale.current
        case .english:
            return Locale(identifier: "en")
        case .french:
            return Locale(identifier: "fr")
        case .spanish:
            return Locale(identifier: "es")
        case .portuguese:
            return Locale(identifier: "pt")
        }
    }

    var effectiveLanguageCode: String {
        switch currentLanguage {
        case .system:
            return Locale.current.language.languageCode?.identifier ?? "en"
        case .english:
            return "en"
        case .french:
            return "fr"
        case .spanish:
            return "es"
        case .portuguese:
            return "pt"
        }
    }
}

extension Bundle {
    private static var bundleKey: UInt8 = 0

    static func setLanguage(_ language: String?) {
        defer {
            object_setClass(Bundle.main, BundleEx.self)
        }

        guard let language = language else {
            objc_setAssociatedObject(Bundle.main, &bundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }

        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return
        }

        objc_setAssociatedObject(Bundle.main, &bundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    static var localizedBundle: Bundle? {
        objc_getAssociatedObject(Bundle.main, &bundleKey) as? Bundle
    }
}

private class BundleEx: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = Bundle.localizedBundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

// Helper function for dynamic localization that bypasses String(localized:) caching
func L(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: nil, table: nil)
}

// Helper function for plural localization with a count
func LPlural(_ key: String, count: Int) -> String {
    String.localizedStringWithFormat(
        Bundle.main.localizedString(forKey: key, value: nil, table: nil),
        count
    )
}
