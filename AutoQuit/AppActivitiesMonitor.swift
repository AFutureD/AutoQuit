//
//  AppActivitiesMonitor.swift
//  AutoClose
//
//  Created by Huanan on 2025/9/19.
//

import AppKit
import AsyncAlgorithms
import Combine
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
    var runningAppLastActiveTime: [pid_t: Date] = [:]

    func setup() {
        StartObserveApps()
    }
}

extension AppActivitiesMonitor {

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
}

extension AppActivitiesMonitor {
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

        logger.info("\(identifier) - isActive: \(isActive) hasWindow: \(app.hasAnyWindow ?? true)")
    }
}

extension AppActivitiesMonitor {
    struct Update: Hashable {
        let appProcessIdentifier: pid_t
        let lastActiveDate: Date
        let hasAnyWindow: Bool
    }

    func updates(idle: TimeInterval) -> any AsyncSequence<Update, Never> {
        AsyncTimerSequence(interval: .seconds(1), clock: .continuous).map { [weak self] instant in
            self?.runningAppLastActiveTime.filter {
                $0.value.advanced(by: idle) < Date()
            }.compactMap { (pid: pid_t, value: Date) in
                guard let app = NSWorkspace.shared.runningApp(by: pid) else { return nil }

                return Update(
                    appProcessIdentifier: app.processIdentifier,
                    lastActiveDate: value,
                    hasAnyWindow: app.hasAnyWindow ?? true
                )
            } ?? []
        }.flatMap { $0.async }.removeDuplicates()
    }
}
