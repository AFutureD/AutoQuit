//
//  Permissions.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/21.
//

import Combine

class Permissions {
    let accessibility = AccessibilityMonitor()

    var isOK: AsyncStream<Bool> {
        var iterator = accessibility.updates().makeAsyncIterator()
        return AsyncStream {
            await iterator.next()
        }
    }
}
