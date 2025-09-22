//
//  SettingsWindow.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/21.
//

import SwiftUI

struct SettingsWindow: Scene {
    @ObservedObject var appState: AppState

    var body: some Scene {
        Window("", id: Constants.PreferenceWindowID) {
            ContentView()
                .frame(minWidth: 825, minHeight: 500)
        }
        .commandsRemoved()
        .windowResizability(.contentSize)
        .environmentObject(appState)
    }
}
