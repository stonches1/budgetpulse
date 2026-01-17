//
//  DateFilterView.swift
//  BudgetPulse
//

import SwiftUI

struct DateFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilter: DateFilter
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var showCustomPicker = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(DateFilter.allCases) { filter in
                        Button {
                            selectedFilter = filter
                            dismiss()
                        } label: {
                            HStack {
                                Text(filter.localizedName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text(L("preset_filters"))
                }

                Section {
                    Button {
                        showCustomPicker = true
                    } label: {
                        HStack {
                            Text(L("custom_range"))
                                .foregroundStyle(.primary)
                            Spacer()
                            if case .custom = selectedFilter {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    if showCustomPicker || selectedFilter.id.hasPrefix("custom") {
                        DatePicker(
                            L("start_date"),
                            selection: $customStartDate,
                            displayedComponents: .date
                        )
                        .environment(\.locale, LanguageManager.shared.effectiveLocale)

                        DatePicker(
                            L("end_date"),
                            selection: $customEndDate,
                            in: customStartDate...,
                            displayedComponents: .date
                        )
                        .environment(\.locale, LanguageManager.shared.effectiveLocale)

                        Button(L("apply_filter")) {
                            selectedFilter = .custom(start: customStartDate, end: customEndDate)
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.blue)
                    }
                } header: {
                    Text(L("custom"))
                }
            }
            .navigationTitle(L("date_filter"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("clear_filter")) {
                        selectedFilter = .thisMonth
                        dismiss()
                    }
                }
            }
            .onAppear {
                if case .custom(let start, let end) = selectedFilter {
                    customStartDate = start
                    customEndDate = end
                    showCustomPicker = true
                }
            }
        }
    }
}

#Preview {
    DateFilterView(selectedFilter: .constant(.thisMonth))
}
