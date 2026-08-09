//
//  AutoQuitApp.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/19.
//

import Combine
import OSLog
import Sparkle
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    weak var state: AppState?

    var statusItem: NSStatusItem?

    private(set) lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: self
    )

    private(set) lazy var updaterViewModel = UpdaterViewModel(
        updater: updaterController.updater
    )

    var menu: NSMenu {
        let menu = NSMenu()

        let items = [
            NSMenuItem(title: "AutoQuit", action: nil, keyEquivalent: ""),
            NSMenuItem.separator(),
            NSMenuItem(title: "Preferences", action: #selector(self.openPreference), keyEquivalent: ""),
            {
                let item = NSMenuItem(
                    title: "Check for Updates…",
                    action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
                    keyEquivalent: ""
                )
                item.target = updaterController
                return item
            }(),
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
        _ = updaterController

        let wasLaunchedAtLogin = state?.wasLaunchedAtLogin == true
        let shouldOpenPreferences = Self.shouldOpenPreferences(
            wasLaunchedAtLogin: wasLaunchedAtLogin
        )

        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        statusItem?.button?.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil)
        statusItem?.button?.image?.size = NSSize(width: 16, height: 16)
        statusItem?.button?.image?.isTemplate = true
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(self.displayMenu)

        state?.setup()

        if wasLaunchedAtLogin {
            NSApp.setActivationPolicy(.accessory)
        } else if shouldOpenPreferences {
            DispatchQueue.main.async { [weak self] in
                self?.openPreference()
            }
        }
    }

    static func shouldOpenPreferences(wasLaunchedAtLogin: Bool) -> Bool {
        !wasLaunchedAtLogin
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

extension AppDelegate: SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        // 常驻 accessory 模式时更新窗口会被压在其他应用后面,先切回前台再展示。
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
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
        SettingsWindow(
            appState: appState,
            updaterViewModel: appDelegate.updaterViewModel
        )
    }
}
