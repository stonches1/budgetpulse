//
//  AddSavingsGoalView.swift
//  BudgetPulse
//

import SwiftUI

struct AddSavingsGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expenseStore = ExpenseStore.shared

    @State private var title = ""
    @State private var targetAmountString = ""
    @State private var hasTargetDate = false
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var selectedIcon: GoalIcon = .star
    @State private var selectedColor: GoalColor = .blue

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L("goal_title_placeholder"), text: $title)
                } header: {
                    Text(L("goal_title"))
                }

                Section {
                    HStack {
                        Text(expenseStore.budget.currency.symbol)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $targetAmountString)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text(L("target_amount"))
                }

                Section {
                    Toggle(L("has_target_date"), isOn: $hasTargetDate)

                    if hasTargetDate {
                        DatePicker(
                            L("target_date"),
                            selection: $targetDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .environment(\.locale, LanguageManager.shared.effectiveLocale)
                    }
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(GoalIcon.allCases) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon.rawValue)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color(selectedColor.rawValue).opacity(0.2) : Color.gray.opacity(0.1))
                                    .foregroundStyle(selectedIcon == icon ? Color(selectedColor.rawValue) : .gray)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(L("icon"))
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(GoalColor.allCases) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(color.rawValue))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(L("color"))
                }
            }
            .navigationTitle(L("add_goal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("save")) {
                        saveGoal()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(L("error"), isPresented: $showingError) {
                Button(L("ok"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert(L("goal_added_success"), isPresented: $showingSuccess) {
                Button(L("ok"), role: .cancel) {
                    dismiss()
                }
            }
        }
    }

    private func saveGoal() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = L("error_empty_title")
            showingError = true
            return
        }

        let cleanedAmount = targetAmountString.replacingOccurrences(of: ",", with: ".")
        guard let targetAmount = Double(cleanedAmount), targetAmount > 0 else {
            errorMessage = L("error_invalid_amount")
            showingError = true
            return
        }

        let goal = SavingsGoal(
            title: title.trimmingCharacters(in: .whitespaces),
            targetAmount: targetAmount,
            targetDate: hasTargetDate ? targetDate : nil,
            icon: selectedIcon.rawValue,
            color: selectedColor.rawValue
        )

        expenseStore.addSavingsGoal(goal)
        showingSuccess = true
    }
}

#Preview {
    AddSavingsGoalView()
}
