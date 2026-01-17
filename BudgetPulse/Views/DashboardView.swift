//
//  DashboardView.swift
//  BudgetPulse
//

import SwiftUI
import Charts

struct DashboardView: View {
    @State private var expenseStore = ExpenseStore.shared
    @State private var showingAddExpense = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5 && hour < 12 {
            return L("greeting_morning")
        } else if hour >= 12 && hour < 17 {
            return L("greeting_afternoon")
        } else {
            return L("greeting_evening")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader

                    // Budget Overview Card
                    budgetOverviewCard

                    // Income & Net Balance Card
                    incomeBalanceCard

                    // Budget Progress
                    budgetProgressCard

                    // Quick Access Cards
                    quickAccessGrid

                    // Spending by Category (Pie Chart)
                    spendingByCategoryCard

                    // Recent Expenses
                    recentExpensesCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("BudgetPulse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Budget Overview Card

    private var budgetOverviewCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Total Spent
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("total_spent"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expenseStore.formatCurrency(expenseStore.totalSpentThisMonth))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(expenseStore.isOverBudget ? .red : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Remaining
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("remaining"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expenseStore.formatCurrency(max(0, expenseStore.remainingBudget)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(expenseStore.isOverBudget ? .red : .green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if expenseStore.isOverBudget {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(L("over_budget"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Income & Balance Card

    private var incomeBalanceCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Total Income
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.green)
                        Text(L("income"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(expenseStore.formatCurrency(expenseStore.totalIncomeThisMonth))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Net Balance
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "equal.circle.fill")
                            .foregroundStyle(expenseStore.netBalanceThisMonth >= 0 ? .blue : .red)
                        Text(L("net_balance"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(expenseStore.formatCurrency(expenseStore.netBalanceThisMonth))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(expenseStore.netBalanceThisMonth >= 0 ? .blue : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            NavigationLink(destination: IncomeListView()) {
                HStack {
                    Text(L("view_all_income"))
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Quick Access Grid

    private var quickAccessGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Savings Goals Card
            NavigationLink(destination: SavingsGoalsView()) {
                QuickAccessCard(
                    icon: "star.circle.fill",
                    iconColor: .purple,
                    title: L("savings_goals"),
                    value: expenseStore.formatCurrency(expenseStore.totalSavings),
                    subtitle: "\(expenseStore.activeSavingsGoals.count) \(L("active"))"
                )
            }
            .buttonStyle(.plain)

            // Subscriptions Card
            NavigationLink(destination: RecurringExpensesView()) {
                QuickAccessCard(
                    icon: "repeat.circle.fill",
                    iconColor: .orange,
                    title: L("subscriptions"),
                    value: expenseStore.formatCurrency(expenseStore.monthlySubscriptionsTotal),
                    subtitle: L("per_month")
                )
            }
            .buttonStyle(.plain)

            // Spending Trends Card
            NavigationLink(destination: SpendingTrendsView()) {
                QuickAccessCard(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    iconColor: .blue,
                    title: L("spending_trends"),
                    value: expenseStore.formatCurrency(expenseStore.averageDailySpending()),
                    subtitle: L("avg_daily")
                )
            }
            .buttonStyle(.plain)

            // Category Budgets Card
            NavigationLink(destination: CategoryBudgetSettingsView()) {
                QuickAccessCard(
                    icon: "chart.pie.fill",
                    iconColor: .teal,
                    title: L("category_budgets"),
                    value: "\(expenseStore.budget.categoryBudgets.count)",
                    subtitle: L("limits_set")
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Budget Progress Card

    private var budgetProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("budget_progress"))
                .font(.headline)

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * expenseStore.budgetProgress, height: 12)
                }
            }
            .frame(height: 12)

            // Budget Summary Text
            Text(budgetSummaryText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(Int(expenseStore.budgetProgress * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(progressColor)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var budgetSummaryText: String {
        let spent = expenseStore.formatCurrency(expenseStore.totalSpentThisMonth)
        let budget = expenseStore.formatCurrency(expenseStore.budget.monthlyLimit)
        let format = L("this_month_spent_of_budget")
        return String(format: format, spent, budget)
    }

    private var progressColor: Color {
        let progress = expenseStore.budgetProgress
        if progress < 0.5 {
            return .green
        } else if progress < 0.75 {
            return .yellow
        } else if progress < 1.0 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Spending by Category Card (Pie Chart)

    private var spendingByCategoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("spending_by_category"))
                .font(.headline)

            if expenseStore.expensesByCategory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text(L("no_expenses_yet"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // Pie Chart
                SpendingPieChartView(expensesByCategory: expenseStore.expensesByCategory)
                    .frame(height: 220)

                // Legend
                VStack(spacing: 8) {
                    ForEach(Array(expenseStore.expensesByCategory.sorted { $0.value > $1.value }), id: \.key) { category, amount in
                        HStack {
                            Circle()
                                .fill(categoryColor(category))
                                .frame(width: 10, height: 10)
                            Text(category.localizedName)
                                .font(.caption)
                            Spacer()
                            Text(expenseStore.formatCurrency(amount))
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("(\(percentageString(for: amount)))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func percentageString(for amount: Double) -> String {
        let total = expenseStore.totalSpentThisMonth
        guard total > 0 else { return "0%" }
        let percentage = (amount / total) * 100
        return String(format: "%.0f%%", percentage)
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

    // MARK: - Recent Expenses Card

    private var recentExpensesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("recent_expenses"))
                    .font(.headline)
                Spacer()
                NavigationLink {
                    AllExpensesView()
                } label: {
                    Text(L("view_all"))
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            if expenseStore.recentExpenses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(L("no_expenses_yet"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(expenseStore.recentExpenses) { expense in
                    ExpenseRowView(expense: expense)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Spending Pie Chart View

struct SpendingPieChartView: View {
    let expensesByCategory: [ExpenseCategory: Double]

    private var chartData: [CategoryChartData] {
        expensesByCategory.map { category, amount in
            CategoryChartData(category: category, amount: amount)
        }
        .sorted { $0.amount > $1.amount }
    }

    private var total: Double {
        expensesByCategory.values.reduce(0, +)
    }

    var body: some View {
        Chart(chartData) { data in
            SectorMark(
                angle: .value("Amount", data.amount),
                innerRadius: .ratio(0.5),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(categoryColor(data.category))
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                let frame = geometry[chartProxy.plotFrame!]
                VStack {
                    Text(formatCurrency(total))
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(L("total_spent"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .position(x: frame.midX, y: frame.midY)
            }
        }
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

    private func formatCurrency(_ amount: Double) -> String {
        ExpenseStore.shared.formatCurrency(amount)
    }
}

// MARK: - Chart Data Model

struct CategoryChartData: Identifiable {
    let id = UUID()
    let category: ExpenseCategory
    let amount: Double
}

// MARK: - Expense Row View

struct ExpenseRowView: View {
    let expense: Expense
    @State private var expenseStore = ExpenseStore.shared

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: expense.category.icon)
                    .foregroundStyle(categoryColor)
            }

            // Title and Category
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(expense.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    // Receipt indicator
                    if expense.receiptImagePath != nil {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Recurring indicator
                    if expense.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(expense.category.localizedName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount and Date
            VStack(alignment: .trailing, spacing: 2) {
                Text(expenseStore.formatCurrency(expense.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(expenseStore.formatDate(expense.date, style: .short))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch expense.category.color {
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

// MARK: - Quick Access Card

struct QuickAccessCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    DashboardView()
}
