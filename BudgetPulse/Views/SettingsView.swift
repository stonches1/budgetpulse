//
//  SettingsView.swift
//  BudgetPulse
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.requestReview) private var requestReview
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var languageManager = LanguageManager.shared
    @State private var expenseStore = ExpenseStore.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var appearanceManager = AppearanceManager.shared
    @State private var monthlyLimitString = ""

    @State private var showingLanguagePicker = false
    @State private var showingCurrencyPicker = false
    @State private var showingAppearancePicker = false
    @State private var showingExportSheet = false
    @State private var showingResetOnboardingAlert = false
    @State private var showingResetDataAlert = false
    @State private var showingNotificationPermission = false
    @State private var showingPaywall = false
    @State private var showingDisclaimer = false

    var body: some View {
        NavigationStack {
            Form {
                // Premium Section
                if !subscriptionManager.isPremium {
                    Section {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.yellow, .orange],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)

                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L("upgrade_to_premium"))
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(L("unlock_all_features"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Section {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("premium_active"))
                                    .font(.headline)
                                Text(L("premium_thanks"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // General Section
                Section {
                    // Language Picker
                    Button {
                        showingLanguagePicker = true
                    } label: {
                        HStack {
                            Label(L("language"), systemImage: "globe")
                            Spacer()
                            Text(languageManager.currentLanguage.nativeName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)

                    // Currency Picker
                    Button {
                        showingCurrencyPicker = true
                    } label: {
                        HStack {
                            Label(L("currency"), systemImage: "dollarsign.circle")
                            Spacer()
                            Text(expenseStore.budget.currency.rawValue)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)

                    // Appearance Picker
                    Button {
                        showingAppearancePicker = true
                    } label: {
                        HStack {
                            Label(L("appearance"), systemImage: "circle.lefthalf.filled")
                            Spacer()
                            Text(appearanceManager.currentAppearance.localizedName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text(L("general"))
                }

                // Budget Settings Section
                Section {
                    HStack {
                        Label(L("monthly_limit"), systemImage: "chart.bar")
                        Spacer()
                        HStack {
                            Text(expenseStore.budget.currency.symbol)
                                .foregroundStyle(.secondary)
                            TextField("1000", text: $monthlyLimitString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .onChange(of: monthlyLimitString) { _, newValue in
                                    if let value = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                                        expenseStore.updateMonthlyLimit(value)
                                    }
                                }
                        }
                    }

                    NavigationLink {
                        CategoryBudgetSettingsView()
                    } label: {
                        Label(L("category_budgets"), systemImage: "chart.pie")
                    }

                    // Budget Rollover (Premium Feature)
                    if subscriptionManager.canAccessBudgetRollover {
                        Toggle(isOn: Binding(
                            get: { expenseStore.budget.rolloverEnabled },
                            set: { expenseStore.toggleRollover($0) }
                        )) {
                            Label(L("budget_rollover"), systemImage: "arrow.triangle.2.circlepath")
                        }
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Label(L("budget_rollover"), systemImage: "arrow.triangle.2.circlepath")
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                } header: {
                    Text(L("budget_settings"))
                } footer: {
                    if subscriptionManager.canAccessBudgetRollover && expenseStore.budget.rolloverEnabled {
                        Text(L("rollover_footer"))
                    }
                }

                // Subscriptions Section
                Section {
                    if subscriptionManager.canAccessSubscriptionTracker {
                        NavigationLink {
                            SubscriptionsView()
                        } label: {
                            HStack {
                                Label(L("subscriptions"), systemImage: "creditcard")
                                Spacer()
                                if !expenseStore.subscriptions.isEmpty {
                                    Text("\(expenseStore.activeSubscriptions.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray5))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Label(L("subscriptions"), systemImage: "creditcard")
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(L("subscriptions"))
                        if !subscriptionManager.canAccessSubscriptionTracker {
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

                // Data Section
                Section {
                    // Export Data (Premium Feature)
                    if subscriptionManager.canExportData {
                        Button {
                            showingExportSheet = true
                        } label: {
                            Label(L("export_data"), systemImage: "square.and.arrow.up")
                        }
                        .disabled(expenseStore.expenses.isEmpty)
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Label(L("export_data"), systemImage: "square.and.arrow.up")
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(L("data"))
                        if !subscriptionManager.canExportData {
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

                // Notifications Section
                Section {
                    Toggle(isOn: Binding(
                        get: { notificationManager.budgetAlertsEnabled },
                        set: { newValue in
                            Task {
                                if newValue {
                                    let granted = await notificationManager.requestAuthorization()
                                    if granted {
                                        notificationManager.budgetAlertsEnabled = true
                                    } else {
                                        showingNotificationPermission = true
                                    }
                                } else {
                                    notificationManager.budgetAlertsEnabled = false
                                }
                            }
                        }
                    )) {
                        Label(L("budget_alerts"), systemImage: "bell.badge")
                    }

                    Toggle(isOn: Binding(
                        get: { notificationManager.dailyRemindersEnabled },
                        set: { newValue in
                            Task {
                                if newValue {
                                    let granted = await notificationManager.requestAuthorization()
                                    if granted {
                                        notificationManager.dailyRemindersEnabled = true
                                    } else {
                                        showingNotificationPermission = true
                                    }
                                } else {
                                    notificationManager.dailyRemindersEnabled = false
                                }
                            }
                        }
                    )) {
                        Label(L("daily_reminders"), systemImage: "clock")
                    }

                    if notificationManager.dailyRemindersEnabled {
                        DatePicker(
                            L("reminder_time"),
                            selection: Binding(
                                get: { notificationManager.reminderTime },
                                set: { notificationManager.reminderTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text(L("notifications"))
                } footer: {
                    Text(L("notifications_footer"))
                }

                // About Section
                Section {
                    Button {
                        requestReview()
                    } label: {
                        Label(L("rate_app"), systemImage: "star")
                    }

                    Button {
                        showingDisclaimer = true
                    } label: {
                        Label(L("disclaimer"), systemImage: "exclamationmark.triangle")
                    }

                    HStack {
                        Label(L("version"), systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(L("about"))
                }

                // Advanced Section
                Section {
                    Button {
                        showingResetOnboardingAlert = true
                    } label: {
                        Label(L("reset_onboarding"), systemImage: "arrow.counterclockwise")
                    }

                    Button(role: .destructive) {
                        showingResetDataAlert = true
                    } label: {
                        Label(L("reset_all_data"), systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text(L("advanced"))
                } footer: {
                    Button {
                        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text(L("terms_of_use"))
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(L("settings_title"))
            .onAppear {
                monthlyLimitString = String(format: "%.0f", expenseStore.budget.monthlyLimit)
            }
            .sheet(isPresented: $showingLanguagePicker) {
                LanguagePickerView()
            }
            .sheet(isPresented: $showingCurrencyPicker) {
                CurrencyPickerView()
            }
            .sheet(isPresented: $showingAppearancePicker) {
                AppearancePickerView()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataSheet()
            }
            .alert(
                L("reset_onboarding_title"),
                isPresented: $showingResetOnboardingAlert
            ) {
                Button(L("cancel"), role: .cancel) {}
                Button(L("reset"), role: .destructive) {
                    hasCompletedOnboarding = false
                }
            } message: {
                Text(L("reset_onboarding_message"))
            }
            .alert(
                L("reset_data_title"),
                isPresented: $showingResetDataAlert
            ) {
                Button(L("cancel"), role: .cancel) {}
                Button(L("reset"), role: .destructive) {
                    expenseStore.resetAllData()
                }
            } message: {
                Text(L("reset_data_message"))
            }
            .alert(
                L("notification_permission_title"),
                isPresented: $showingNotificationPermission
            ) {
                Button(L("open_settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button(L("cancel"), role: .cancel) {}
            } message: {
                Text(L("notification_permission_message"))
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingDisclaimer) {
                DisclaimerView()
            }
        }
    }
}

// MARK: - Export Data Sheet

struct ExportDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expenseStore = ExpenseStore.shared
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                }

                VStack(spacing: 8) {
                    Text(L("export_data"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(L("export_data_description"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Export Stats
                VStack(spacing: 12) {
                    HStack {
                        Text(L("total_expenses"))
                        Spacer()
                        Text("\(expenseStore.expenses.count)")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)

                Spacer()

                // Export Button
                ShareLink(
                    item: expenseStore.exportToCSV(),
                    subject: Text("BudgetPulse Export"),
                    message: Text(L("export_share_message"))
                ) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text(L("export_csv"))
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Language Picker View

struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        languageManager.changeLanguage(to: language)
                        // Delay dismiss to allow refresh to propagate
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(language.displayName)
                                    .foregroundStyle(.primary)
                                if language != .system {
                                    Text(language.nativeName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("select_language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Currency Picker View

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expenseStore = ExpenseStore.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(CurrencyCode.allCases) { currency in
                    Button {
                        expenseStore.updateCurrency(currency)
                        dismiss()
                    } label: {
                        HStack {
                            Text(currency.symbol)
                                .font(.title2)
                                .frame(width: 40)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currency.localizedName)
                                    .foregroundStyle(.primary)
                                Text(currency.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if expenseStore.budget.currency == currency {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("select_currency"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Appearance Picker View

struct AppearancePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appearanceManager = AppearanceManager.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(AppAppearance.allCases) { appearance in
                    Button {
                        appearanceManager.setAppearance(appearance)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: appearance.icon)
                                .font(.title2)
                                .foregroundStyle(appearance == .dark ? .purple : (appearance == .light ? .orange : .blue))
                                .frame(width: 40)
                            Text(appearance.localizedName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if appearanceManager.currentAppearance == appearance {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("select_appearance"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    SettingsView()
}
