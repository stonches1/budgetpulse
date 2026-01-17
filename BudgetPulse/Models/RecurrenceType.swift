//
//  RecurrenceType.swift
//  BudgetPulse
//

import Foundation

enum RecurrenceType: String, Codable, CaseIterable, Identifiable {
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case yearly = "yearly"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .weekly:
            return L("recurrence_weekly")
        case .biweekly:
            return L("recurrence_biweekly")
        case .monthly:
            return L("recurrence_monthly")
        case .yearly:
            return L("recurrence_yearly")
        }
    }

    var icon: String {
        switch self {
        case .weekly:
            return "calendar.badge.clock"
        case .biweekly:
            return "calendar"
        case .monthly:
            return "calendar.circle"
        case .yearly:
            return "calendar.badge.exclamationmark"
        }
    }

    func nextDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }

    var monthlyMultiplier: Double {
        switch self {
        case .weekly:
            return 4.33 // Average weeks per month
        case .biweekly:
            return 2.17
        case .monthly:
            return 1.0
        case .yearly:
            return 1.0 / 12.0
        }
    }
}
