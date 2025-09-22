//
//  AutoQuitApp.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/19.
//

import Combine
import OSLog
import SwiftUI

let logger = Logger()

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    weak var state: AppState?

    var statusItem: NSStatusItem?

    var menu: NSMenu {
        let menu = NSMenu()

        let items = [
            NSMenuItem(title: "AutoQuit", action: nil, keyEquivalent: ""),
            NSMenuItem.separator(),
            NSMenuItem(title: "Preferences", action: #selector(self.openPreference), keyEquivalent: ""),
            NSMenuItem.separator(),
            NSMenuItem(
                title: "Quit",
                action: #selector(NSApplication.shared.terminate(_:)),
                keyEquivalent: "q"
            ),
        ].compactMap { $0 }

        items.forEach { menu.addItem($0) }

        return menu
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        statusItem?.button?.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil)
        statusItem?.button?.image?.size = NSSize(width: 16, height: 16)
        statusItem?.button?.image?.isTemplate = true
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(self.displayMenu)

        state?.setup()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        if let nextApp = NSWorkspace.shared.runningApplications.first(where: { $0 != .current }) {
            NSApp.yieldActivation(to: nextApp)
        } else {
            NSApp.deactivate()
        }
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    @objc func displayMenu() {
        // https://stackoverflow.com/a/57612963
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func openPreference() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        EnvironmentValues().openWindow(id: Constants.PreferenceWindowID)
    }
}

@main
struct AutoQuitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let appState = AppState()

    init() {
        appDelegate.state = self.appState
    }

    var body: some Scene {
        SettingsWindow(appState: appState)
    }
}
