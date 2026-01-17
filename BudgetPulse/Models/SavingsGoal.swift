//
//  SavingsGoal.swift
//  BudgetPulse
//

import Foundation

struct SavingsGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var targetAmount: Double
    var currentAmount: Double
    var targetDate: Date?
    var icon: String
    var color: String
    var contributions: [SavingsContribution]

    init(id: UUID = UUID(), title: String, targetAmount: Double, currentAmount: Double = 0, targetDate: Date? = nil, icon: String = "star.fill", color: String = "blue", contributions: [SavingsContribution] = []) {
        self.id = id
        self.title = title
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.icon = icon
        self.color = color
        self.contributions = contributions
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    var isCompleted: Bool {
        currentAmount >= targetAmount
    }

    var remainingAmount: Double {
        max(targetAmount - currentAmount, 0)
    }

    var daysRemaining: Int? {
        guard let targetDate = targetDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return max(components.day ?? 0, 0)
    }

    var suggestedMonthlyContribution: Double? {
        guard let targetDate = targetDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: Date(), to: targetDate)
        let monthsRemaining = max(components.month ?? 1, 1)
        return remainingAmount / Double(monthsRemaining)
    }
}

struct SavingsContribution: Identifiable, Codable, Equatable {
    let id: UUID
    var amount: Double
    var date: Date
    var notes: String?

    init(id: UUID = UUID(), amount: Double, date: Date = Date(), notes: String? = nil) {
        self.id = id
        self.amount = amount
        self.date = date
        self.notes = notes
    }
}

enum GoalIcon: String, CaseIterable, Identifiable {
    case star = "star.fill"
    case house = "house.fill"
    case car = "car.fill"
    case airplane = "airplane"
    case graduationcap = "graduationcap.fill"
    case heart = "heart.fill"
    case gift = "gift.fill"
    case banknote = "banknote.fill"
    case creditcard = "creditcard.fill"
    case bag = "bag.fill"
    case cross = "cross.fill"
    case laptopcomputer = "laptopcomputer"
    case iphone = "iphone"
    case camera = "camera.fill"
    case gamecontroller = "gamecontroller.fill"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .star: return L("icon_star")
        case .house: return L("icon_house")
        case .car: return L("icon_car")
        case .airplane: return L("icon_travel")
        case .graduationcap: return L("icon_education")
        case .heart: return L("icon_health")
        case .gift: return L("icon_gift")
        case .banknote: return L("icon_savings")
        case .creditcard: return L("icon_debt")
        case .bag: return L("icon_shopping")
        case .cross: return L("icon_emergency")
        case .laptopcomputer: return L("icon_electronics")
        case .iphone: return L("icon_phone")
        case .camera: return L("icon_hobby")
        case .gamecontroller: return L("icon_entertainment")
        }
    }
}

enum GoalColor: String, CaseIterable, Identifiable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case purple = "purple"
    case pink = "pink"
    case yellow = "yellow"
    case cyan = "cyan"
    case indigo = "indigo"
    case mint = "mint"

    var id: String { rawValue }
}
