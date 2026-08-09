//
//  ApplicationManager.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/22.
//

import AppKit
import Foundation
import os.log

extension ApplicationManager: LogCarrier {
    static var category: String {
        "ApplicationManager"
    }
}

@MainActor
class ApplicationManager {
    private let ruleStore: AppRuleStore

    init(ruleStore: AppRuleStore) {
        self.ruleStore = ruleStore
    }

    func shutdown(_ pid: pid_t) {
        let app = NSWorkspace.shared.runningApp(by: pid)
        guard let app, app.activationPolicy == .regular else { return }

        guard !app.isActive else {
            return
        }

        let identifier = app.bundleIdentifier
            ?? app.bundleURL.map { "path:\($0.standardizedFileURL.path)" }
        guard let identifier,
              app.bundleIdentifier != Bundle.main.bundleIdentifier
        else { return }

        let condition = ruleStore.condition(for: identifier)
        switch condition {
        case .doNothing:
            return
        case .always:
            break
        case .whenNoWindows:
            guard app.hasAnyWindow == false else { return }
        }

        logger.info("shutdown app. pid: \(app.processIdentifier) bundle: \(app.bundleIdentifier ?? "nil")")
        app.terminate()
    }
}
