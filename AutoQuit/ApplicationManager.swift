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

class ApplicationManager {

    var quitApplicationList: [String] = [
        "com.apple.Preview"
    ]

    func shutdown(_ pid: pid_t) {
        let app = NSWorkspace.shared.runningApp(by: pid)
        guard let app, app.activationPolicy == .regular else { return }

        guard !app.isActive,
              app.hasAnyWindow == false,
              let identifier = app.bundleIdentifier,
              quitApplicationList.contains(identifier)
        else {
            return
        }

        logger.info("shutdown app. pid: \(app.processIdentifier) bundle: \(app.bundleIdentifier ?? "nil")")
        app.terminate()
    }
}
