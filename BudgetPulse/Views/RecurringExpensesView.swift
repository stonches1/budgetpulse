//
//  RecurringExpensesView.swift
//  BudgetPulse
//

import SwiftUI

struct RecurringExpensesView: View {
    @State private var expenseStore = ExpenseStore.shared
    @State private var showingAddExpense = false

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text(L("monthly_subscriptions_total"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(expenseStore.formatCurrency(expenseStore.monthlySubscriptionsTotal))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Text(L("per_month"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if !expenseStore.upcomingRecurringExpenses.isEmpty {
                Section {
                    ForEach(expenseStore.upcomingRecurringExpenses) { expense in
                        RecurringExpenseRow(expense: expense, showDueDate: true)
                    }
                } header: {
                    Text(L("upcoming_bills"))
                }
            }

            Section {
                if expenseStore.recurringExpenses.isEmpty {
                    ContentUnavailableView {
                        Label(L("no_recurring_expenses"), systemImage: "repeat.circle")
                    } description: {
                        Text(L("no_recurring_description"))
                    }
                } else {
                    ForEach(expenseStore.recurringExpenses) { expense in
                        RecurringExpenseRow(expense: expense, showDueDate: false)
                    }
                    .onDelete { offsets in
                        expenseStore.deleteExpenses(at: offsets, from: expenseStore.recurringExpenses)
                    }
                }
            } header: {
                HStack {
                    Text(L("all_subscriptions"))
                    Spacer()
                    Text("\(expenseStore.recurringExpenses.count) \(L("items"))")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(L("recurring_expenses"))
        .navigationBarTitleDisplayMode(.inline)
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
    }
}

struct RecurringExpenseRow: View {
    @State private var expenseStore = ExpenseStore.shared
    let expense: Expense
    let showDueDate: Bool

    var body: some View {
        HStack {
            Image(systemName: expense.category.icon)
                .foregroundStyle(Color(expense.category.color))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    if let recurrence = expense.recurrenceType {
                        Text(recurrence.localizedName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if showDueDate, let dueDate = expense.nextDueDate {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(L("due") + " " + expenseStore.formatDate(dueDate, style: .short))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(expenseStore.formatCurrency(expense.amount))
                    .fontWeight(.semibold)

                if let recurrence = expense.recurrenceType {
                    let monthly = expense.amount * recurrence.monthlyMultiplier
                    if recurrence != .monthly {
                        Text("~\(expenseStore.formatCurrency(monthly))/\(L("mo"))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .leading) {
            Button {
                expenseStore.markRecurringExpensePaid(expense)
            } label: {
                Label(L("mark_paid"), systemImage: "checkmark.circle")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing) {
            Button {
                expenseStore.skipRecurringExpense(expense)
            } label: {
                Label(L("skip"), systemImage: "forward")
            }
            .tint(.orange)
        }
    }
}

#Preview {
    NavigationStack {
        RecurringExpensesView()
    }
}
