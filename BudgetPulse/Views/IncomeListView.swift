//
//  IncomeListView.swift
//  BudgetPulse
//

import SwiftUI

struct IncomeListView: View {
    @State private var expenseStore = ExpenseStore.shared
    @State private var showingAddIncome = false
    @State private var selectedFilter: DateFilter = .thisMonth

    var filteredIncomes: [Income] {
        expenseStore.incomes(for: selectedFilter)
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text(L("total_income"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(expenseStore.formatCurrency(expenseStore.totalIncome(for: selectedFilter)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Section {
                if filteredIncomes.isEmpty {
                    ContentUnavailableView {
                        Label(L("no_income_yet"), systemImage: "dollarsign.circle")
                    } description: {
                        Text(L("no_income_description"))
                    }
                } else {
                    ForEach(filteredIncomes) { income in
                        IncomeRowView(income: income)
                    }
                    .onDelete { offsets in
                        expenseStore.deleteIncomes(at: offsets, from: filteredIncomes)
                    }
                }
            } header: {
                HStack {
                    Text(selectedFilter.localizedName)
                    Spacer()
                    Text("\(filteredIncomes.count) \(L("items"))")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(L("income"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddIncome = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    ForEach(DateFilter.allCases) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            if selectedFilter == filter {
                                Label(filter.localizedName, systemImage: "checkmark")
                            } else {
                                Text(filter.localizedName)
                            }
                        }
                    }
                } label: {
                    Label(L("filter"), systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddIncome) {
            AddIncomeView()
        }
    }
}

struct IncomeRowView: View {
    @State private var expenseStore = ExpenseStore.shared
    let income: Income

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(income.title)
                        .fontWeight(.medium)

                    if income.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                Text(expenseStore.formatDate(income.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("+\(expenseStore.formatCurrency(income.amount))")
                .fontWeight(.semibold)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        IncomeListView()
    }
}
