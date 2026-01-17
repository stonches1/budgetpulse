//
//  SavingsGoalDetailView.swift
//  BudgetPulse
//

import SwiftUI

struct SavingsGoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expenseStore = ExpenseStore.shared
    let goal: SavingsGoal

    @State private var showingAddContribution = false
    @State private var contributionAmountString = ""
    @State private var contributionNotes = ""

    private var currentGoal: SavingsGoal? {
        expenseStore.savingsGoals.first { $0.id == goal.id }
    }

    var body: some View {
        List {
            if let goal = currentGoal {
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                                .frame(width: 120, height: 120)

                            Circle()
                                .trim(from: 0, to: goal.progress)
                                .stroke(Color(goal.color), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: goal.progress)

                            VStack {
                                Image(systemName: goal.icon)
                                    .font(.title)
                                    .foregroundStyle(Color(goal.color))
                                Text("\(Int(goal.progress * 100))%")
                                    .font(.headline)
                            }
                        }

                        VStack(spacing: 4) {
                            Text(expenseStore.formatCurrency(goal.currentAmount))
                                .font(.title)
                                .fontWeight(.bold)
                            Text("\(L("of")) \(expenseStore.formatCurrency(goal.targetAmount))")
                                .foregroundStyle(.secondary)
                        }

                        if goal.isCompleted {
                            Label(L("goal_completed"), systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }

                Section {
                    HStack {
                        Text(L("remaining"))
                        Spacer()
                        Text(expenseStore.formatCurrency(goal.remainingAmount))
                            .fontWeight(.medium)
                    }

                    if let daysRemaining = goal.daysRemaining {
                        HStack {
                            Text(L("days_left"))
                            Spacer()
                            Text("\(daysRemaining)")
                                .fontWeight(.medium)
                                .foregroundStyle(daysRemaining < 30 ? .orange : .primary)
                        }
                    }

                    if let suggested = goal.suggestedMonthlyContribution {
                        HStack {
                            Text(L("suggested_monthly"))
                            Spacer()
                            Text(expenseStore.formatCurrency(suggested))
                                .fontWeight(.medium)
                        }
                    }
                }

                if !goal.isCompleted {
                    Section {
                        Button {
                            showingAddContribution = true
                        } label: {
                            Label(L("add_contribution"), systemImage: "plus.circle.fill")
                        }
                    }
                }

                if !goal.contributions.isEmpty {
                    Section {
                        ForEach(goal.contributions.sorted { $0.date > $1.date }) { contribution in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("+\(expenseStore.formatCurrency(contribution.amount))")
                                        .fontWeight(.medium)
                                        .foregroundStyle(.green)
                                    if let notes = contribution.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(expenseStore.formatDate(contribution.date, style: .short))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { offsets in
                            for offset in offsets {
                                let sortedContributions = goal.contributions.sorted { $0.date > $1.date }
                                let contribution = sortedContributions[offset]
                                expenseStore.removeContribution(contribution.id, from: goal.id)
                            }
                        }
                    } header: {
                        Text(L("contribution_history"))
                    }
                }
            }
        }
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L("add_contribution"), isPresented: $showingAddContribution) {
            TextField(L("amount"), text: $contributionAmountString)
                .keyboardType(.decimalPad)
            TextField(L("notes_optional"), text: $contributionNotes)
            Button(L("cancel"), role: .cancel) {
                contributionAmountString = ""
                contributionNotes = ""
            }
            Button(L("add")) {
                addContribution()
            }
        }
    }

    private func addContribution() {
        let cleaned = contributionAmountString.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleaned), amount > 0 else {
            contributionAmountString = ""
            contributionNotes = ""
            return
        }

        expenseStore.addContribution(amount, to: goal.id, notes: contributionNotes.isEmpty ? nil : contributionNotes)
        contributionAmountString = ""
        contributionNotes = ""
    }
}

#Preview {
    NavigationStack {
        SavingsGoalDetailView(goal: SavingsGoal(title: "Vacation", targetAmount: 5000, currentAmount: 2500))
    }
}
