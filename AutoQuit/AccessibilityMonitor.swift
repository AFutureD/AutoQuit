//
//  AccessibilityMonitor.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/21.
//

import AppKit
import AsyncAlgorithms
import Combine

class AccessibilityMonitor {
    func updates() -> any AsyncSequence<Bool, Never> {
        AsyncTimerSequence(interval: .seconds(1), clock: .continuous).map { _ in
            AccessibilityMonitor.hasPermission
        }.removeDuplicates()
    }
}

extension AccessibilityMonitor {
    func setup() {

    }
}

extension AccessibilityMonitor {
    private static func checkPermission(prompt: Bool) -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        return AXIsProcessTrustedWithOptions([checkOptPrompt: prompt] as CFDictionary?)
    }
}

extension AccessibilityMonitor {

    static var hasPermission: Bool {
        checkPermission(prompt: false)
    }

    private static func checkPermissionAndPromptIfNeeded() -> Bool {
        checkPermission(prompt: true)
    }

    @discardableResult
    func checkPermissionAndPromptIfNeeded() -> Bool {
        Self.checkPermissionAndPromptIfNeeded()
    }

}
