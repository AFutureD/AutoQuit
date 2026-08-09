//
//  NSRunningApplication+Ext.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/21.
//

import AppKit

extension NSRunningApplication {
    /// Returns whether the app owns any AX window, or nil when the state cannot be read.
    var hasAnyWindow: Bool? {
        guard AXIsProcessTrusted() else { return nil }

        let axApp = AXUIElementCreateApplication(self.processIdentifier)
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &value)
        guard err == .success, let windows = value as? [AXUIElement] else { return nil }

        return !windows.isEmpty
    }
}
