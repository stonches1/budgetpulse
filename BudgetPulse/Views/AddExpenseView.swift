//
//  AddExpenseView.swift
//  BudgetPulse
//

import SwiftUI
import PhotosUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expenseStore = ExpenseStore.shared
    @State private var subscriptionManager = SubscriptionManager.shared

    @State private var title = ""
    @State private var amountString = ""
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var date = Date()
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var recurrenceType: RecurrenceType = .monthly
    @State private var receiptImage: UIImage?

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                // Title Section
                Section {
                    TextField(L("expense_title_placeholder"), text: $title)
                } header: {
                    Text(L("expense_title"))
                }

                // Amount Section
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

                // Category Section
                Section {
                    Picker(selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.localizedName)
                            }
                            .tag(category)
                        }
                    } label: {
                        Text(L("category"))
                    }
                }

                // Date Section
                Section {
                    DatePicker(
                        L("date"),
                        selection: $date,
                        displayedComponents: .date
                    )
                    .environment(\.locale, LanguageManager.shared.effectiveLocale)
                }

                // Recurring Section
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
                } footer: {
                    if isRecurring {
                        Text(L("recurring_expense_footer"))
                    }
                }

                // Receipt Section (Premium Feature)
                Section {
                    if subscriptionManager.canAccessReceipts {
                        ReceiptImagePicker(selectedImage: $receiptImage)
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(.orange)
                                Text(L("receipt_premium_feature"))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(L("receipt"))
                        if !subscriptionManager.canAccessReceipts {
                            Text(L("premium"))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Notes Section
                Section {
                    TextField(L("notes_placeholder"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text(L("notes"))
                }
            }
            .navigationTitle(L("add_expense"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("save")) {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(L("error_invalid_amount"), isPresented: $showingError) {
                Button(L("ok"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert(L("expense_added_success"), isPresented: $showingSuccess) {
                Button(L("ok"), role: .cancel) {
                    dismiss()
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private func saveExpense() {
        // Validate title
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = L("error_empty_title")
            showingError = true
            return
        }

        // Validate and parse amount
        let cleanedAmount = amountString.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleanedAmount), amount > 0 else {
            errorMessage = L("error_invalid_amount")
            showingError = true
            return
        }

        let expenseId = UUID()
        var receiptPath: String?

        // Save receipt image if present
        if let image = receiptImage {
            receiptPath = ImageStorageManager.shared.saveImage(image, for: expenseId)
        }

        let expense = Expense(
            id: expenseId,
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amount,
            category: selectedCategory,
            date: date,
            notes: notes.isEmpty ? nil : notes,
            isRecurring: isRecurring,
            recurrenceType: isRecurring ? recurrenceType : nil,
            nextDueDate: isRecurring ? recurrenceType.nextDate(from: date) : nil,
            receiptImagePath: receiptPath
        )

        expenseStore.addExpense(expense)

        // Check for budget alerts
        NotificationManager.shared.checkAndSendBudgetAlert()

        showingSuccess = true
    }
}

#Preview {
    AddExpenseView()
}
