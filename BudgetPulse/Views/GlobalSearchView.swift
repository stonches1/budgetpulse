//
//  GlobalSearchView.swift
//  BudgetPulse
//

import SwiftUI

struct GlobalSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expenseStore = ExpenseStore.shared
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Chips
                filterChips
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Divider()

                // Results
                if searchText.isEmpty {
                    recentSearchesView
                } else if filteredResults.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .navigationTitle(L("search"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, isPresented: .constant(true), prompt: Text(L("search_placeholder")))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isSearchFocused = true
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: filter.icon)
                                .font(.caption)
                            Text(filter.localizedName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedFilter == filter ? Color.blue : Color(.systemGray5))
                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Recent Searches View

    private var recentSearchesView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(L("search_hint"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(L("no_results"))
                .font(.headline)

            Text(L("no_results_description"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            // Expenses Section
            if !filteredExpenses.isEmpty {
                Section {
                    ForEach(filteredExpenses.prefix(10)) { expense in
                        SearchResultRow(
                            title: expense.title,
                            subtitle: expense.category.localizedName,
                            detail: expenseStore.formatCurrency(expense.amount),
                            date: expense.date,
                            icon: expense.category.icon,
                            iconColor: categoryColor(expense.category),
                            type: .expense
                        )
                    }
                } header: {
                    HStack {
                        Text(L("expenses"))
                        Spacer()
                        if filteredExpenses.count > 10 {
                            Text("+\(filteredExpenses.count - 10) " + L("more"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Income Section
            if !filteredIncomes.isEmpty {
                Section {
                    ForEach(filteredIncomes.prefix(10)) { income in
                        SearchResultRow(
                            title: income.title,
                            subtitle: L("income"),
                            detail: expenseStore.formatCurrency(income.amount),
                            date: income.date,
                            icon: "arrow.down.circle.fill",
                            iconColor: .green,
                            type: .income
                        )
                    }
                } header: {
                    HStack {
                        Text(L("income"))
                        Spacer()
                        if filteredIncomes.count > 10 {
                            Text("+\(filteredIncomes.count - 10) " + L("more"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Savings Goals Section
            if !filteredGoals.isEmpty {
                Section {
                    ForEach(filteredGoals.prefix(10)) { goal in
                        SearchResultRow(
                            title: goal.title,
                            subtitle: String(format: "%.0f%% " + L("complete"), goal.progress * 100),
                            detail: expenseStore.formatCurrency(goal.targetAmount),
                            date: nil,
                            icon: goal.icon,
                            iconColor: goalColor(goal.color),
                            type: .goal
                        )
                    }
                } header: {
                    HStack {
                        Text(L("savings_goals"))
                        Spacer()
                        if filteredGoals.count > 10 {
                            Text("+\(filteredGoals.count - 10) " + L("more"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Filtered Results

    private var filteredResults: [Any] {
        var results: [Any] = []
        results.append(contentsOf: filteredExpenses as [Any])
        results.append(contentsOf: filteredIncomes as [Any])
        results.append(contentsOf: filteredGoals as [Any])
        return results
    }

    private var filteredExpenses: [Expense] {
        guard selectedFilter == .all || selectedFilter == .expenses else { return [] }
        guard !searchText.isEmpty else { return [] }

        return expenseStore.expenses.filter { expense in
            expense.title.localizedCaseInsensitiveContains(searchText) ||
            expense.category.localizedName.localizedCaseInsensitiveContains(searchText) ||
            (expense.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        .sorted { $0.date > $1.date }
    }

    private var filteredIncomes: [Income] {
        guard selectedFilter == .all || selectedFilter == .income else { return [] }
        guard !searchText.isEmpty else { return [] }

        return expenseStore.incomes.filter { income in
            income.title.localizedCaseInsensitiveContains(searchText) ||
            (income.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        .sorted { $0.date > $1.date }
    }

    private var filteredGoals: [SavingsGoal] {
        guard selectedFilter == .all || selectedFilter == .goals else { return [] }
        guard !searchText.isEmpty else { return [] }

        return expenseStore.savingsGoals.filter { goal in
            goal.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Helper Functions

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

    private func goalColor(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "yellow": return .yellow
        case "cyan": return .cyan
        default: return .blue
        }
    }
}

// MARK: - Search Filter

enum SearchFilter: String, CaseIterable, Identifiable {
    case all
    case expenses
    case income
    case goals

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .all: return L("all")
        case .expenses: return L("expenses")
        case .income: return L("income")
        case .goals: return L("goals")
        }
    }

    var icon: String {
        switch self {
        case .all: return "magnifyingglass"
        case .expenses: return "arrow.up.circle"
        case .income: return "arrow.down.circle"
        case .goals: return "star.circle"
        }
    }
}

// MARK: - Search Result Type

enum SearchResultType {
    case expense, income, goal
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let title: String
    let subtitle: String
    let detail: String
    let date: Date?
    let icon: String
    let iconColor: Color
    let type: SearchResultType

    @State private var expenseStore = ExpenseStore.shared

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let date = date {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(expenseStore.formatDate(date, style: .short))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text(detail)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(type == .income ? .green : .primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GlobalSearchView()
}
