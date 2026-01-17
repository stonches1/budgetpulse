//
//  Expense.swift
//  BudgetPulse
//

import Foundation

struct Expense: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var notes: String?
    var isRecurring: Bool
    var recurrenceType: RecurrenceType?
    var nextDueDate: Date?
    var receiptImagePath: String?

    init(id: UUID = UUID(), title: String, amount: Double, category: ExpenseCategory, date: Date = Date(), notes: String? = nil, isRecurring: Bool = false, recurrenceType: RecurrenceType? = nil, nextDueDate: Date? = nil, receiptImagePath: String? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.isRecurring = isRecurring
        self.recurrenceType = recurrenceType
        self.nextDueDate = nextDueDate
        self.receiptImagePath = receiptImagePath
    }
}

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food = "food"
    case transportation = "transportation"
    case entertainment = "entertainment"
    case shopping = "shopping"
    case utilities = "utilities"
    case healthcare = "healthcare"
    case education = "education"
    case travel = "travel"
    case other = "other"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .food:
            return L("category_food")
        case .transportation:
            return L("category_transportation")
        case .entertainment:
            return L("category_entertainment")
        case .shopping:
            return L("category_shopping")
        case .utilities:
            return L("category_utilities")
        case .healthcare:
            return L("category_healthcare")
        case .education:
            return L("category_education")
        case .travel:
            return L("category_travel")
        case .other:
            return L("category_other")
        }
    }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .entertainment: return "tv.fill"
        case .shopping: return "bag.fill"
        case .utilities: return "bolt.fill"
        case .healthcare: return "heart.fill"
        case .education: return "book.fill"
        case .travel: return "airplane"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .food: return "orange"
        case .transportation: return "blue"
        case .entertainment: return "purple"
        case .shopping: return "pink"
        case .utilities: return "yellow"
        case .healthcare: return "red"
        case .education: return "green"
        case .travel: return "cyan"
        case .other: return "gray"
        }
    }
}
