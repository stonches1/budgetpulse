//
//  CategoriesView.swift
//  BudgetPulse
//

import SwiftUI

struct CategoriesView: View {
    @State private var expenseStore = ExpenseStore.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ExpenseCategory.allCases) { category in
                        NavigationLink {
                            CategoryDetailView(category: category)
                        } label: {
                            CategoryRowView(category: category)
                        }
                    }
                } footer: {
                    HStack {
                        Spacer()
                        Text(L("categories_footer"))
                        Spacer()
                    }
                }
            }
            .navigationTitle(L("categories_title"))
        }
    }
}

// MARK: - Category Row View

struct CategoryRowView: View {
    let category: ExpenseCategory
    @State private var expenseStore = ExpenseStore.shared

    private var categoryTotal: Double {
        expenseStore.expensesByCategory[category] ?? 0
    }

    private var expenseCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        return expenseStore.expenses
            .filter { $0.category == category && $0.date >= startOfMonth }
            .count
    }

    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(categoryColor)
            }

            // Category Name and Count
            VStack(alignment: .leading, spacing: 4) {
                Text(category.localizedName)
                    .font(.headline)
                Text(LPlural("expenses_count", count: expenseCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Total Amount
            Text(expenseStore.formatCurrency(categoryTotal))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(categoryTotal > 0 ? .primary : .secondary)
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
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

// MARK: - Category Detail View

struct CategoryDetailView: View {
    let category: ExpenseCategory
    @State private var expenseStore = ExpenseStore.shared
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showingAddExpense = false
    @State private var showingPaywall = false
    @State private var budgetLimitString = ""
    @State private var isEditingBudget = false
    @FocusState private var isBudgetFocused: Bool

    private var categoryExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        return expenseStore.expenses
            .filter { $0.category == category && $0.date >= startOfMonth }
            .sorted { $0.date > $1.date }
    }

    private var categoryTotal: Double {
        categoryExpenses.reduce(0) { $0 + $1.amount }
    }

    private var budgetLimit: Double? {
        expenseStore.budget.budgetLimit(for: category)
    }

    private var budgetProgress: Double {
        expenseStore.categoryBudgetProgress(for: category)
    }

    private var isOverBudget: Bool {
        expenseStore.isCategoryOverBudget(category)
    }

    var body: some View {
        List {
            // Summary Section
            Section {
                HStack {
                    Text(L("total_spent"))
                    Spacer()
                    Text(expenseStore.formatCurrency(categoryTotal))
                        .fontWeight(.semibold)
                }

                HStack {
                    Text(LPlural("expenses_count", count: categoryExpenses.count))
                }
            }

            // Budget Section (Premium Feature)
            Section {
                if subscriptionManager.canAccessCategoryBudgets {
                    HStack {
                        Text(L("budget_limit"))
                        Spacer()
                        if isEditingBudget {
                            HStack {
                                Text(expenseStore.budget.currency.symbol)
                                    .foregroundStyle(.secondary)
                                TextField("0", text: $budgetLimitString)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .focused($isBudgetFocused)
                            }
                        } else {
                            Button {
                                budgetLimitString = budgetLimit.map { String(format: "%.0f", $0) } ?? ""
                                isEditingBudget = true
                                isBudgetFocused = true
                            } label: {
                                if let limit = budgetLimit {
                                    Text(expenseStore.formatCurrency(limit))
                                        .foregroundStyle(.primary)
                                } else {
                                    Text(L("no_limit_set"))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    if let limit = budgetLimit {
                        HStack {
                            ProgressView(value: min(budgetProgress, 1.0))
                                .tint(isOverBudget ? .red : .blue)

                            Text("\(expenseStore.formatCurrency(categoryTotal)) / \(expenseStore.formatCurrency(limit))")
                                .font(.caption)
                                .foregroundStyle(isOverBudget ? .red : .secondary)
                        }
                    }
                } else {
                    Button {
                        showingPaywall = true
                    } label: {
                        HStack {
                            Text(L("budget_limit"))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            } header: {
                HStack {
                    Text(L("budget"))
                    if !subscriptionManager.canAccessCategoryBudgets {
                        Text(L("premium"))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }
            } footer: {
                if subscriptionManager.canAccessCategoryBudgets {
                    Text(L("category_budget_detail_footer"))
                }
            }

            // Expenses Section
            Section {
                if categoryExpenses.isEmpty {
                    ContentUnavailableView {
                        Label(L("no_expenses_yet"), systemImage: "tray")
                    }
                } else {
                    ForEach(categoryExpenses) { expense in
                        ExpenseRowView(expense: expense)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    expenseStore.deleteExpense(expense)
                                } label: {
                                    Label(L("delete"), systemImage: "trash")
                                }
                            }
                    }
                }
            } header: {
                Text(L("recent_expenses"))
            }
        }
        .navigationTitle(category.localizedName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onChange(of: isBudgetFocused) { _, focused in
            if !focused && isEditingBudget {
                saveBudgetLimit()
            }
        }
    }

    private func saveBudgetLimit() {
        isEditingBudget = false
        let cleaned = budgetLimitString.replacingOccurrences(of: ",", with: ".")
        if let value = Double(cleaned), value > 0 {
            expenseStore.setCategoryBudget(value, for: category)
        } else if budgetLimitString.isEmpty {
            expenseStore.setCategoryBudget(nil, for: category)
        }
    }
}

#Preview {
    CategoriesView()
}
