//
//  EditExpenseView.swift
//  BudgetPulse
//

import SwiftUI
import PhotosUI

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expenseStore = ExpenseStore.shared

    let expense: Expense

    @State private var title: String
    @State private var amountString: String
    @State private var selectedCategory: ExpenseCategory
    @State private var date: Date
    @State private var notes: String
    @State private var isRecurring: Bool
    @State private var recurrenceType: RecurrenceType
    @State private var receiptImage: UIImage?
    @State private var existingReceiptPath: String?

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false

    init(expense: Expense) {
        self.expense = expense
        _title = State(initialValue: expense.title)
        _amountString = State(initialValue: String(format: "%.2f", expense.amount))
        _selectedCategory = State(initialValue: expense.category)
        _date = State(initialValue: expense.date)
        _notes = State(initialValue: expense.notes ?? "")
        _isRecurring = State(initialValue: expense.isRecurring)
        _recurrenceType = State(initialValue: expense.recurrenceType ?? .monthly)
        _existingReceiptPath = State(initialValue: expense.receiptImagePath)
    }

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

                // Receipt Section
                Section {
                    if let path = existingReceiptPath, receiptImage == nil {
                        ReceiptImageViewer(filename: path)

                        Button(role: .destructive) {
                            ImageStorageManager.shared.deleteImage(filename: path)
                            existingReceiptPath = nil
                        } label: {
                            Label(L("remove_receipt"), systemImage: "trash")
                        }
                    } else {
                        ReceiptImagePicker(selectedImage: $receiptImage)
                    }
                } header: {
                    Text(L("receipt"))
                }

                // Notes Section
                Section {
                    TextField(L("notes_placeholder"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text(L("notes"))
                }
            }
            .navigationTitle(L("edit_expense"))
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
            .alert(L("expense_updated_success"), isPresented: $showingSuccess) {
                Button(L("ok"), role: .cancel) {
                    dismiss()
                }
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

        var receiptPath = existingReceiptPath

        // Save new receipt image if present
        if let image = receiptImage {
            // Delete old image if exists
            if let oldPath = existingReceiptPath {
                ImageStorageManager.shared.deleteImage(filename: oldPath)
            }
            receiptPath = ImageStorageManager.shared.saveImage(image, for: expense.id)
        }

        let updatedExpense = Expense(
            id: expense.id,
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

        expenseStore.updateExpense(updatedExpense)
        showingSuccess = true
    }
}

#Preview {
    EditExpenseView(expense: Expense(title: "Coffee", amount: 5.50, category: .food))
}
