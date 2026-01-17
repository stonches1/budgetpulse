//
//  PaywallView.swift
//  BudgetPulse
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isRestoring = false
    @State private var showingPrivacyPolicy = false
    @State private var isEligibleForTrial = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Features List
                    featuresSection

                    // Pricing Options
                    pricingSection

                    // Subscribe Button
                    subscribeButton

                    // Restore Purchases
                    restoreButton

                    // Terms
                    termsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
            }
            .alert(L("error"), isPresented: $showingError) {
                Button(L("ok"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                if let monthly = subscriptionManager.monthlyProduct {
                    selectedProduct = monthly
                }
                await checkTrialEligibility()
            }
        }
    }

    private func checkTrialEligibility() async {
        guard let product = subscriptionManager.monthlyProduct ?? subscriptionManager.yearlyProduct else {
            return
        }
        if let subscription = product.subscription {
            isEligibleForTrial = await subscription.isEligibleForIntroOffer
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            }

            Text(L("premium_title"))
                .font(.title2)
                .fontWeight(.bold)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 12) {
            FeatureRow(icon: "chart.bar.fill", title: L("feature_reports"), description: L("feature_reports_desc"))
            FeatureRow(icon: "star.fill", title: L("feature_unlimited_goals"), description: L("feature_unlimited_goals_desc"))
            FeatureRow(icon: "camera.fill", title: L("feature_receipts"), description: L("feature_receipts_desc"))
            FeatureRow(icon: "chart.pie.fill", title: L("feature_category_budgets"), description: L("feature_category_budgets_desc"))
            FeatureRow(icon: "creditcard.fill", title: L("feature_subscriptions"), description: L("feature_subscriptions_desc"))
            FeatureRow(icon: "arrow.triangle.2.circlepath", title: L("feature_rollover"), description: L("feature_rollover_desc"))
            FeatureRow(icon: "square.and.arrow.up.fill", title: L("feature_export"), description: L("feature_export_desc"))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Pricing Section

    private var isMonthlySelected: Bool {
        selectedProduct?.id == subscriptionManager.monthlyProduct?.id
    }

    private var pricingSection: some View {
        VStack(spacing: 12) {
            // Monthly option with free trial
            if let monthly = subscriptionManager.monthlyProduct {
                Button {
                    selectedProduct = monthly
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(L("monthly"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                // Free trial badge (only show if eligible)
                                if isEligibleForTrial {
                                    Text(L("free_trial_badge"))
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.green)
                                        .clipShape(Capsule())
                                }
                            }

                            Text(isEligibleForTrial ? L("then_billed_monthly") : L("billed_monthly"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(monthly.displayPrice)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Image(systemName: isMonthlySelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isMonthlySelected ? .green : .secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isMonthlySelected ? Color.green : Color.clear, lineWidth: 2)
                    )
                }
                .onAppear {
                    if selectedProduct == nil {
                        selectedProduct = monthly
                    }
                }
            }

            // Yearly option
            if let yearly = subscriptionManager.yearlyProduct {
                Button {
                    selectedProduct = yearly
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(L("yearly"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                // Free trial badge (only show if eligible)
                                if isEligibleForTrial {
                                    Text(L("free_trial_badge"))
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.green)
                                        .clipShape(Capsule())
                                }

                                // Best value badge
                                Text(L("best_value"))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange)
                                    .clipShape(Capsule())
                            }

                            Text(isEligibleForTrial ? L("then_billed_yearly") : L("billed_yearly"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(yearly.displayPrice)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Image(systemName: !isMonthlySelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(!isMonthlySelected ? .blue : .secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(!isMonthlySelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
            }

            if subscriptionManager.products.isEmpty {
                ProgressView()
                    .padding()
                Text(L("loading_products"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        VStack(spacing: 12) {
            // No payment required text (only show if eligible for free trial)
            if isEligibleForTrial {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text(L("no_payment_now"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task {
                    guard let product = selectedProduct else { return }
                    let success = await subscriptionManager.purchase(product)
                    if success {
                        dismiss()
                    } else if !subscriptionManager.purchaseInProgress {
                        errorMessage = L("purchase_failed")
                        showingError = true
                    }
                }
            } label: {
                HStack {
                    if subscriptionManager.purchaseInProgress {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(isEligibleForTrial ? L("start_free_trial") : L("subscribe_now"))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isEligibleForTrial ? [.green, .mint] : [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedProduct == nil || subscriptionManager.purchaseInProgress)
        }
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task {
                isRestoring = true
                let success = await subscriptionManager.restorePurchases()
                isRestoring = false
                if success {
                    dismiss()
                } else {
                    errorMessage = L("restore_failed")
                    showingError = true
                }
            }
        } label: {
            if isRestoring {
                ProgressView()
            } else {
                Text(L("restore_purchases"))
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
        .disabled(isRestoring)
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        VStack(spacing: 8) {
            Text(L("subscription_terms"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button(L("privacy_policy")) {
                    showingPrivacyPolicy = true
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                Button(L("terms_of_use")) {
                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 20)
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Pricing Option Card

struct PricingOptionCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let period: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }

                    Text(product.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Premium Feature Lock View

struct PremiumFeatureLockView: View {
    let feature: String
    @State private var subscriptionManager = SubscriptionManager.shared

    private var featureBenefits: [(icon: String, text: String)] {
        // Check which feature this is and return appropriate benefits
        if feature == L("reports") {
            return [
                ("chart.pie.fill", L("reports_benefit_1")),
                ("chart.bar.fill", L("reports_benefit_2")),
                ("lightbulb.fill", L("reports_benefit_3")),
                ("calendar", L("reports_benefit_4"))
            ]
        } else if feature == L("category_budgets") {
            return [
                ("chart.pie.fill", L("category_budget_benefit_1")),
                ("bell.badge.fill", L("category_budget_benefit_2")),
                ("target", L("category_budget_benefit_3"))
            ]
        } else if feature == L("subscriptions") {
            return [
                ("creditcard.fill", L("subscription_benefit_1")),
                ("bell.badge.fill", L("subscription_benefit_2")),
                ("chart.line.uptrend.xyaxis", L("subscription_benefit_3")),
                ("calendar", L("subscription_benefit_4"))
            ]
        } else if feature == L("budget_rollover") {
            return [
                ("arrow.triangle.2.circlepath", L("rollover_benefit_1")),
                ("banknote.fill", L("rollover_benefit_2")),
                ("chart.bar.fill", L("rollover_benefit_3"))
            ]
        } else {
            return []
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)

                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                }

                VStack(spacing: 8) {
                    Text(L("premium_required"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(String(format: L("premium_unlock_feature"), feature))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Feature Benefits
                if !featureBenefits.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L("whats_included"))
                            .font(.headline)
                            .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            ForEach(featureBenefits, id: \.text) { benefit in
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.15))
                                            .frame(width: 36, height: 36)

                                        Image(systemName: benefit.icon)
                                            .font(.system(size: 16))
                                            .foregroundStyle(.blue)
                                    }

                                    Text(benefit.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)

                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }
                }

                Button {
                    subscriptionManager.showingPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text(L("upgrade_to_premium"))
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 20)
            }
        }
        .sheet(isPresented: $subscriptionManager.showingPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    PaywallView()
}
