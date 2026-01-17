//
//  Budget.swift
//  BudgetPulse
//

import Foundation

struct Budget: Codable, Equatable {
    var monthlyLimit: Double
    var currency: CurrencyCode
    var categoryBudgets: [String: Double]
    var rolloverEnabled: Bool
    var rolloverAmount: Double
    var lastRolloverMonth: String?

    init(monthlyLimit: Double = 1000.0, currency: CurrencyCode = .usd, categoryBudgets: [String: Double] = [:], rolloverEnabled: Bool = false, rolloverAmount: Double = 0, lastRolloverMonth: String? = nil) {
        self.monthlyLimit = monthlyLimit
        self.currency = currency
        self.categoryBudgets = categoryBudgets
        self.rolloverEnabled = rolloverEnabled
        self.rolloverAmount = rolloverAmount
        self.lastRolloverMonth = lastRolloverMonth
    }

    /// Effective monthly limit including any rollover
    var effectiveMonthlyLimit: Double {
        rolloverEnabled ? monthlyLimit + rolloverAmount : monthlyLimit
    }

    func budgetLimit(for category: ExpenseCategory) -> Double? {
        categoryBudgets[category.rawValue]
    }

    mutating func setBudgetLimit(_ limit: Double?, for category: ExpenseCategory) {
        if let limit = limit {
            categoryBudgets[category.rawValue] = limit
        } else {
            categoryBudgets.removeValue(forKey: category.rawValue)
        }
    }
}

enum CurrencyCode: String, Codable, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case cad = "CAD"
    case mxn = "MXN"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .cad: return "CA$"
        case .mxn: return "MX$"
        }
    }

    var localizedName: String {
        switch self {
        case .usd:
            return L("currency_usd")
        case .eur:
            return L("currency_eur")
        case .gbp:
            return L("currency_gbp")
        case .cad:
            return L("currency_cad")
        case .mxn:
            return L("currency_mxn")
        }
    }

    var locale: Locale {
        switch self {
        case .usd: return Locale(identifier: "en_US")
        case .eur: return Locale(identifier: "fr_FR")
        case .gbp: return Locale(identifier: "en_GB")
        case .cad: return Locale(identifier: "en_CA")
        case .mxn: return Locale(identifier: "es_MX")
        }
    }
}
