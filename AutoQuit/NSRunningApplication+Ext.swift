//
//  NSRunningApplication+Ext.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/21.
//

import AppKit

extension NSRunningApplication {
    /// Returns true if the app owns any non-minimized AX window (visible state doesn’t matter).
    func hasAnyWindowAX(promptForAccessIfNeeded: Bool = false) -> Bool {
        if promptForAccessIfNeeded {
            let opts: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts)  // will prompt if not trusted
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
                let minimized = minRef as? Bool, minimized == true
            {
                continue
            }
            // Optionally check kAXVisibleAttribute or size/position if you care
            return true
        }
        return false
    }
}
