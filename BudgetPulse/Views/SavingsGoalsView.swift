//
//  SavingsGoalsView.swift
//  BudgetPulse
//

import SwiftUI

struct SavingsGoalsView: View {
    @State private var expenseStore = ExpenseStore.shared
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showingAddGoal = false
    @State private var showingPaywall = false

    private var canAddMoreGoals: Bool {
        subscriptionManager.canAddMoreSavingsGoals(currentCount: expenseStore.savingsGoals.count)
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text(L("total_saved"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(expenseStore.formatCurrency(expenseStore.totalSavings))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(expenseStore.activeSavingsGoals.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(L("active_goals"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if !expenseStore.activeSavingsGoals.isEmpty {
                Section {
                    ForEach(expenseStore.activeSavingsGoals) { goal in
                        NavigationLink(destination: SavingsGoalDetailView(goal: goal)) {
                            SavingsGoalRow(goal: goal)
                        }
                    }
                    .onDelete { offsets in
                        for offset in offsets {
                            let goal = expenseStore.activeSavingsGoals[offset]
                            expenseStore.deleteSavingsGoal(goal)
                        }
                    }
                } header: {
                    Text(L("active_goals"))
                }
            }

            if !expenseStore.completedSavingsGoals.isEmpty {
                Section {
                    ForEach(expenseStore.completedSavingsGoals) { goal in
                        NavigationLink(destination: SavingsGoalDetailView(goal: goal)) {
                            SavingsGoalRow(goal: goal)
                        }
                    }
                    .onDelete { offsets in
                        for offset in offsets {
                            let goal = expenseStore.completedSavingsGoals[offset]
                            expenseStore.deleteSavingsGoal(goal)
                        }
                    }
                } header: {
                    Text(L("completed_goals"))
                }
            }

            if expenseStore.savingsGoals.isEmpty {
                ContentUnavailableView {
                    Label(L("no_goals_yet"), systemImage: "star.circle")
                } description: {
                    Text(L("no_goals_description"))
                }
            }
        }
        .navigationTitle(L("savings_goals"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if canAddMoreGoals {
                        showingAddGoal = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddSavingsGoalView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

struct SavingsGoalRow: View {
    @State private var expenseStore = ExpenseStore.shared
    let goal: SavingsGoal

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: goal.progress)
                    .stroke(Color(goal.color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Image(systemName: goal.icon)
                    .foregroundStyle(Color(goal.color))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(goal.title)
                        .fontWeight(.medium)

                    if goal.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                Text("\(expenseStore.formatCurrency(goal.currentAmount)) / \(expenseStore.formatCurrency(goal.targetAmount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let daysRemaining = goal.daysRemaining, !goal.isCompleted {
                    Text("\(daysRemaining) \(L("days_remaining"))")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Text("\(Int(goal.progress * 100))%")
                .font(.headline)
                .foregroundStyle(goal.isCompleted ? .green : .primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SavingsGoalsView()
    }
}
