//
//  Permissions.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/21.
//

import Combine

class Permissions {
    let accessibility = AccessibilityMonitor()

    var isOK: any AsyncSequence<Bool, Never> {
        accessibility.updates()
    }
}
