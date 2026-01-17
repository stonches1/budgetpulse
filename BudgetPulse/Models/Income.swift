//
//  Income.swift
//  BudgetPulse
//

import Foundation

struct Income: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var amount: Double
    var date: Date
    var isRecurring: Bool
    var recurrenceType: RecurrenceType?
    var notes: String?

    init(id: UUID = UUID(), title: String, amount: Double, date: Date = Date(), isRecurring: Bool = false, recurrenceType: RecurrenceType? = nil, notes: String? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.isRecurring = isRecurring
        self.recurrenceType = recurrenceType
        self.notes = notes
    }
}

enum IncomeCategory: String, Codable, CaseIterable, Identifiable {
    case salary = "salary"
    case freelance = "freelance"
    case investment = "investment"
    case gift = "gift"
    case refund = "refund"
    case other = "other"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .salary:
            return L("income_salary")
        case .freelance:
            return L("income_freelance")
        case .investment:
            return L("income_investment")
        case .gift:
            return L("income_gift")
        case .refund:
            return L("income_refund")
        case .other:
            return L("income_other")
        }
    }

    var icon: String {
        switch self {
        case .salary: return "briefcase.fill"
        case .freelance: return "laptopcomputer"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .gift: return "gift.fill"
        case .refund: return "arrow.uturn.backward.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .salary: return "green"
        case .freelance: return "blue"
        case .investment: return "purple"
        case .gift: return "pink"
        case .refund: return "orange"
        case .other: return "gray"
        }
    }
}
