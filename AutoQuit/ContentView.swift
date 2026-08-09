//
//  ContentView.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/19.
//

import SwiftUI

enum Tabs: Equatable, Hashable, Identifiable {
    case general
    case appRules

    var id: Int {
        switch self {
        case .general: 1
        case .appRules: 2
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedTab: Tabs = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("General", systemImage: "gearshape.circle", value: .general) {
                GeneralTabView()
            }
            .customizationID("general")

            Tab("APP Rules", systemImage: "app.badge.checkmark", value: .appRules) {
                AppRulesTabView(
                    applicationCatalog: appState.applicationCatalog,
                    appRuleStore: appState.appRuleStore
                )
            }
            .customizationID("app-rules")
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    ContentView()
}
