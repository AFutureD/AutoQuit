//
//  AppActivitiesMonitor.swift
//  AutoClose
//
//  Created by Huanan on 2025/9/19.
//


internal import Combine
import AppKit
import OSLog

extension NSWorkspace {
    func runningApp(by pid: pid_t) -> NSRunningApplication? {
        self.runningApplications.first { $0.processIdentifier == pid }
    }

    func runningApp(by identifier: String) -> NSRunningApplication? {
        self.runningApplications.first { $0.bundleIdentifier == identifier }
    }
}


class AppActivitiesMonitor {

    var workspaceObs: AnyCancellable?
    var runningAppActiveObs: [String: AnyCancellable] = [:]

    func setup() {
        StartObserveApps()
    }

    func StartObserveApps() {
        workspaceObs = NSWorkspace.shared.publisher(for: \.runningApplications).sink { [weak self] runningApps in
            self?.handleWorkspaceStateChanges(runningApps)
        }
    }

    func startObserveApp(_ app: NSRunningApplication) {
        guard let identifier = app.bundleIdentifier else { return }

        guard !runningAppActiveObs.keys.contains(identifier) else {
            return
        }

        let obs = app.publisher(for: \.isActive).sink { [weak self] isActive in
            self?.handleApplicationActiveChanges(app, isActive)
        }
        runningAppActiveObs[identifier] = obs
    }

    func handleWorkspaceStateChanges(_ apps: [NSRunningApplication]) {
        let newAppIds = apps.compactMap(\.bundleIdentifier)
        let oldAppIds = runningAppActiveObs.keys

        let killedAppIds = Set(oldAppIds).subtracting(newAppIds)
        killedAppIds.forEach { runningAppActiveObs[$0] = nil }

        for app in apps {
            startObserveApp(app)
        }
    }

    func handleApplicationActiveChanges(_ app: NSRunningApplication, _ isActive: Bool) {
        guard let identifier = app.bundleIdentifier else { return }

        logger.info("\(identifier) - isActive: \(isActive) hasWindow: \(app.hasAnyWindowAX(promptForAccessIfNeeded: true))")
    }
}
