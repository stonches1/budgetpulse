//
//  NotificationManager.swift
//  BudgetPulse
//

import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private let budgetAlertsKey = "BudgetAlertsEnabled"
    private let dailyRemindersKey = "DailyRemindersEnabled"
    private let reminderTimeKey = "ReminderTime"
    private let lastBudgetAlertKey = "LastBudgetAlertPercentage"

    var budgetAlertsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(budgetAlertsEnabled, forKey: budgetAlertsKey)
            if !budgetAlertsEnabled {
                cancelBudgetAlerts()
            }
        }
    }

    var dailyRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyRemindersEnabled, forKey: dailyRemindersKey)
            if dailyRemindersEnabled {
                scheduleDailyReminder()
            } else {
                cancelDailyReminders()
            }
        }
    }

    var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime.timeIntervalSince1970, forKey: reminderTimeKey)
            if dailyRemindersEnabled {
                scheduleDailyReminder()
            }
        }
    }

    private var lastBudgetAlertPercentage: Int {
        get { UserDefaults.standard.integer(forKey: lastBudgetAlertKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastBudgetAlertKey) }
    }

    private init() {
        self.budgetAlertsEnabled = UserDefaults.standard.bool(forKey: budgetAlertsKey)
        self.dailyRemindersEnabled = UserDefaults.standard.bool(forKey: dailyRemindersKey)

        if let savedTime = UserDefaults.standard.object(forKey: reminderTimeKey) as? Double {
            self.reminderTime = Date(timeIntervalSince1970: savedTime)
        } else {
            // Default to 8 PM
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 20
            components.minute = 0
            self.reminderTime = Calendar.current.date(from: components) ?? Date()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Budget Alerts

    func checkAndSendBudgetAlert() {
        guard budgetAlertsEnabled else { return }

        let store = ExpenseStore.shared
        let percentageUsed = Int(store.budgetProgress * 100)

        // Alert thresholds: 75%, 90%, 100%
        let thresholds = [75, 90, 100]

        for threshold in thresholds {
            if percentageUsed >= threshold && lastBudgetAlertPercentage < threshold {
                scheduleBudgetAlert(percentageUsed: threshold, remaining: store.formatCurrency(store.remainingBudget))
                lastBudgetAlertPercentage = threshold
                break
            }
        }

        // Reset at the start of a new month
        let calendar = Calendar.current
        let now = Date()
        if calendar.component(.day, from: now) == 1 {
            lastBudgetAlertPercentage = 0
        }
    }

    func scheduleBudgetAlert(percentageUsed: Int, remaining: String) {
        let content = UNMutableNotificationContent()
        content.title = L("notification_budget_alert_title")

        if percentageUsed >= 100 {
            content.body = L("notification_budget_exceeded_body")
        } else {
            content.body = String(format: L("notification_budget_alert_body"), percentageUsed, remaining)
        }

        content.sound = .default
        content.badge = 1

        let request = UNNotificationRequest(
            identifier: "budgetAlert_\(percentageUsed)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelBudgetAlerts() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "budgetAlert_75",
            "budgetAlert_90",
            "budgetAlert_100"
        ])
    }

    // MARK: - Daily Reminders

    func scheduleDailyReminder() {
        cancelDailyReminders()

        let content = UNMutableNotificationContent()
        content.title = L("notification_daily_reminder_title")
        content.body = L("notification_daily_reminder_body")
        content.sound = .default

        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelDailyReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }

    // MARK: - Recurring Expense Reminders

    func scheduleRecurringExpenseReminder(for expense: Expense) {
        guard expense.isRecurring, let nextDue = expense.nextDueDate else { return }

        let content = UNMutableNotificationContent()
        content.title = L("notification_bill_due_title")
        content.body = String(format: L("notification_bill_due_body"), expense.title, ExpenseStore.shared.formatCurrency(expense.amount))
        content.sound = .default

        // Remind one day before
        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .day, value: -1, to: nextDue) else { return }

        var dateComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "recurringExpense_\(expense.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelRecurringExpenseReminder(for expenseId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["recurringExpense_\(expenseId.uuidString)"])
    }

    // MARK: - Clear All

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
