//
//  AddIncomeView.swift
//  BudgetPulse
//

import SwiftUI

struct AddIncomeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expenseStore = ExpenseStore.shared

    @State private var title = ""
    @State private var amountString = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var recurrenceType: RecurrenceType = .monthly

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L("income_title_placeholder"), text: $title)
                } header: {
                    Text(L("income_title"))
                }

                Section {
                    HStack {
                        Text(expenseStore.budget.currency.symbol)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountString)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text(L("amount"))
                }

                Section {
                    DatePicker(
                        L("date"),
                        selection: $date,
                        displayedComponents: .date
                    )
                    .environment(\.locale, LanguageManager.shared.effectiveLocale)
                }

                Section {
                    Toggle(L("is_recurring"), isOn: $isRecurring)

                    if isRecurring {
                        Picker(L("recurrence_type"), selection: $recurrenceType) {
                            ForEach(RecurrenceType.allCases) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.localizedName)
                                }
                                .tag(type)
                            }
                        }
                    }
                }

                Section {
                    TextField(L("notes_placeholder"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text(L("notes"))
                }
            }
            .navigationTitle(L("add_income"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("save")) {
                        saveIncome()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(L("error"), isPresented: $showingError) {
                Button(L("ok"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert(L("income_added_success"), isPresented: $showingSuccess) {
                Button(L("ok"), role: .cancel) {
                    dismiss()
                }
            }
        }
    }

    private func saveIncome() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = L("error_empty_title")
            showingError = true
            return
        }

        let cleanedAmount = amountString.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleanedAmount), amount > 0 else {
            errorMessage = L("error_invalid_amount")
            showingError = true
            return
        }

        let income = Income(
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amount,
            date: date,
            isRecurring: isRecurring,
            recurrenceType: isRecurring ? recurrenceType : nil,
            notes: notes.isEmpty ? nil : notes
        )

        expenseStore.addIncome(income)
        showingSuccess = true
    }
}

#Preview {
    AddIncomeView()
}
