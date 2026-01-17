//
//  OnboardingView.swift
//  BudgetPulse
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var selectedLanguage: AppLanguage = .system
    @State private var selectedCurrency: CurrencyCode = .usd
    @State private var budgetLimitString: String = "1000"
    @State private var languageRefreshID = UUID()

    @State private var expenseStore = ExpenseStore.shared
    @State private var languageManager = LanguageManager.shared

    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                welcomePage
                    .tag(0)
                    .id("welcome-\(languageRefreshID)")

                // Page 2: Language Selection
                languageSelectionPage
                    .tag(1)
                    .id("language-\(languageRefreshID)")

                // Page 3: Currency Selection
                currencySelectionPage
                    .tag(2)
                    .id("currency-\(languageRefreshID)")

                // Page 4: Budget Limit
                budgetLimitPage
                    .tag(3)
                    .id("budget-\(languageRefreshID)")
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Bottom Section
            bottomSection
                .id("bottom-\(languageRefreshID)")
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    private func applyLanguageImmediately(_ language: AppLanguage) {
        selectedLanguage = language
        // Apply the language change without triggering global refresh
        languageManager.currentLanguage = language

        // Apply to Bundle directly (without triggering global refreshID)
        if language != .system {
            Bundle.setLanguage(language.rawValue)
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        } else {
            Bundle.setLanguage(nil)
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()

        // Refresh the content locally without resetting navigation
        languageRefreshID = UUID()
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }
            .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)

            VStack(spacing: 12) {
                Text(L("welcome_title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(L("track_spending_subtitle"))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Features List
            VStack(alignment: .leading, spacing: 16) {
                OnboardingFeatureRow(
                    icon: "dollarsign.circle.fill",
                    color: .green,
                    title: L("onboarding_feature_track"),
                    subtitle: L("onboarding_feature_track_desc")
                )

                OnboardingFeatureRow(
                    icon: "chart.bar.fill",
                    color: .blue,
                    title: L("onboarding_feature_budget"),
                    subtitle: L("onboarding_feature_budget_desc")
                )

                OnboardingFeatureRow(
                    icon: "globe",
                    color: .purple,
                    title: L("onboarding_feature_languages"),
                    subtitle: L("onboarding_feature_languages_desc")
                )
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Language Selection Page

    private var languageSelectionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "globe")
                    .font(.system(size: 44))
                    .foregroundStyle(.purple)
            }

            VStack(spacing: 8) {
                Text(L("onboarding_select_language"))
                    .font(.title)
                    .fontWeight(.bold)

                Text(L("onboarding_language_description"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Language Options
            VStack(spacing: 12) {
                ForEach(AppLanguage.allCases) { language in
                    LanguageOptionButton(
                        language: language,
                        isSelected: selectedLanguage == language
                    ) {
                        applyLanguageImmediately(language)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Currency Selection Page

    private var currencySelectionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 8) {
                Text(L("onboarding_select_currency"))
                    .font(.title)
                    .fontWeight(.bold)

                Text(L("onboarding_currency_description"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Currency Options
            VStack(spacing: 12) {
                ForEach(CurrencyCode.allCases) { currency in
                    CurrencyOptionButton(
                        currency: currency,
                        isSelected: selectedCurrency == currency
                    ) {
                        selectedCurrency = currency
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Budget Limit Page

    private var budgetLimitPage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 8) {
                Text(L("onboarding_set_budget"))
                    .font(.title)
                    .fontWeight(.bold)

                Text(L("onboarding_budget_description"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Budget Input
            VStack(spacing: 16) {
                Text(L("monthly_limit"))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .center, spacing: 8) {
                    Text(selectedCurrency.symbol)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.orange)

                    TextField("1000", text: $budgetLimitString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 200)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 32)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)

                Text(L("onboarding_budget_hint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 16) {
            // Page Indicators
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }

            // Buttons
            HStack(spacing: 16) {
                if currentPage > 0 {
                    Button {
                        withAnimation {
                            currentPage -= 1
                        }
                    } label: {
                        Text(L("onboarding_back"))
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Button {
                    if currentPage < totalPages - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentPage == totalPages - 1 ? L("onboarding_get_started") : L("onboarding_next"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.top, 16)
        .background(Color(.systemBackground))
    }

    // MARK: - Actions

    private func completeOnboarding() {
        // Save selected language to manager
        languageManager.currentLanguage = selectedLanguage

        // Apply selected currency
        expenseStore.updateCurrency(selectedCurrency)

        // Apply budget limit
        if let budgetLimit = Double(budgetLimitString.replacingOccurrences(of: ",", with: ".")), budgetLimit > 0 {
            expenseStore.updateMonthlyLimit(budgetLimit)
        }

        // Mark onboarding as complete
        hasCompletedOnboarding = true
    }
}

// MARK: - Onboarding Feature Row

struct OnboardingFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Language Option Button

struct LanguageOptionButton: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if language != .system {
                        Text(language.nativeName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                } else {
                    Circle()
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Currency Option Button

struct CurrencyOptionButton: View {
    let currency: CurrencyCode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(currency.symbol)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.localizedName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(currency.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                } else {
                    Circle()
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.green : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
