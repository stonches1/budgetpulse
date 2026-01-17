//
//  ContentView.swift
//  BudgetPulse
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingSearch = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(L("tab_dashboard"), systemImage: "chart.pie.fill", value: 0) {
                DashboardView()
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                showingSearch = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                    }
            }

            Tab(L("tab_categories"), systemImage: "square.grid.2x2.fill", value: 1) {
                CategoriesView()
            }

            Tab(L("tab_reports"), systemImage: "chart.bar.fill", value: 2) {
                ReportsView()
            }

            Tab(L("tab_history"), systemImage: "calendar", value: 3) {
                MonthlyHistoryView()
            }

            Tab(L("tab_settings"), systemImage: "gearshape.fill", value: 4) {
                SettingsView()
            }
        }
        .sheet(isPresented: $showingSearch) {
            GlobalSearchView()
        }
    }
}

#Preview {
    ContentView()
}
