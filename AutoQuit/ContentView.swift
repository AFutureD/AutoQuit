//
//  ContentView.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/19.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button("Click Me") {
            appState.permissions.accessibility.checkPermissionAndPromptIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}
