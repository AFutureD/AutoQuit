//
//  AccessibilityMonitor.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/21.
//

import AppKit
import Combine

extension AccessibilityMonitor {
    struct Updates: AsyncSequence {
        func makeAsyncIterator() -> AsyncPublisher<AnyPublisher<Bool, Never>>.Iterator {
            Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .map { _ in
                    AccessibilityMonitor.hasPermission
                }
                .removeDuplicates()
                .eraseToAnyPublisher()
                .values
                .makeAsyncIterator()
        }
    }
}

class AccessibilityMonitor {
    func updates() -> Updates {
        Updates()
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
