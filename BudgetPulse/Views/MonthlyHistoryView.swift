//
//  MonthlyHistoryView.swift
//  BudgetPulse
//

import SwiftUI

struct MonthlyHistoryView: View {
    @State private var expenseStore = ExpenseStore.shared
    @State private var selectedMonth: Date?
    @State private var expenseToEdit: Expense?
    @State private var expenseToDelete: Expense?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                if expenseStore.availableMonths.isEmpty {
                    ContentUnavailableView {
                        Label(L("no_history"), systemImage: "calendar")
                    } description: {
                        Text(L("no_history_description"))
                    }
                } else {
                    ForEach(expenseStore.availableMonths, id: \.self) { month in
                        NavigationLink {
                            MonthDetailView(month: month)
                        } label: {
                            MonthRowView(month: month)
                        }
                    }
                }
            }
            .navigationTitle(L("monthly_history"))
        }
    }
}

// MARK: - Month Row View

struct MonthRowView: View {
    let month: Date
    @State private var expenseStore = ExpenseStore.shared

    private var expenseCount: Int {
        expenseStore.expenses(for: month).count
    }

    private var totalSpent: Double {
        expenseStore.totalSpent(for: month)
    }

    private var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        return calendar.isDate(month, equalTo: now, toGranularity: .month)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expenseStore.formatMonthYear(month))
                        .font(.headline)
                    if isCurrentMonth {
                        Text(L("current_month"))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
                Text(LPlural("expenses_count", count: expenseCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(expenseStore.formatCurrency(totalSpent))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Month Detail View

struct MonthDetailView: View {
    let month: Date
    @State private var expenseStore = ExpenseStore.shared
    @State private var expenseToEdit: Expense?
    @State private var expenseToDelete: Expense?
    @State private var showingDeleteConfirmation = false

    private var monthExpenses: [Expense] {
        expenseStore.expenses(for: month)
    }

    private var expensesByCategory: [ExpenseCategory: Double] {
        var result: [ExpenseCategory: Double] = [:]
        for expense in monthExpenses {
            result[expense.category, default: 0] += expense.amount
        }
        return result
    }

    var body: some View {
        List {
            // Summary Section
            Section {
                HStack {
                    Text(L("total_spent"))
                    Spacer()
                    Text(expenseStore.formatCurrency(expenseStore.totalSpent(for: month)))
                        .fontWeight(.semibold)
                }

                HStack {
                    Text(LPlural("expenses_count", count: monthExpenses.count))
                }
            }

            // Category Breakdown
            if !expensesByCategory.isEmpty {
                Section {
                    ForEach(Array(expensesByCategory.sorted { $0.value > $1.value }), id: \.key) { category, amount in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundStyle(categoryColor(category))
                                .frame(width: 24)
                            Text(category.localizedName)
                            Spacer()
                            Text(expenseStore.formatCurrency(amount))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(L("spending_by_category"))
                }
            }

            // Expenses List
            Section {
                if monthExpenses.isEmpty {
                    ContentUnavailableView {
                        Label(L("no_expenses_yet"), systemImage: "tray")
                    }
                } else {
                    ForEach(monthExpenses) { expense in
                        ExpenseRowView(expense: expense)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                expenseToEdit = expense
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    expenseToDelete = expense
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label(L("delete"), systemImage: "trash")
                                }

                                Button {
                                    expenseToEdit = expense
                                } label: {
                                    Label(L("edit"), systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            } header: {
                Text(L("all_expenses"))
            }
        }
        .navigationTitle(expenseStore.formatMonthYear(month))
        .sheet(item: $expenseToEdit) { expense in
            EditExpenseView(expense: expense)
        }
        .alert(L("delete_expense_title"), isPresented: $showingDeleteConfirmation) {
            Button(L("cancel"), role: .cancel) {
                expenseToDelete = nil
            }
            Button(L("delete"), role: .destructive) {
                if let expense = expenseToDelete {
                    expenseStore.deleteExpense(expense)
                    expenseToDelete = nil
                }
            }
        } message: {
            Text(L("delete_expense_message"))
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
}

#Preview {
    MonthlyHistoryView()
}
