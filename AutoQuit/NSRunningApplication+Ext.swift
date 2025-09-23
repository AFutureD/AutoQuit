//
//  NSRunningApplication+Ext.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/21.
//

import AppKit

extension NSRunningApplication {
    /// Returns true if the app owns any non-minimized AX window (visible state doesn’t matter).
    var hasAnyWindow: Bool? {
        guard AXIsProcessTrusted() else { return nil }

        let axApp = AXUIElementCreateApplication(self.processIdentifier)
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &value)
        guard err == .success, let windows = value as? [AXUIElement], !windows.isEmpty else { return false }

        return !windows.isEmpty
    }
}
