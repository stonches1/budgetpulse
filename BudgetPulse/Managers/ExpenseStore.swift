//
//  ExpenseStore.swift
//  BudgetPulse
//

import Foundation
import SwiftUI
import WidgetKit

enum DateFilter: Equatable, CaseIterable, Identifiable {
    case thisMonth
    case lastMonth
    case last3Months
    case last6Months
    case thisYear
    case custom(start: Date, end: Date)

    var id: String {
        switch self {
        case .thisMonth: return "thisMonth"
        case .lastMonth: return "lastMonth"
        case .last3Months: return "last3Months"
        case .last6Months: return "last6Months"
        case .thisYear: return "thisYear"
        case .custom(let start, let end): return "custom_\(start)_\(end)"
        }
    }

    var localizedName: String {
        switch self {
        case .thisMonth: return L("this_month")
        case .lastMonth: return L("last_month")
        case .last3Months: return L("last_3_months")
        case .last6Months: return L("last_6_months")
        case .thisYear: return L("this_year")
        case .custom: return L("custom_range")
        }
    }

    static var allCases: [DateFilter] {
        [.thisMonth, .lastMonth, .last3Months, .last6Months, .thisYear]
    }

    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return (start, end)
        case .lastMonth:
            let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth)!
            let end = calendar.date(byAdding: .day, value: -1, to: startOfThisMonth)!
            return (start, end)
        case .last3Months:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, now)
        case .last6Months:
            let start = calendar.date(byAdding: .month, value: -6, to: now)!
            return (start, now)
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return (start, now)
        case .custom(let start, let end):
            return (start, end)
        }
    }
}

struct DailySpending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: Date
    let amount: Double
}

// Widget Data Structures
struct WidgetCategoryData: Codable {
    let name: String
    let amount: Double
    let icon: String
    let color: String
}

struct WidgetSubscriptionData: Codable {
    let name: String
    let amount: Double
    let daysUntil: Int
    let icon: String
}

@MainActor
@Observable
final class ExpenseStore {
    static let shared = ExpenseStore()

    private(set) var expenses: [Expense] = []
    private(set) var incomes: [Income] = []
    private(set) var savingsGoals: [SavingsGoal] = []
    private(set) var subscriptions: [Subscription] = []
    var budget: Budget = Budget()

    private let expensesKey = "SavedExpenses"
    private let budgetKey = "SavedBudget"
    private let incomesKey = "SavedIncomes"
    private let savingsGoalsKey = "SavedSavingsGoals"
    private let subscriptionsKey = "SavedSubscriptions"
    private let dataVersionKey = "DataSchemaVersion"
    private let currentDataVersion = 3

    private init() {
        loadData()
        migrateDataIfNeeded()
        checkAndApplyRollover()
    }

    // MARK: - Computed Properties

