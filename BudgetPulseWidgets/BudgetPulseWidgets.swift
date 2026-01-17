//
//  BudgetPulseWidgets.swift
//  BudgetPulseWidgets
//

import WidgetKit
import SwiftUI

// MARK: - Widget Localization Helper

private func WL(_ key: String) -> String {
    NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
}

private func WL(_ key: String, _ args: CVarArg...) -> String {
    String(format: NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: ""), arguments: args)
}

// MARK: - Widget Data Structures

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

// MARK: - Widget Data Provider

struct WidgetDataProvider {
    static let appGroupID = "group.com.budgetpulse.shared"

    static var budgetRemaining: Double {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        let spent = defaults.double(forKey: "widgetSpentThisMonth")
        let limit = defaults.double(forKey: "widgetMonthlyLimit")
        return max(0, limit - spent)
    }

    static var budgetProgress: Double {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        let spent = defaults.double(forKey: "widgetSpentThisMonth")
        let limit = defaults.double(forKey: "widgetMonthlyLimit")
        guard limit > 0 else { return 0 }
        return min(1.0, spent / limit)
    }

    static var spentThisMonth: Double {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        return defaults.double(forKey: "widgetSpentThisMonth")
    }

    static var monthlyLimit: Double {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        return defaults.double(forKey: "widgetMonthlyLimit")
    }

    static var todaySpending: Double {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        return defaults.double(forKey: "widgetTodaySpending")
    }

    static var totalSavings: Double {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        return defaults.double(forKey: "widgetTotalSavings")
    }

    static var savingsGoalProgress: Double {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        return defaults.double(forKey: "widgetSavingsGoalProgress")
    }

    static var currencySymbol: String {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        return defaults.string(forKey: "widgetCurrencySymbol") ?? "$"
    }

    static var categoryBreakdown: [WidgetCategoryData] {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        guard let data = defaults.data(forKey: "widgetCategoryBreakdown"),
              let categories = try? JSONDecoder().decode([WidgetCategoryData].self, from: data) else {
            return []
        }
        return categories
    }

    static var upcomingSubscriptions: [WidgetSubscriptionData] {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        guard let data = defaults.data(forKey: "widgetUpcomingSubscriptions"),
              let subs = try? JSONDecoder().decode([WidgetSubscriptionData].self, from: data) else {
            return []
        }
        return subs
    }

    static var monthlySubscriptions: Double {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        return defaults.double(forKey: "widgetMonthlySubscriptions")
    }

    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)\(Int(amount))"
    }

    static func categoryColor(_ colorName: String) -> Color {
        switch colorName {
        case "orange": return .orange
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "red": return .red
        case "green": return .green
        case "cyan": return .cyan
        default: return .gray
        }
    }
}

// MARK: - Budget Remaining Widget

struct BudgetRemainingEntry: TimelineEntry {
    let date: Date
    let remaining: Double
    let spent: Double
    let limit: Double
    let progress: Double
    let currencySymbol: String
}

