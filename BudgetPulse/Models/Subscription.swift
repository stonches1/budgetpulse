//
//  Subscription.swift
//  BudgetPulse
//

import Foundation

struct Subscription: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var amount: Double
    var recurrenceType: RecurrenceType
    var category: ExpenseCategory
    var nextBillingDate: Date
    var startDate: Date
    var isActive: Bool
    var notes: String?
    var reminderEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        recurrenceType: RecurrenceType = .monthly,
        category: ExpenseCategory = .utilities,
        nextBillingDate: Date = Date(),
        startDate: Date = Date(),
        isActive: Bool = true,
        notes: String? = nil,
        reminderEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.recurrenceType = recurrenceType
        self.category = category
        self.nextBillingDate = nextBillingDate
        self.startDate = startDate
        self.isActive = isActive
        self.notes = notes
        self.reminderEnabled = reminderEnabled
    }

    /// Monthly cost of this subscription
    var monthlyCost: Double {
        amount * recurrenceType.monthlyMultiplier
    }

    /// Yearly cost of this subscription
    var yearlyCost: Double {
        monthlyCost * 12
    }

    /// Check if billing is due soon (within 7 days)
    var isDueSoon: Bool {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: nextBillingDate).day ?? 0
        return daysUntilDue >= 0 && daysUntilDue <= 7
    }

    /// Check if billing is overdue
    var isOverdue: Bool {
        nextBillingDate < Date()
    }

    /// Get days until next billing
    var daysUntilBilling: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextBillingDate).day ?? 0
    }
}