    var totalSpentThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        return expenses
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }

    var remainingBudget: Double {
        budget.monthlyLimit - totalSpentThisMonth
    }

    var budgetProgress: Double {
        guard budget.monthlyLimit > 0 else { return 0 }
        return min(totalSpentThisMonth / budget.monthlyLimit, 1.0)
    }

    var isOverBudget: Bool {
        totalSpentThisMonth > budget.monthlyLimit
    }

    var recentExpenses: [Expense] {
        Array(expenses.sorted { $0.date > $1.date }.prefix(5))
    }

    var thisMonthExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        return expenses
            .filter { $0.date >= startOfMonth }
            .sorted { $0.date > $1.date }
    }

    var expensesByCategory: [ExpenseCategory: Double] {
        var result: [ExpenseCategory: Double] = [:]
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        for expense in expenses where expense.date >= startOfMonth {
            result[expense.category, default: 0] += expense.amount
        }
        return result
    }

    // MARK: - Income Computed Properties

    var totalIncomeThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        return incomes
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }

    var netBalanceThisMonth: Double {
        totalIncomeThisMonth - totalSpentThisMonth
    }

    var recentIncomes: [Income] {
        Array(incomes.sorted { $0.date > $1.date }.prefix(5))
    }

    var thisMonthIncomes: [Income] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        return incomes
            .filter { $0.date >= startOfMonth }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Recurring Expenses Computed Properties

    var recurringExpenses: [Expense] {
        expenses.filter { $0.isRecurring }
    }

    var upcomingRecurringExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now)!

        return recurringExpenses
            .filter { expense in
                guard let nextDue = expense.nextDueDate else { return false }
                return nextDue >= now && nextDue <= weekFromNow
            }
            .sorted { ($0.nextDueDate ?? Date()) < ($1.nextDueDate ?? Date()) }
    }

    var monthlySubscriptionsTotal: Double {
        recurringExpenses.reduce(0) { total, expense in
            let multiplier = expense.recurrenceType?.monthlyMultiplier ?? 1.0
            return total + (expense.amount * multiplier)
        }
    }

    // MARK: - Savings Goals Computed Properties

    var totalSavings: Double {
        savingsGoals.reduce(0) { $0 + $1.currentAmount }
    }

    var activeSavingsGoals: [SavingsGoal] {
        savingsGoals.filter { !$0.isCompleted }
    }

    var completedSavingsGoals: [SavingsGoal] {
        savingsGoals.filter { $0.isCompleted }
    }

    // MARK: - Subscription Computed Properties

    var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive }
    }

    var totalMonthlySubscriptions: Double {
        activeSubscriptions.reduce(0) { $0 + $1.monthlyCost }
    }

    var totalYearlySubscriptions: Double {
        totalMonthlySubscriptions * 12
    }

    var upcomingSubscriptions: [Subscription] {
        activeSubscriptions
            .filter { $0.isDueSoon }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    var overdueSubscriptions: [Subscription] {
        activeSubscriptions.filter { $0.isOverdue }
    }

    var subscriptionsByCategory: [ExpenseCategory: Double] {
        var result: [ExpenseCategory: Double] = [:]
        for subscription in activeSubscriptions {
            result[subscription.category, default: 0] += subscription.monthlyCost
        }
        return result
    }

    // MARK: - Budget Rollover Computed Properties

    var effectiveBudgetLimit: Double {
        budget.effectiveMonthlyLimit
    }

    var remainingBudgetWithRollover: Double {
        effectiveBudgetLimit - totalSpentThisMonth
    }

    var rolloverStatus: String {
        if budget.rolloverAmount > 0 {
            return L("rollover_positive")
        } else if budget.rolloverAmount < 0 {
            return L("rollover_negative")
        }
        return L("rollover_none")
    }

    // MARK: - Category Budget Computed Properties

    func categorySpentThisMonth(for category: ExpenseCategory) -> Double {
        expensesByCategory[category] ?? 0
    }

    func categoryBudgetProgress(for category: ExpenseCategory) -> Double {
        guard let limit = budget.budgetLimit(for: category), limit > 0 else { return 0 }
        return min(categorySpentThisMonth(for: category) / limit, 1.0)
    }

    func isCategoryOverBudget(_ category: ExpenseCategory) -> Bool {
        guard let limit = budget.budgetLimit(for: category) else { return false }
        return categorySpentThisMonth(for: category) > limit
    }

    func categoryRemainingBudget(for category: ExpenseCategory) -> Double? {
        guard let limit = budget.budgetLimit(for: category) else { return nil }
        return limit - categorySpentThisMonth(for: category)
    }

    // MARK: - Actions

    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        saveData()
    }

    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        saveData()
    }

    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveData()
        }
    }

    func deleteExpenses(at offsets: IndexSet, from list: [Expense]) {
        for index in offsets {
            let expense = list[index]
            deleteExpense(expense)
        }
    }

    func updateBudget(_ newBudget: Budget) {
        budget = newBudget
        saveData()
    }

    func updateMonthlyLimit(_ limit: Double) {
        budget.monthlyLimit = limit
        saveData()
    }

    func updateCurrency(_ currency: CurrencyCode) {
        budget.currency = currency
        saveData()
    }

    // MARK: - Category Budget Actions

    func setCategoryBudget(_ limit: Double?, for category: ExpenseCategory) {
        budget.setBudgetLimit(limit, for: category)
        saveData()
    }

    // MARK: - Income Actions

    func addIncome(_ income: Income) {
        incomes.append(income)
        saveData()
    }

    func deleteIncome(_ income: Income) {
        incomes.removeAll { $0.id == income.id }
        saveData()
    }

    func updateIncome(_ income: Income) {
        if let index = incomes.firstIndex(where: { $0.id == income.id }) {
            incomes[index] = income
            saveData()
        }
    }

    func deleteIncomes(at offsets: IndexSet, from list: [Income]) {
        for index in offsets {
            let income = list[index]
            deleteIncome(income)
        }
    }

    // MARK: - Savings Goal Actions

    func addSavingsGoal(_ goal: SavingsGoal) {
        savingsGoals.append(goal)
        saveData()
    }

    func deleteSavingsGoal(_ goal: SavingsGoal) {
        savingsGoals.removeAll { $0.id == goal.id }
        saveData()
    }

    func updateSavingsGoal(_ goal: SavingsGoal) {
        if let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) {
            savingsGoals[index] = goal
            saveData()
        }
    }

    func addContribution(_ amount: Double, to goalId: UUID, notes: String? = nil) {
        guard let index = savingsGoals.firstIndex(where: { $0.id == goalId }) else { return }
        let contribution = SavingsContribution(amount: amount, notes: notes)
        savingsGoals[index].contributions.append(contribution)
        savingsGoals[index].currentAmount += amount
        saveData()
    }

    func removeContribution(_ contributionId: UUID, from goalId: UUID) {
        guard let goalIndex = savingsGoals.firstIndex(where: { $0.id == goalId }) else { return }
        if let contribIndex = savingsGoals[goalIndex].contributions.firstIndex(where: { $0.id == contributionId }) {
            let amount = savingsGoals[goalIndex].contributions[contribIndex].amount
            savingsGoals[goalIndex].currentAmount -= amount
            savingsGoals[goalIndex].contributions.remove(at: contribIndex)
            saveData()
        }
    }

    // MARK: - Subscription Actions

    func addSubscription(_ subscription: Subscription) {
        subscriptions.append(subscription)
        saveData()
    }

    func deleteSubscription(_ subscription: Subscription) {
        subscriptions.removeAll { $0.id == subscription.id }
        saveData()
    }

    func updateSubscription(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
            saveData()
        }
    }

    func markSubscriptionPaid(_ subscription: Subscription) {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }

        // Create an expense record for this payment
        let expense = Expense(
            title: subscription.name,
            amount: subscription.amount,
            category: subscription.category,
            date: Date(),
            notes: L("subscription_payment")
        )
        addExpense(expense)

        // Update the next billing date
        subscriptions[index].nextBillingDate = subscription.recurrenceType.nextDate(from: Date())
        saveData()
    }

    func toggleSubscriptionActive(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index].isActive.toggle()
            saveData()
        }
    }

    // MARK: - Budget Rollover Actions

    func toggleRollover(_ enabled: Bool) {
        budget.rolloverEnabled = enabled
        if !enabled {
            budget.rolloverAmount = 0
            budget.lastRolloverMonth = nil
        }
        saveData()
    }

    func checkAndApplyRollover() {
        guard budget.rolloverEnabled else { return }

        let calendar = Calendar.current
        let now = Date()
        let currentMonthKey = monthKey(for: now)

        // Check if we've already applied rollover this month
        if budget.lastRolloverMonth == currentMonthKey {
            return
        }

        // Calculate last month's unused budget
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return }
        let lastMonthSpent = totalSpent(for: lastMonth)
        let unusedBudget = budget.monthlyLimit - lastMonthSpent

        // Apply rollover (can be negative if overspent)
        budget.rolloverAmount = unusedBudget
        budget.lastRolloverMonth = currentMonthKey
        saveData()
    }

    func resetRollover() {
        budget.rolloverAmount = 0
        budget.lastRolloverMonth = nil
        saveData()
    }

    private func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    // MARK: - Recurring Expense Actions

    func markRecurringExpensePaid(_ expense: Expense) {
        guard expense.isRecurring, let recurrenceType = expense.recurrenceType else { return }

        // Create a new one-time expense record
        let paidExpense = Expense(
            title: expense.title,
            amount: expense.amount,
            category: expense.category,
            date: Date(),
            notes: expense.notes
        )
        addExpense(paidExpense)

        // Update the next due date
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index].nextDueDate = recurrenceType.nextDate(from: Date())
            saveData()
        }
    }

    func skipRecurringExpense(_ expense: Expense) {
        guard expense.isRecurring, let recurrenceType = expense.recurrenceType else { return }

        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index].nextDueDate = recurrenceType.nextDate(from: Date())
            saveData()
        }
    }

    // MARK: - Date Filtering

    func expenses(for filter: DateFilter) -> [Expense] {
        let range = filter.dateRange
        return expenses
            .filter { $0.date >= range.start && $0.date <= range.end }
            .sorted { $0.date > $1.date }
    }

    func totalSpent(for filter: DateFilter) -> Double {
        expenses(for: filter).reduce(0) { $0 + $1.amount }
    }

    func incomes(for filter: DateFilter) -> [Income] {
        let range = filter.dateRange
        return incomes
            .filter { $0.date >= range.start && $0.date <= range.end }
            .sorted { $0.date > $1.date }
    }

    func totalIncome(for filter: DateFilter) -> Double {
        incomes(for: filter).reduce(0) { $0 + $1.amount }
    }

    // MARK: - Spending Trends

    func dailySpending(days: Int = 30) -> [DailySpending] {
        let calendar = Calendar.current
        let now = Date()
        var result: [DailySpending] = []

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            let dayTotal = expenses
                .filter { $0.date >= startOfDay && $0.date < endOfDay }
                .reduce(0) { $0 + $1.amount }

            result.append(DailySpending(date: startOfDay, amount: dayTotal))
        }

        return result.reversed()
    }

    func monthlySpending(months: Int = 6) -> [MonthlySpending] {
        let calendar = Calendar.current
        let now = Date()
        var result: [MonthlySpending] = []

        for monthOffset in 0..<months {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { continue }

            let monthTotal = expenses
                .filter { $0.date >= startOfMonth && $0.date < endOfMonth }
                .reduce(0) { $0 + $1.amount }

            result.append(MonthlySpending(month: startOfMonth, amount: monthTotal))
        }

        return result.reversed()
    }

    func averageDailySpending(days: Int = 30) -> Double {
        let dailyData = dailySpending(days: days)
        guard !dailyData.isEmpty else { return 0 }
        let total = dailyData.reduce(0) { $0 + $1.amount }
        return total / Double(dailyData.count)
    }

    // MARK: - Formatting Helpers

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = budget.currency.locale
        formatter.currencyCode = budget.currency.rawValue
        return formatter.string(from: NSNumber(value: amount)) ?? "\(budget.currency.symbol)\(amount)"
    }

    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = LanguageManager.shared.effectiveLocale
        return formatter.string(from: date)
    }

    func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = LanguageManager.shared.effectiveLocale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Persistence

    private func saveData() {
        if let encodedExpenses = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encodedExpenses, forKey: expensesKey)
        }
        if let encodedBudget = try? JSONEncoder().encode(budget) {
            UserDefaults.standard.set(encodedBudget, forKey: budgetKey)
        }
        if let encodedIncomes = try? JSONEncoder().encode(incomes) {
            UserDefaults.standard.set(encodedIncomes, forKey: incomesKey)
        }
        if let encodedGoals = try? JSONEncoder().encode(savingsGoals) {
            UserDefaults.standard.set(encodedGoals, forKey: savingsGoalsKey)
        }
        if let encodedSubscriptions = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(encodedSubscriptions, forKey: subscriptionsKey)
        }
        UserDefaults.standard.set(currentDataVersion, forKey: dataVersionKey)

        // Sync widget data
        syncWidgetData()
    }

    // MARK: - Widget Data Sync

    private let widgetAppGroupID = "group.com.budgetpulse.shared"

    private func syncWidgetData() {
        guard let defaults = UserDefaults(suiteName: widgetAppGroupID) else { return }

        // Budget data
        defaults.set(totalSpentThisMonth, forKey: "widgetSpentThisMonth")
        defaults.set(budget.monthlyLimit, forKey: "widgetMonthlyLimit")

        // Today's spending
        let calendar = Calendar.current
        let todaySpending = expenses
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
        defaults.set(todaySpending, forKey: "widgetTodaySpending")

        // Savings data
        defaults.set(totalSavings, forKey: "widgetTotalSavings")

        // Calculate average savings goal progress
        let activeGoals = activeSavingsGoals
        if !activeGoals.isEmpty {
            let avgProgress = activeGoals.reduce(0) { $0 + $1.progress } / Double(activeGoals.count)
            defaults.set(avgProgress, forKey: "widgetSavingsGoalProgress")
        } else {
            defaults.set(0.0, forKey: "widgetSavingsGoalProgress")
        }

        // Currency symbol
        defaults.set(budget.currency.symbol, forKey: "widgetCurrencySymbol")

        // Category breakdown data (top 5 categories)
        let categoryData = expensesByCategory
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ["name": $0.key.rawValue, "amount": $0.value, "icon": $0.key.icon, "color": $0.key.color] }
        if let encodedCategories = try? JSONEncoder().encode(categoryData.map { WidgetCategoryData(name: $0["name"] as? String ?? "", amount: $0["amount"] as? Double ?? 0, icon: $0["icon"] as? String ?? "", color: $0["color"] as? String ?? "") }) {
            defaults.set(encodedCategories, forKey: "widgetCategoryBreakdown")
        }

        // Upcoming subscriptions (next 3)
        let upcomingSubs = upcomingSubscriptions.prefix(3).map {
            WidgetSubscriptionData(name: $0.name, amount: $0.amount, daysUntil: $0.daysUntilBilling, icon: $0.category.icon)
        }
        if let encodedSubs = try? JSONEncoder().encode(upcomingSubs) {
            defaults.set(encodedSubs, forKey: "widgetUpcomingSubscriptions")
        }

        // Total monthly subscriptions
        defaults.set(totalMonthlySubscriptions, forKey: "widgetMonthlySubscriptions")

        // Request widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func loadData() {
        if let expensesData = UserDefaults.standard.data(forKey: expensesKey),
           let decodedExpenses = try? JSONDecoder().decode([Expense].self, from: expensesData) {
            expenses = decodedExpenses
        }
        if let budgetData = UserDefaults.standard.data(forKey: budgetKey),
           let decodedBudget = try? JSONDecoder().decode(Budget.self, from: budgetData) {
            budget = decodedBudget
        }
        if let incomesData = UserDefaults.standard.data(forKey: incomesKey),
           let decodedIncomes = try? JSONDecoder().decode([Income].self, from: incomesData) {
            incomes = decodedIncomes
        }
        if let goalsData = UserDefaults.standard.data(forKey: savingsGoalsKey),
           let decodedGoals = try? JSONDecoder().decode([SavingsGoal].self, from: goalsData) {
            savingsGoals = decodedGoals
        }
        if let subscriptionsData = UserDefaults.standard.data(forKey: subscriptionsKey),
           let decodedSubscriptions = try? JSONDecoder().decode([Subscription].self, from: subscriptionsData) {
            subscriptions = decodedSubscriptions
        }
    }

    private func migrateDataIfNeeded() {
        let savedVersion = UserDefaults.standard.integer(forKey: dataVersionKey)
        if savedVersion < currentDataVersion {
            // Migration from version 1 to 2: expenses now have default values for new fields
            // Swift's Codable handles missing fields with default values, so no explicit migration needed
            saveData()
        }
    }

    // MARK: - Monthly History

    var availableMonths: [Date] {
        let calendar = Calendar.current
        var months: Set<Date> = []

        for expense in expenses {
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            if let monthStart = calendar.date(from: components) {
                months.insert(monthStart)
            }
        }

        return months.sorted(by: >)
    }

    func expenses(for month: Date) -> [Expense] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        return expenses
            .filter { $0.date >= startOfMonth && $0.date <= endOfMonth }
            .sorted { $0.date > $1.date }
    }

    func totalSpent(for month: Date) -> Double {
        expenses(for: month).reduce(0) { $0 + $1.amount }
    }

    func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = LanguageManager.shared.effectiveLocale
        return formatter.string(from: date)
    }

    // MARK: - Export

    func exportToCSV() -> String {
        var csv = "Date,Title,Category,Amount,Notes\n"

        let sortedExpenses = expenses.sorted { $0.date > $1.date }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.locale = LanguageManager.shared.effectiveLocale

        for expense in sortedExpenses {
            let date = dateFormatter.string(from: expense.date)
            let title = expense.title.replacingOccurrences(of: ",", with: ";")
            let category = expense.category.localizedName.replacingOccurrences(of: ",", with: ";")
            let amount = String(format: "%.2f", expense.amount)
            let notes = (expense.notes ?? "").replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\n", with: " ")

            csv += "\(date),\(title),\(category),\(amount),\(notes)\n"
        }

        return csv
    }

    // MARK: - Reset

    func resetAllData() {
        expenses = []
        incomes = []
        savingsGoals = []
        subscriptions = []
        budget = Budget()
        saveData()
    }

    // MARK: - Sample Data (for testing)

    func loadSampleData() {
        let sampleExpenses = [
            Expense(title: "Coffee", amount: 5.50, category: .food, date: Date()),
            Expense(title: "Gas", amount: 45.00, category: .transportation, date: Date().addingTimeInterval(-86400)),
            Expense(title: "Netflix", amount: 15.99, category: .entertainment, date: Date().addingTimeInterval(-172800)),
            Expense(title: "Groceries", amount: 125.75, category: .food, date: Date().addingTimeInterval(-259200)),
            Expense(title: "Electricity", amount: 89.00, category: .utilities, date: Date().addingTimeInterval(-345600))
        ]
        expenses = sampleExpenses
        saveData()
    }
}
