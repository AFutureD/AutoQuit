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

extension AppActivitiesMonitor {
    struct RunningState: Hashable {
        let updateAt: Date
        let isActive: Bool
    }
}

extension AppActivitiesMonitor: LogCarrier {
    static var category: String {
        "AppActivitiesMonitor"
    }
}


class AppActivitiesMonitor {
    var workspaceObs: AnyCancellable?
    var runningAppActiveObs: [pid_t: AnyCancellable] = [:]
    var runningAppLastActiveTime: [pid_t: RunningState] = [:]

    func setup() {
        StartObserveApps()
    }
}

extension AppActivitiesMonitor {

    func StartObserveApps() {
        logger.info("[*] StartObserveApps")
        workspaceObs = NSWorkspace.shared.publisher(for: \.runningApplications).sink { [weak self] runningApps in
            self?.handleWorkspaceStateChanges(runningApps)
        }
    }

    func startObserveApp(_ app: NSRunningApplication) {
        guard let identifier = app.bundleIdentifier else { return }

        guard !runningAppActiveObs.keys.contains(app.processIdentifier) else {
            return
        }

        logger.info("[*] startObserveApp: pid: \(app.processIdentifier) bundle: \(app.bundleIdentifier ?? "nil")")

        let obs = app.publisher(for: \.isActive).sink { [weak self] isActive in
            self?.handleApplicationActiveChanges(app, isActive)
        }
        runningAppActiveObs[app.processIdentifier] = obs
    }
}

extension AppActivitiesMonitor {
    func handleWorkspaceStateChanges(_ apps: [NSRunningApplication]) {
        let newAppIds = apps.compactMap(\.processIdentifier)
        let oldAppIds = runningAppActiveObs.keys

        let killedAppIds = Set(oldAppIds).subtracting(newAppIds)
        killedAppIds.forEach {
            runningAppActiveObs.removeValue(forKey: $0)
            runningAppLastActiveTime.removeValue(forKey: $0)
            logger.info("[*] Remove App Obs. pid: \($0)")
        }

        for app in apps {
            startObserveApp(app)
        }
    }

    func handleApplicationActiveChanges(_ app: NSRunningApplication, _ isActive: Bool) {
        guard let identifier = app.bundleIdentifier else { return }

        logger.info("[*] App Active State Changes. pid: \(app.processIdentifier) bundle: \(identifier) isActive: \(isActive)")

        runningAppLastActiveTime[app.processIdentifier] = RunningState(updateAt: Date(), isActive: isActive)
    }
}

extension AppActivitiesMonitor {
    struct Update: Hashable {
        let appProcessIdentifier: pid_t
        let runningState: RunningState
        let hasAnyWindow: Bool
    }

    func updates(idle: TimeInterval) -> any AsyncSequence<Update, Never> {
        AsyncTimerSequence(interval: .seconds(1), clock: .continuous).map { [weak self] instant in
            self?.runningAppLastActiveTime.filter {
                !$0.value.isActive && $0.value.updateAt.advanced(by: idle) < Date()
            }.compactMap { (pid: pid_t, state: RunningState) in
                guard let app = NSWorkspace.shared.runningApp(by: pid) else { return nil }

                return Update(
                    appProcessIdentifier: app.processIdentifier,
                    runningState: state,
                    hasAnyWindow: app.hasAnyWindow ?? true
                )
            } ?? []
        }.flatMap { $0.async }.removeDuplicates()
    }
}
