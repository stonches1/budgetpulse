//
//  CategoryBudgetSettingsView.swift
//  BudgetPulse
//

import SwiftUI

struct CategoryBudgetSettingsView: View {
    @State private var expenseStore = ExpenseStore.shared
    @State private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        Group {
            if subscriptionManager.canAccessCategoryBudgets {
                List {
                    Section {
                        ForEach(ExpenseCategory.allCases) { category in
                            CategoryBudgetRow(category: category)
                        }
                    } header: {
                        Text(L("category_budget_limit"))
                    } footer: {
                        Text(L("category_budget_footer"))
                    }
                }
            } else {
                PremiumFeatureLockView(feature: L("category_budgets"))
            }
        }
        .navigationTitle(L("category_budgets"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $subscriptionManager.showingPaywall) {
            PaywallView()
        }
    }
}

struct CategoryBudgetRow: View {
    @State private var expenseStore = ExpenseStore.shared
    let category: ExpenseCategory

    @State private var limitString: String = ""
    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    var spent: Double {
        expenseStore.categorySpentThisMonth(for: category)
    }

    var limit: Double? {
        expenseStore.budget.budgetLimit(for: category)
    }

    var progress: Double {
        expenseStore.categoryBudgetProgress(for: category)
    }

    var isOverBudget: Bool {
        expenseStore.isCategoryOverBudget(category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(Color(category.color))
                    .frame(width: 24)

                Text(category.localizedName)
                    .fontWeight(.medium)

                Spacer()

                if isEditing {
                    HStack {
                        Text(expenseStore.budget.currency.symbol)
                            .foregroundStyle(.secondary)
                        TextField("0", text: $limitString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .focused($isFocused)
                    }
                } else {
                    Button {
                        limitString = limit.map { String(format: "%.0f", $0) } ?? ""
                        isEditing = true
                        isFocused = true
                    } label: {
                        if let limit = limit {
                            Text(expenseStore.formatCurrency(limit))
                                .foregroundStyle(.primary)
                        } else {
                            Text(L("no_limit_set"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let limit = limit {
                HStack {
                    ProgressView(value: min(progress, 1.0))
                        .tint(isOverBudget ? .red : .blue)

                    Text("\(expenseStore.formatCurrency(spent)) / \(expenseStore.formatCurrency(limit))")
                        .font(.caption)
                        .foregroundStyle(isOverBudget ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .onChange(of: isFocused) { _, focused in
            if !focused && isEditing {
                saveLimit()
            }
        }
    }

    private func saveLimit() {
        isEditing = false
        let cleaned = limitString.replacingOccurrences(of: ",", with: ".")
        if let value = Double(cleaned), value > 0 {
            expenseStore.setCategoryBudget(value, for: category)
        } else if limitString.isEmpty {
            expenseStore.setCategoryBudget(nil, for: category)
        }
    }
}

#Preview {
    NavigationStack {
        CategoryBudgetSettingsView()
    }
}
