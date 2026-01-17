//
//  SubscriptionsView.swift
//  BudgetPulse
//

import SwiftUI

struct SubscriptionsView: View {
    @State private var expenseStore = ExpenseStore.shared
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showingAddSubscription = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if subscriptionManager.canAccessSubscriptionTracker {
                    subscriptionContent
                } else {
                    PremiumFeatureLockView(feature: L("subscriptions"))
                }
            }
            .navigationTitle(L("subscriptions"))
        }
        .sheet(isPresented: $showingAddSubscription) {
            AddSubscriptionView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private var subscriptionContent: some View {
        List {
            // Summary Section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("monthly_cost"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(expenseStore.formatCurrency(expenseStore.totalMonthlySubscriptions))
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(L("yearly_cost"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(expenseStore.formatCurrency(expenseStore.totalYearlySubscriptions))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 8)
            }

            // Upcoming Payments
            if !expenseStore.upcomingSubscriptions.isEmpty {
                Section {
                    ForEach(expenseStore.upcomingSubscriptions) { subscription in
                        SubscriptionRowView(subscription: subscription, showDueDate: true)
                    }
                } header: {
                    HStack {
                        Text(L("upcoming_payments"))
                        Spacer()
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
            }

            // Active Subscriptions
            Section {
                if expenseStore.activeSubscriptions.isEmpty {
                    ContentUnavailableView {
                        Label(L("no_subscriptions"), systemImage: "creditcard")
                    } description: {
                        Text(L("add_subscription_prompt"))
                    }
                } else {
                    ForEach(expenseStore.activeSubscriptions) { subscription in
                        NavigationLink {
                            SubscriptionDetailView(subscription: subscription)
                        } label: {
                            SubscriptionRowView(subscription: subscription)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                expenseStore.deleteSubscription(subscription)
                            } label: {
                                Label(L("delete"), systemImage: "trash")
                            }

                            Button {
                                expenseStore.toggleSubscriptionActive(subscription)
                            } label: {
                                Label(L("pause"), systemImage: "pause.circle")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                expenseStore.markSubscriptionPaid(subscription)
                            } label: {
                                Label(L("mark_paid"), systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                    }
                }
            } header: {
                Text(L("active_subscriptions"))
            }

            // Paused Subscriptions
            let pausedSubscriptions = expenseStore.subscriptions.filter { !$0.isActive }
            if !pausedSubscriptions.isEmpty {
                Section {
                    ForEach(pausedSubscriptions) { subscription in
                        SubscriptionRowView(subscription: subscription, isPaused: true)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    expenseStore.deleteSubscription(subscription)
                                } label: {
                                    Label(L("delete"), systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    expenseStore.toggleSubscriptionActive(subscription)
                                } label: {
                                    Label(L("resume"), systemImage: "play.circle")
                                }
                                .tint(.green)
                            }
                    }
                } header: {
                    Text(L("paused_subscriptions"))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSubscription = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// MARK: - Subscription Row View

struct SubscriptionRowView: View {
    let subscription: Subscription
    var showDueDate: Bool = false
    var isPaused: Bool = false
    @State private var expenseStore = ExpenseStore.shared

    private var categoryColor: Color {
        switch subscription.category.color {
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

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(isPaused ? 0.08 : 0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: subscription.category.icon)
                    .font(.title3)
                    .foregroundStyle(isPaused ? .secondary : categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundStyle(isPaused ? .secondary : .primary)

                if showDueDate {
                    Text(dueDateText)
                        .font(.caption)
                        .foregroundStyle(subscription.isOverdue ? .red : .orange)
                } else {
                    Text(subscription.recurrenceType.localizedName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(expenseStore.formatCurrency(subscription.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isPaused ? .secondary : .primary)

                if !showDueDate {
                    Text("~\(expenseStore.formatCurrency(subscription.monthlyCost))/\(L("month_abbr"))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(isPaused ? 0.7 : 1.0)
    }

    private var dueDateText: String {
        if subscription.isOverdue {
            return L("overdue")
        } else if subscription.daysUntilBilling == 0 {
            return L("due_today")
        } else if subscription.daysUntilBilling == 1 {
            return L("due_tomorrow")
        } else {
            return String(format: L("due_in_days"), subscription.daysUntilBilling)
        }
    }
}

// MARK: - Add Subscription View

struct AddSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expenseStore = ExpenseStore.shared

    @State private var name = ""
    @State private var amountString = ""
    @State private var selectedCategory: ExpenseCategory = .utilities
    @State private var recurrenceType: RecurrenceType = .monthly
    @State private var nextBillingDate = Date()
    @State private var notes = ""
    @State private var reminderEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L("subscription_name"), text: $name)

                    HStack {
                        Text(expenseStore.budget.currency.symbol)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountString)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    Picker(L("category"), selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Label(category.localizedName, systemImage: category.icon)
                                .tag(category)
                        }
                    }

                    Picker(L("billing_cycle"), selection: $recurrenceType) {
                        ForEach(RecurrenceType.allCases) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }

                    DatePicker(L("next_billing_date"), selection: $nextBillingDate, displayedComponents: .date)
                }

                Section {
                    Toggle(L("payment_reminder"), isOn: $reminderEnabled)

                    TextField(L("notes_optional"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(L("add_subscription"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("save")) {
                        saveSubscription()
                    }
                    .disabled(name.isEmpty || amountString.isEmpty)
                }
            }
        }
    }

    private func saveSubscription() {
        let cleaned = amountString.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleaned), amount > 0 else { return }

        let subscription = Subscription(
            name: name,
            amount: amount,
            recurrenceType: recurrenceType,
            category: selectedCategory,
            nextBillingDate: nextBillingDate,
            startDate: Date(),
            isActive: true,
            notes: notes.isEmpty ? nil : notes,
            reminderEnabled: reminderEnabled
        )

        expenseStore.addSubscription(subscription)
        dismiss()
    }
}

// MARK: - Subscription Detail View

struct SubscriptionDetailView: View {
    let subscription: Subscription
    @Environment(\.dismiss) private var dismiss
    @State private var expenseStore = ExpenseStore.shared
    @State private var showingEditSheet = false

    private var categoryColor: Color {
        switch subscription.category.color {
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

    var body: some View {
        List {
            // Header Section
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 60, height: 60)
                        Image(systemName: subscription.category.icon)
                            .font(.title)
                            .foregroundStyle(categoryColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(subscription.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(subscription.category.localizedName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            // Cost Section
            Section {
                HStack {
                    Text(L("amount"))
                    Spacer()
                    Text(expenseStore.formatCurrency(subscription.amount))
                        .fontWeight(.semibold)
                }

                HStack {
                    Text(L("billing_cycle"))
                    Spacer()
                    Text(subscription.recurrenceType.localizedName)
                }

                HStack {
                    Text(L("monthly_cost"))
                    Spacer()
                    Text(expenseStore.formatCurrency(subscription.monthlyCost))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(L("yearly_cost"))
                    Spacer()
                    Text(expenseStore.formatCurrency(subscription.yearlyCost))
                        .foregroundStyle(.orange)
                }
            }

            // Billing Section
            Section {
                HStack {
                    Text(L("next_billing_date"))
                    Spacer()
                    Text(expenseStore.formatDate(subscription.nextBillingDate))
                        .foregroundStyle(subscription.isOverdue ? .red : .primary)
                }

                HStack {
                    Text(L("start_date"))
                    Spacer()
                    Text(expenseStore.formatDate(subscription.startDate))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(L("status"))
                    Spacer()
                    Text(subscription.isActive ? L("active") : L("paused"))
                        .foregroundStyle(subscription.isActive ? .green : .orange)
                }
            }

            // Notes Section
            if let notes = subscription.notes, !notes.isEmpty {
                Section {
                    Text(notes)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(L("notes"))
                }
            }

            // Actions Section
            Section {
                Button {
                    expenseStore.markSubscriptionPaid(subscription)
                } label: {
                    Label(L("record_payment"), systemImage: "checkmark.circle")
                }

                Button {
                    expenseStore.toggleSubscriptionActive(subscription)
                } label: {
                    Label(
                        subscription.isActive ? L("pause_subscription") : L("resume_subscription"),
                        systemImage: subscription.isActive ? "pause.circle" : "play.circle"
                    )
                }
                .foregroundStyle(.orange)

                Button(role: .destructive) {
                    expenseStore.deleteSubscription(subscription)
                    dismiss()
                } label: {
                    Label(L("delete_subscription"), systemImage: "trash")
                }
            }
        }
        .navigationTitle(L("subscription_details"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SubscriptionsView()
}
