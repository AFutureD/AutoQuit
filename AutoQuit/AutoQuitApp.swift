//
//  AutoQuitApp.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/19.
//

import SwiftUI
import OSLog
internal import Combine

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


@MainActor
class AppState: NSObject {

    var anyCancelables: Set<AnyCancellable> = .init()

    let activitiedMonitor: AppActivitiesMonitor

    override init() {
        self.activitiedMonitor = .init()
    }


    func setup() {

        activitiedMonitor.setup()
        //        let it = Timer.publish(every: 1.0, on: .main, in: .common)
        //            .autoconnect()
        //            .values
        //
        //        Task {
        //            var tt: Bool = false
        //            for try await _ in it {
        //                let apps = NSWorkspace.shared.runningApplications
        //                apps.forEach { app in
        //                    if app.activationPolicy != .regular { return }
        //
        //                    logger.info("\(app.bundleIdentifier ?? "nil") - isActive: \(app.isActive) - isHidden: \(app.isHidden)")
        //                    logger.info("\(app.bundleIdentifier ?? "nil") - window: \(app.hasAnyWindowAX(promptForAccessIfNeeded: true))")
        //
        //                    if app.bundleIdentifier == "com.apple.Preview" {
        //                        if !tt, app.isActive == false && !app.hasAnyWindowAX() {
        //                            app.terminate()
        //                            tt = true
        //                        }
        //                    }
        //
        //                }
        //            }
        //        }
        //
        //        NSWorkspace.shared.publisher(for: \.runningApplications).sink { apps in
        //            apps.forEach { app in
        //                if app.activationPolicy != .regular { return }
        //
        //                logger.info("\(app.bundleIdentifier ?? "nil") - isActive: \(app.isActive) - isHidden: \(app.isHidden)")
        //                logger.info("\(app.bundleIdentifier ?? "nil") - window: \(app.hasAnyWindowAX(promptForAccessIfNeeded: true))")
        //
        //            }
        //        }.store(in: &anyCancelables)

    }
}

extension NSRunningApplication {
    /// Returns true if the app owns any non-minimized AX window (visible state doesn’t matter).
    func hasAnyWindowAX(promptForAccessIfNeeded: Bool = false) -> Bool {
        if promptForAccessIfNeeded {
            let opts: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts) // will prompt if not trusted
        } else if !AXIsProcessTrusted() {
            return false
        }

        let axApp = AXUIElementCreateApplication(self.processIdentifier)
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &value)
        guard err == .success, let windows = value as? [AXUIElement], !windows.isEmpty else { return false }

        for w in windows {
            var minRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(w, kAXMinimizedAttribute as CFString, &minRef) == .success,
               let minimized = minRef as? Bool, minimized == true {
                continue
            }
            // Optionally check kAXVisibleAttribute or size/position if you care
            return true
        }
        return false
    }
}

enum Constants {
    static let PreferenceWindowID = "PreferenceWindowID"
}

@main
struct AutoQuitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let appState = AppState()

    init() {
        appDelegate.state = self.appState
    }


    var body: some Scene {
        Window("", id: Constants.PreferenceWindowID) {
            ContentView()
        }
    }
}