struct BudgetRemainingProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetRemainingEntry {
        BudgetRemainingEntry(date: Date(), remaining: 500, spent: 500, limit: 1000, progress: 0.5, currencySymbol: "$")
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetRemainingEntry) -> Void) {
        let entry = BudgetRemainingEntry(
            date: Date(),
            remaining: WidgetDataProvider.budgetRemaining,
            spent: WidgetDataProvider.spentThisMonth,
            limit: WidgetDataProvider.monthlyLimit,
            progress: WidgetDataProvider.budgetProgress,
            currencySymbol: WidgetDataProvider.currencySymbol
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetRemainingEntry>) -> Void) {
        let entry = BudgetRemainingEntry(
            date: Date(),
            remaining: WidgetDataProvider.budgetRemaining,
            spent: WidgetDataProvider.spentThisMonth,
            limit: WidgetDataProvider.monthlyLimit,
            progress: WidgetDataProvider.budgetProgress,
            currencySymbol: WidgetDataProvider.currencySymbol
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct BudgetRemainingWidgetView: View {
    var entry: BudgetRemainingEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(.blue)
                Text(WL("widget_budget"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(WidgetDataProvider.formatCurrency(entry.remaining))
                .font(.title2)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)

            Text(WL("widget_remaining"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * entry.progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    var mediumView: some View {
        HStack(spacing: 16) {
            // Left side - amount
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .foregroundStyle(.blue)
                    Text(WL("widget_budget_remaining"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(WidgetDataProvider.formatCurrency(entry.remaining))
                    .font(.title)
                    .fontWeight(.bold)

                Text(WL("widget_used_this_month", Int(entry.progress * 100)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Right side - circular progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int((1 - entry.progress) * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(width: 60, height: 60)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    var progressColor: Color {
        if entry.progress >= 1.0 {
            return .red
        } else if entry.progress >= 0.8 {
            return .orange
        } else {
            return .blue
        }
    }
}

struct BudgetRemainingWidget: Widget {
    let kind: String = "BudgetRemainingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetRemainingProvider()) { entry in
            BudgetRemainingWidgetView(entry: entry)
        }
        .configurationDisplayName(WL("widget_budget_remaining"))
        .description(WL("widget_budget_remaining_desc"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Today's Spending Widget

struct TodaySpendingEntry: TimelineEntry {
    let date: Date
    let amount: Double
    let currencySymbol: String
}

struct TodaySpendingProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodaySpendingEntry {
        TodaySpendingEntry(date: Date(), amount: 25, currencySymbol: "$")
    }

    func getSnapshot(in context: Context, completion: @escaping (TodaySpendingEntry) -> Void) {
        let entry = TodaySpendingEntry(
            date: Date(),
            amount: WidgetDataProvider.todaySpending,
            currencySymbol: WidgetDataProvider.currencySymbol
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodaySpendingEntry>) -> Void) {
        let entry = TodaySpendingEntry(
            date: Date(),
            amount: WidgetDataProvider.todaySpending,
            currencySymbol: WidgetDataProvider.currencySymbol
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800)))
        completion(timeline)
    }
}

struct TodaySpendingWidgetView: View {
    var entry: TodaySpendingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundStyle(.orange)
                Text(WL("widget_today"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(WidgetDataProvider.formatCurrency(entry.amount))
                .font(.title2)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)

            Text(WL("widget_spent_today"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(formattedDate)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: entry.date)
    }
}

struct TodaySpendingWidget: Widget {
    let kind: String = "TodaySpendingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodaySpendingProvider()) { entry in
            TodaySpendingWidgetView(entry: entry)
        }
        .configurationDisplayName(WL("widget_todays_spending"))
        .description(WL("widget_todays_spending_desc"))
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Savings Goal Widget

struct SavingsGoalEntry: TimelineEntry {
    let date: Date
    let totalSavings: Double
    let progress: Double
    let currencySymbol: String
}

struct SavingsGoalProvider: TimelineProvider {
    func placeholder(in context: Context) -> SavingsGoalEntry {
        SavingsGoalEntry(date: Date(), totalSavings: 1500, progress: 0.6, currencySymbol: "$")
    }

    func getSnapshot(in context: Context, completion: @escaping (SavingsGoalEntry) -> Void) {
        let entry = SavingsGoalEntry(
            date: Date(),
            totalSavings: WidgetDataProvider.totalSavings,
            progress: WidgetDataProvider.savingsGoalProgress,
            currencySymbol: WidgetDataProvider.currencySymbol
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SavingsGoalEntry>) -> Void) {
        let entry = SavingsGoalEntry(
            date: Date(),
            totalSavings: WidgetDataProvider.totalSavings,
            progress: WidgetDataProvider.savingsGoalProgress,
            currencySymbol: WidgetDataProvider.currencySymbol
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct SavingsGoalWidgetView: View {
    var entry: SavingsGoalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(.purple)
                Text(WL("widget_savings"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(WidgetDataProvider.formatCurrency(entry.totalSavings))
                .font(.title2)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)

            Text(WL("widget_total_saved"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Progress bar
            if entry.progress > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple)
                            .frame(width: geometry.size.width * min(1.0, entry.progress), height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SavingsGoalWidget: Widget {
    let kind: String = "SavingsGoalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SavingsGoalProvider()) { entry in
            SavingsGoalWidgetView(entry: entry)
        }
        .configurationDisplayName(WL("widget_savings_progress"))
        .description(WL("widget_savings_progress_desc"))
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Category Breakdown Widget (Large)

struct CategoryBreakdownEntry: TimelineEntry {
    let date: Date
    let categories: [WidgetCategoryData]
    let totalSpent: Double
    let budgetLimit: Double
    let currencySymbol: String
}

struct CategoryBreakdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CategoryBreakdownEntry {
        CategoryBreakdownEntry(
            date: Date(),
            categories: [
                WidgetCategoryData(name: "food", amount: 350, icon: "cart.fill", color: "orange"),
                WidgetCategoryData(name: "transportation", amount: 150, icon: "car.fill", color: "blue"),
                WidgetCategoryData(name: "entertainment", amount: 100, icon: "tv.fill", color: "purple"),
                WidgetCategoryData(name: "utilities", amount: 80, icon: "bolt.fill", color: "yellow"),
                WidgetCategoryData(name: "shopping", amount: 70, icon: "bag.fill", color: "pink")
            ],
            totalSpent: 750,
            budgetLimit: 1000,
            currencySymbol: "$"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CategoryBreakdownEntry) -> Void) {
        let entry = CategoryBreakdownEntry(
            date: Date(),
            categories: WidgetDataProvider.categoryBreakdown,
            totalSpent: WidgetDataProvider.spentThisMonth,
            budgetLimit: WidgetDataProvider.monthlyLimit,
            currencySymbol: WidgetDataProvider.currencySymbol
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CategoryBreakdownEntry>) -> Void) {
        let entry = CategoryBreakdownEntry(
            date: Date(),
            categories: WidgetDataProvider.categoryBreakdown,
            totalSpent: WidgetDataProvider.spentThisMonth,
            budgetLimit: WidgetDataProvider.monthlyLimit,
            currencySymbol: WidgetDataProvider.currencySymbol
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct CategoryBreakdownWidgetView: View {
    var entry: CategoryBreakdownEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemLarge:
            largeView
        case .systemMedium:
            mediumView
        default:
            mediumView
        }
    }

    var mediumView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(.blue)
                Text(WL("widget_top_categories"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(WidgetDataProvider.formatCurrency(entry.totalSpent))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                ForEach(entry.categories.prefix(4), id: \.name) { category in
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(WidgetDataProvider.categoryColor(category.color).opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: category.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(WidgetDataProvider.categoryColor(category.color))
                        }
                        Text(WidgetDataProvider.formatCurrency(category.amount))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    var largeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "chart.pie.fill")
                            .foregroundStyle(.blue)
                        Text(WL("widget_monthly_spending"))
                            .font(.headline)
                    }
                    Text(currentMonthName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(WidgetDataProvider.formatCurrency(entry.totalSpent))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(WL("widget_of_budget", WidgetDataProvider.formatCurrency(entry.budgetLimit)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                let progress = entry.budgetLimit > 0 ? min(1.0, entry.totalSpent / entry.budgetLimit) : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(progress >= 1.0 ? Color.red : (progress >= 0.8 ? Color.orange : Color.blue))
                        .frame(width: geometry.size.width * progress, height: 10)
                }
            }
            .frame(height: 10)

            Divider()

            // Category List
            Text(WL("widget_top_categories"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if entry.categories.isEmpty {
                VStack {
                    Spacer()
                    Text(WL("widget_no_expenses"))
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            } else {
                ForEach(entry.categories.prefix(5), id: \.name) { category in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(WidgetDataProvider.categoryColor(category.color).opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: category.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(WidgetDataProvider.categoryColor(category.color))
                        }

                        Text(categoryDisplayName(category.name))
                            .font(.subheadline)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(WidgetDataProvider.formatCurrency(category.amount))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if entry.totalSpent > 0 {
                                Text("\(Int((category.amount / entry.totalSpent) * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: entry.date)
    }

    func categoryDisplayName(_ name: String) -> String {
        name.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

struct CategoryBreakdownWidget: Widget {
    let kind: String = "CategoryBreakdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CategoryBreakdownProvider()) { entry in
            CategoryBreakdownWidgetView(entry: entry)
        }
        .configurationDisplayName(WL("widget_category_breakdown"))
        .description(WL("widget_category_breakdown_desc"))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Upcoming Subscriptions Widget

struct UpcomingSubscriptionsEntry: TimelineEntry {
    let date: Date
    let subscriptions: [WidgetSubscriptionData]
    let monthlyTotal: Double
    let currencySymbol: String
}

struct UpcomingSubscriptionsProvider: TimelineProvider {
    func placeholder(in context: Context) -> UpcomingSubscriptionsEntry {
        UpcomingSubscriptionsEntry(
            date: Date(),
            subscriptions: [
                WidgetSubscriptionData(name: "Netflix", amount: 15.99, daysUntil: 2, icon: "tv.fill"),
                WidgetSubscriptionData(name: "Spotify", amount: 9.99, daysUntil: 5, icon: "music.note"),
                WidgetSubscriptionData(name: "iCloud", amount: 2.99, daysUntil: 7, icon: "cloud.fill")
            ],
            monthlyTotal: 50,
            currencySymbol: "$"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (UpcomingSubscriptionsEntry) -> Void) {
        let entry = UpcomingSubscriptionsEntry(
            date: Date(),
            subscriptions: WidgetDataProvider.upcomingSubscriptions,
            monthlyTotal: WidgetDataProvider.monthlySubscriptions,
            currencySymbol: WidgetDataProvider.currencySymbol
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpcomingSubscriptionsEntry>) -> Void) {
        let entry = UpcomingSubscriptionsEntry(
            date: Date(),
            subscriptions: WidgetDataProvider.upcomingSubscriptions,
            monthlyTotal: WidgetDataProvider.monthlySubscriptions,
            currencySymbol: WidgetDataProvider.currencySymbol
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct UpcomingSubscriptionsWidgetView: View {
    var entry: UpcomingSubscriptionsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundStyle(.green)
                Text(WL("widget_subscriptions"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(WidgetDataProvider.formatCurrency(entry.monthlyTotal))
                .font(.title2)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)

            Text(WL("widget_per_month"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let next = entry.subscriptions.first {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(WL("widget_sub_in_days", next.name, next.daysUntil))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    var mediumView: some View {
        HStack(spacing: 16) {
            // Left side - total
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundStyle(.green)
                    Text(WL("widget_subscriptions"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(WidgetDataProvider.formatCurrency(entry.monthlyTotal))
                    .font(.title)
                    .fontWeight(.bold)

                Text(WL("widget_per_month"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Right side - upcoming
            VStack(alignment: .leading, spacing: 6) {
                Text(WL("widget_upcoming"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                if entry.subscriptions.isEmpty {
                    Text(WL("widget_no_upcoming_payments"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(entry.subscriptions.prefix(3), id: \.name) { sub in
                        HStack(spacing: 8) {
                            Image(systemName: sub.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 16)

                            Text(sub.name)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            Text(dueText(sub.daysUntil))
                                .font(.caption2)
                                .foregroundStyle(sub.daysUntil <= 2 ? .orange : .secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    func dueText(_ days: Int) -> String {
        if days == 0 {
            return WL("widget_today")
        } else if days == 1 {
            return WL("widget_tomorrow")
        } else {
            return WL("widget_in_days", days)
        }
    }
}

struct UpcomingSubscriptionsWidget: Widget {
    let kind: String = "UpcomingSubscriptionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingSubscriptionsProvider()) { entry in
            UpcomingSubscriptionsWidgetView(entry: entry)
        }
        .configurationDisplayName(WL("widget_subscriptions"))
        .description(WL("widget_subscriptions_desc"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Quick Overview Widget (Accessory)

struct QuickOverviewEntry: TimelineEntry {
    let date: Date
    let remaining: Double
    let progress: Double
}

struct QuickOverviewProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickOverviewEntry {
        QuickOverviewEntry(date: Date(), remaining: 500, progress: 0.5)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickOverviewEntry) -> Void) {
        let entry = QuickOverviewEntry(
            date: Date(),
            remaining: WidgetDataProvider.budgetRemaining,
            progress: WidgetDataProvider.budgetProgress
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickOverviewEntry>) -> Void) {
        let entry = QuickOverviewEntry(
            date: Date(),
            remaining: WidgetDataProvider.budgetRemaining,
            progress: WidgetDataProvider.budgetProgress
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct QuickOverviewWidgetView: View {
    var entry: QuickOverviewEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    var circularView: some View {
        Gauge(value: 1 - entry.progress) {
            Image(systemName: "dollarsign")
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(entry.progress >= 0.8 ? .orange : .blue)
    }

    var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "chart.pie.fill")
                Text(WL("widget_budget"))
                    .fontWeight(.semibold)
            }
            Text(WidgetDataProvider.formatCurrency(entry.remaining))
                .font(.headline)
            Text(WL("widget_remaining"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    var inlineView: some View {
        Text(WL("widget_left", WidgetDataProvider.formatCurrency(entry.remaining)))
    }
}

struct QuickOverviewWidget: Widget {
    let kind: String = "QuickOverviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickOverviewProvider()) { entry in
            QuickOverviewWidgetView(entry: entry)
        }
        .configurationDisplayName(WL("widget_quick_budget"))
        .description(WL("widget_quick_budget_desc"))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Widget Bundle

@main
struct BudgetPulseWidgets: WidgetBundle {
    var body: some Widget {
        BudgetRemainingWidget()
        TodaySpendingWidget()
        SavingsGoalWidget()
        CategoryBreakdownWidget()
        UpcomingSubscriptionsWidget()
        QuickOverviewWidget()
    }
}

// MARK: - Previews

#Preview("Budget Remaining Small", as: .systemSmall) {
    BudgetRemainingWidget()
} timeline: {
    BudgetRemainingEntry(date: Date(), remaining: 750, spent: 250, limit: 1000, progress: 0.25, currencySymbol: "$")
    BudgetRemainingEntry(date: Date(), remaining: 250, spent: 750, limit: 1000, progress: 0.75, currencySymbol: "$")
    BudgetRemainingEntry(date: Date(), remaining: 0, spent: 1000, limit: 1000, progress: 1.0, currencySymbol: "$")
}

#Preview("Budget Remaining Medium", as: .systemMedium) {
    BudgetRemainingWidget()
} timeline: {
    BudgetRemainingEntry(date: Date(), remaining: 750, spent: 250, limit: 1000, progress: 0.25, currencySymbol: "$")
}

#Preview("Today Spending", as: .systemSmall) {
    TodaySpendingWidget()
} timeline: {
    TodaySpendingEntry(date: Date(), amount: 45.50, currencySymbol: "$")
}

#Preview("Savings Goal", as: .systemSmall) {
    SavingsGoalWidget()
} timeline: {
    SavingsGoalEntry(date: Date(), totalSavings: 2500, progress: 0.65, currencySymbol: "$")
}

#Preview("Category Breakdown Large", as: .systemLarge) {
    CategoryBreakdownWidget()
} timeline: {
    CategoryBreakdownEntry(
        date: Date(),
        categories: [
            WidgetCategoryData(name: "food", amount: 350, icon: "cart.fill", color: "orange"),
            WidgetCategoryData(name: "transportation", amount: 150, icon: "car.fill", color: "blue"),
            WidgetCategoryData(name: "entertainment", amount: 100, icon: "tv.fill", color: "purple"),
            WidgetCategoryData(name: "utilities", amount: 80, icon: "bolt.fill", color: "yellow"),
            WidgetCategoryData(name: "shopping", amount: 70, icon: "bag.fill", color: "pink")
        ],
        totalSpent: 750,
        budgetLimit: 1000,
        currencySymbol: "$"
    )
}

#Preview("Subscriptions Medium", as: .systemMedium) {
    UpcomingSubscriptionsWidget()
} timeline: {
    UpcomingSubscriptionsEntry(
        date: Date(),
        subscriptions: [
            WidgetSubscriptionData(name: "Netflix", amount: 15.99, daysUntil: 2, icon: "tv.fill"),
            WidgetSubscriptionData(name: "Spotify", amount: 9.99, daysUntil: 5, icon: "music.note"),
            WidgetSubscriptionData(name: "iCloud", amount: 2.99, daysUntil: 7, icon: "cloud.fill")
        ],
        monthlyTotal: 50,
        currencySymbol: "$"
    )
}
