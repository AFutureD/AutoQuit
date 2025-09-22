//
//  ApplicationManager.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/22.
//

import AppKit
import Foundation

class ApplicationManager {

    func shutdown(_ pid: pid_t) {
        let app = NSWorkspace.shared.runningApp(by: pid)
        guard let app, app.activationPolicy == .regular else { return }

        guard !app.isActive, app.hasAnyWindow == false else {
            return
        }

        app.terminate()
    }
}
