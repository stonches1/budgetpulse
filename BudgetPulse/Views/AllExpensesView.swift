//
//  AllExpensesView.swift
//  BudgetPulse
//

import SwiftUI

struct AllExpensesView: View {
    @State private var expenseStore = ExpenseStore.shared
    @State private var showingAddExpense = false
    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var expenseToEdit: Expense?
    @State private var expenseToDelete: Expense?
    @State private var showingDeleteConfirmation = false
    @State private var dateFilter: DateFilter = .thisMonth
    @State private var showingDateFilter = false

    private var baseExpenses: [Expense] {
        expenseStore.expenses(for: dateFilter)
    }

    private var filteredExpenses: [Expense] {
        var result = baseExpenses

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { expense in
                expense.title.localizedCaseInsensitiveContains(searchText) ||
                expense.category.localizedName.localizedCaseInsensitiveContains(searchText) ||
                (expense.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        return result
    }

    var body: some View {
        List {
            if expenseStore.thisMonthExpenses.isEmpty {
                ContentUnavailableView {
                    Label(L("no_expenses_yet"), systemImage: "tray")
                } description: {
                    Text(L("track_spending_subtitle"))
                }
            } else if filteredExpenses.isEmpty {
                ContentUnavailableView {
                    Label(L("no_results"), systemImage: "magnifyingglass")
                } description: {
                    Text(L("no_results_description"))
                }
            } else {
                // Category Filter
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: L("all_categories"),
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }

                            ForEach(ExpenseCategory.allCases) { category in
                                FilterChip(
                                    title: category.localizedName,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Expenses List
                Section {
                    ForEach(filteredExpenses) { expense in
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
                } header: {
                    Text(LPlural("expenses_count", count: filteredExpenses.count))
                }
            }
        }
        .searchable(text: $searchText, prompt: Text(L("search_expenses")))
        .navigationTitle(L("all_expenses"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingDateFilter = true
                } label: {
                    Label(dateFilter.localizedName, systemImage: "calendar")
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
        }
        .sheet(isPresented: $showingDateFilter) {
            DateFilterView(selectedFilter: $dateFilter)
        }
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
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AllExpensesView()
    }
}
