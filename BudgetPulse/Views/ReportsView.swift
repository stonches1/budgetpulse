//
//  ReportsView.swift
//  BudgetPulse
//

import SwiftUI
import Charts

struct ReportsView: View {
    @State private var expenseStore = ExpenseStore.shared
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPeriod: ReportPeriod = .thisMonth

    var body: some View {
        NavigationStack {
            if subscriptionManager.canAccessReports {
                ScrollView {
                    VStack(spacing: 20) {
                        // Period Selector
                        periodSelector

                        // Summary Cards
                        summaryCards

                        // Budget Rollover Card
                        if expenseStore.budget.rolloverEnabled {
                            rolloverCard
                        }

                        // Subscription Summary Card
                        if !expenseStore.subscriptions.isEmpty {
                            subscriptionSummaryCard
                        }

                        // Spending Comparison Chart
                        spendingComparisonCard

                        // Top Categories
                        topCategoriesCard

                        // Monthly Breakdown
                        monthlyBreakdownCard

                        // Insights
                        insightsCard
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(L("reports"))
            } else {
                PremiumFeatureLockView(feature: L("reports"))
                    .navigationTitle(L("reports"))
            }
        }
        .sheet(isPresented: $subscriptionManager.showingPaywall) {
            PaywallView()
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        Picker(L("period"), selection: $selectedPeriod) {
            ForEach(ReportPeriod.allCases) { period in
                Text(period.localizedName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Budget Rollover Card

    private var rolloverCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L("budget_rollover"))
                    .font(.headline)
                Spacer()
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.purple)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("base_budget"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expenseStore.formatCurrency(expenseStore.budget.monthlyLimit))
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Image(systemName: expenseStore.budget.rolloverAmount >= 0 ? "plus.circle.fill" : "minus.circle.fill")
                    .foregroundStyle(expenseStore.budget.rolloverAmount >= 0 ? .green : .red)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("rollover"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expenseStore.formatCurrency(abs(expenseStore.budget.rolloverAmount)))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(expenseStore.budget.rolloverAmount >= 0 ? .green : .red)
                }

                Image(systemName: "equal")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("effective_budget"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expenseStore.formatCurrency(expenseStore.effectiveBudgetLimit))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
            }

            if expenseStore.budget.rolloverAmount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.green)
                    Text(L("rollover_savings_message"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if expenseStore.budget.rolloverAmount < 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(L("rollover_deficit_message"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Subscription Summary Card

    private var subscriptionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L("subscription_overview"))
                    .font(.headline)
                Spacer()
                NavigationLink {
                    SubscriptionsView()
                } label: {
                    Text(L("view_all"))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("monthly_cost"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expenseStore.formatCurrency(expenseStore.totalMonthlySubscriptions))
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(L("yearly_cost"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expenseStore.formatCurrency(expenseStore.totalYearlySubscriptions))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
            }

            // Top subscriptions by category
            let topSubCategories = expenseStore.subscriptionsByCategory
                .sorted { $0.value > $1.value }
                .prefix(3)

            if !topSubCategories.isEmpty {
                Divider()

                ForEach(Array(topSubCategories), id: \.key) { category, amount in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundStyle(categoryColor(category))
                            .frame(width: 24)
                        Text(category.localizedName)
                            .font(.subheadline)
                        Spacer()
                        Text(expenseStore.formatCurrency(amount) + "/" + L("month_abbr"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Upcoming payments
            if !expenseStore.upcomingSubscriptions.isEmpty {
                Divider()

                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(.orange)
                    Text(String(format: L("upcoming_payments_count"), expenseStore.upcomingSubscriptions.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(
                title: L("total_spent"),
                value: expenseStore.formatCurrency(totalSpent),
                icon: "arrow.up.circle.fill",
                color: .red
            )

            SummaryCard(
                title: L("total_income"),
                value: expenseStore.formatCurrency(totalIncome),
                icon: "arrow.down.circle.fill",
                color: .green
            )

            SummaryCard(
                title: L("net_balance"),
                value: expenseStore.formatCurrency(netBalance),
                icon: "equal.circle.fill",
                color: netBalance >= 0 ? .blue : .red
            )

            SummaryCard(
                title: L("avg_daily"),
                value: expenseStore.formatCurrency(averageDaily),
                icon: "calendar.circle.fill",
                color: .orange
            )
        }
    }

    // MARK: - Spending Comparison

    private var spendingComparisonCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("spending_comparison"))
                .font(.headline)

            if comparisonData.isEmpty {
                Text(L("no_data_available"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(comparisonData) { item in
                    BarMark(
                        x: .value(L("period"), item.label),
                        y: .value(L("amount"), item.amount)
                    )
                    .foregroundStyle(item.isCurrent ? Color.blue : Color.gray.opacity(0.5))
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(expenseStore.formatCurrency(amount))
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }

            // Comparison text
            if let change = spendingChange {
                HStack {
                    Image(systemName: change >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(change >= 0 ? .red : .green)
                    Text(String(format: L("spending_change"), abs(Int(change))))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Top Categories

    private var topCategoriesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("top_categories"))
                .font(.headline)

            if topCategories.isEmpty {
                Text(L("no_expenses_yet"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(topCategories.prefix(5), id: \.category) { item in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(categoryColor(item.category).opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: item.category.icon)
                                .foregroundStyle(categoryColor(item.category))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.category.localizedName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(Int(item.percentage))% " + L("of_total"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(expenseStore.formatCurrency(item.amount))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    if item.category != topCategories.prefix(5).last?.category {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Monthly Breakdown

    private var monthlyBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("monthly_breakdown"))
                .font(.headline)

            if monthlyData.isEmpty {
                Text(L("no_data_available"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(monthlyData) { item in
                    LineMark(
                        x: .value(L("month"), item.month),
                        y: .value(L("amount"), item.amount)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value(L("month"), item.month),
                        y: .value(L("amount"), item.amount)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value(L("month"), item.month),
                        y: .value(L("amount"), item.amount)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(expenseStore.formatCurrency(amount))
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Insights

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("insights"))
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                            .frame(width: 24)

                        Text(insight)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                }
            }

            if insights.isEmpty {
                Text(L("no_insights_yet"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Computed Properties

    private var periodExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .thisMonth:
            return expenseStore.thisMonthExpenses
        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return [] }
            return expenseStore.expenses(for: lastMonth)
        case .last3Months:
            guard let startDate = calendar.date(byAdding: .month, value: -3, to: now) else { return [] }
            return expenseStore.expenses.filter { $0.date >= startDate }
        case .thisYear:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return expenseStore.expenses.filter { $0.date >= startOfYear }
        }
    }

    private var periodIncomes: [Income] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .thisMonth:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return expenseStore.incomes.filter { $0.date >= startOfMonth }
        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now),
                  let startOfLastMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth)),
                  let endOfLastMonth = calendar.date(byAdding: .month, value: 1, to: startOfLastMonth) else { return [] }
            return expenseStore.incomes.filter { $0.date >= startOfLastMonth && $0.date < endOfLastMonth }
        case .last3Months:
            guard let startDate = calendar.date(byAdding: .month, value: -3, to: now) else { return [] }
            return expenseStore.incomes.filter { $0.date >= startDate }
        case .thisYear:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return expenseStore.incomes.filter { $0.date >= startOfYear }
        }
    }

    private var totalSpent: Double {
        periodExpenses.reduce(0) { $0 + $1.amount }
    }

    private var totalIncome: Double {
        periodIncomes.reduce(0) { $0 + $1.amount }
    }

    private var netBalance: Double {
        totalIncome - totalSpent
    }

    private var averageDaily: Double {
        let days = selectedPeriod.days
        return days > 0 ? totalSpent / Double(days) : 0
    }

    private var topCategories: [(category: ExpenseCategory, amount: Double, percentage: Double)] {
        var categoryTotals: [ExpenseCategory: Double] = [:]
        for expense in periodExpenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }

        let total = totalSpent
        return categoryTotals
            .map { (category: $0.key, amount: $0.value, percentage: total > 0 ? ($0.value / total) * 100 : 0) }
            .sorted { $0.amount > $1.amount }
    }

    private var comparisonData: [ComparisonItem] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .thisMonth:
            let thisMonthTotal = expenseStore.totalSpentThisMonth
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
                return [ComparisonItem(label: L("this_month"), amount: thisMonthTotal, isCurrent: true)]
            }
            let lastMonthTotal = expenseStore.totalSpent(for: lastMonth)
            return [
                ComparisonItem(label: L("last_month"), amount: lastMonthTotal, isCurrent: false),
                ComparisonItem(label: L("this_month"), amount: thisMonthTotal, isCurrent: true)
            ]
        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now),
                  let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now) else { return [] }
            return [
                ComparisonItem(label: L("previous"), amount: expenseStore.totalSpent(for: twoMonthsAgo), isCurrent: false),
                ComparisonItem(label: L("last_month"), amount: expenseStore.totalSpent(for: lastMonth), isCurrent: true)
            ]
        case .last3Months, .thisYear:
            return monthlyData.suffix(4).enumerated().map { index, item in
                ComparisonItem(label: item.monthLabel, amount: item.amount, isCurrent: index == monthlyData.suffix(4).count - 1)
            }
        }
    }

    private var spendingChange: Double? {
        guard comparisonData.count >= 2 else { return nil }
        let current = comparisonData.last?.amount ?? 0
        let previous = comparisonData[comparisonData.count - 2].amount
        guard previous > 0 else { return nil }
        return ((current - previous) / previous) * 100
    }

    private var monthlyData: [MonthlyDataItem] {
        let calendar = Calendar.current
        let now = Date()
        let monthsToShow: Int

        switch selectedPeriod {
        case .thisMonth, .lastMonth:
            monthsToShow = 6
        case .last3Months:
            monthsToShow = 3
        case .thisYear:
            monthsToShow = calendar.component(.month, from: now)
        }

        var data: [MonthlyDataItem] = []
        for i in (0..<monthsToShow).reversed() {
            guard let month = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            formatter.locale = LanguageManager.shared.effectiveLocale
            let amount = expenseStore.totalSpent(for: month)
            data.append(MonthlyDataItem(month: month, monthLabel: formatter.string(from: month), amount: amount))
        }
        return data
    }

    private var insights: [String] {
        var result: [String] = []

        // Top spending category insight
        if let topCategory = topCategories.first {
            result.append(String(format: L("insight_top_category"), topCategory.category.localizedName, Int(topCategory.percentage)))
        }

        // Budget status insight
        let budgetProgress = expenseStore.budgetProgress
        if budgetProgress >= 1.0 {
            result.append(L("insight_over_budget"))
        } else if budgetProgress >= 0.8 {
            result.append(String(format: L("insight_near_budget"), Int(budgetProgress * 100)))
        } else if budgetProgress < 0.5 && totalSpent > 0 {
            result.append(L("insight_good_progress"))
        }

        // Spending trend insight
        if let change = spendingChange {
            if change > 20 {
                result.append(String(format: L("insight_spending_up"), Int(change)))
            } else if change < -20 {
                result.append(String(format: L("insight_spending_down"), Int(abs(change))))
            }
        }

        // Savings insight
        if netBalance > 0 {
            result.append(String(format: L("insight_saved"), expenseStore.formatCurrency(netBalance)))
        }

        return result
    }

    private func categoryColor(_ category: ExpenseCategory) -> Color {
        switch category.color {
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

// MARK: - Supporting Types

enum ReportPeriod: String, CaseIterable, Identifiable {
    case thisMonth
    case lastMonth
    case last3Months
    case thisYear

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .thisMonth: return L("this_month")
        case .lastMonth: return L("last_month")
        case .last3Months: return L("last_3_months")
        case .thisYear: return L("this_year")
        }
    }

    var days: Int {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .thisMonth:
            return calendar.component(.day, from: now)
        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return 30 }
            return calendar.range(of: .day, in: .month, for: lastMonth)?.count ?? 30
        case .last3Months:
            return 90
        case .thisYear:
            return calendar.ordinality(of: .day, in: .year, for: now) ?? 365
        }
    }
}

struct ComparisonItem: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
    let isCurrent: Bool
}

struct MonthlyDataItem: Identifiable {
    let id = UUID()
    let month: Date
    let monthLabel: String
    let amount: Double
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ReportsView()
}
