//
//  ContentView.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/19.
//

import SwiftUI

enum Tabs: Equatable, Hashable, Identifiable {
    case general

    var id: Int {
        switch self {
        case .general: 1
        }
    }
}

struct GeneralTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button("Click Me") {
            appState.permissions.accessibility.checkPermissionAndPromptIfNeeded()
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
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    ContentView()
}
