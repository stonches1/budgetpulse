//
//  SpendingTrendsView.swift
//  BudgetPulse
//

import SwiftUI
import Charts

enum TrendPeriod: String, CaseIterable, Identifiable {
    case daily = "daily"
    case monthly = "monthly"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .daily: return L("daily_spending")
        case .monthly: return L("monthly_spending")
        }
    }
}

struct SpendingTrendsView: View {
    @State private var expenseStore = ExpenseStore.shared
    @State private var selectedPeriod: TrendPeriod = .daily

    var dailyData: [DailySpending] {
        expenseStore.dailySpending(days: 30)
    }

    var monthlyData: [MonthlySpending] {
        expenseStore.monthlySpending(months: 6)
    }

    var averageDaily: Double {
        expenseStore.averageDailySpending(days: 30)
    }

    var body: some View {
        List {
            Section {
                Picker(L("period"), selection: $selectedPeriod) {
                    ForEach(TrendPeriod.allCases) { period in
                        Text(period.localizedName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if selectedPeriod == .daily {
                        DailySpendingChart(data: dailyData, average: averageDaily)
                            .frame(height: 200)
                    } else {
                        MonthlySpendingChart(data: monthlyData)
                            .frame(height: 200)
                    }
                }
                .padding(.vertical, 8)
            }

            Section {
                if selectedPeriod == .daily {
                    HStack {
                        Text(L("average_daily"))
                        Spacer()
                        Text(expenseStore.formatCurrency(averageDaily))
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text(L("highest_day"))
                        Spacer()
                        if let max = dailyData.max(by: { $0.amount < $1.amount }) {
                            VStack(alignment: .trailing) {
                                Text(expenseStore.formatCurrency(max.amount))
                                    .fontWeight(.medium)
                                Text(expenseStore.formatDate(max.date, style: .short))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        Text(L("total_30_days"))
                        Spacer()
                        Text(expenseStore.formatCurrency(dailyData.reduce(0) { $0 + $1.amount }))
                            .fontWeight(.medium)
                    }
                } else {
                    HStack {
                        Text(L("average_monthly"))
                        Spacer()
                        let avgMonthly = monthlyData.isEmpty ? 0 : monthlyData.reduce(0) { $0 + $1.amount } / Double(monthlyData.count)
                        Text(expenseStore.formatCurrency(avgMonthly))
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text(L("highest_month"))
                        Spacer()
                        if let max = monthlyData.max(by: { $0.amount < $1.amount }) {
                            VStack(alignment: .trailing) {
                                Text(expenseStore.formatCurrency(max.amount))
                                    .fontWeight(.medium)
                                Text(expenseStore.formatMonthYear(max.month))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text(L("statistics"))
            }
        }
        .navigationTitle(L("spending_trends"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DailySpendingChart: View {
    @State private var expenseStore = ExpenseStore.shared
    let data: [DailySpending]
    let average: Double

    var body: some View {
        Chart {
            ForEach(data) { item in
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            RuleMark(y: .value("Average", average))
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(L("avg"))
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(expenseStore.formatCurrency(amount))
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

struct MonthlySpendingChart: View {
    @State private var expenseStore = ExpenseStore.shared
    let data: [MonthlySpending]

    var body: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(expenseStore.formatCurrency(amount))
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SpendingTrendsView()
    }
}
