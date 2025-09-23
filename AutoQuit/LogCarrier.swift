//
//  Logger.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/23.
//

import os.log

private var Loggers: [String: Logger] = [:]
private let SharedLoggerKey = "Shared"

extension Logger {
    static let shared: Logger = addLogger(category: nil)
}

@discardableResult
func addLogger(_ key: String, _ logger: Logger) -> Logger {
    if let old = Loggers[key] {
        return old
    }

    Loggers[key] = logger
    return logger
}

@discardableResult
func addLogger(category: String?) -> Logger {
    let category = category ?? SharedLoggerKey
    let logger = Logger(subsystem: "me.afuture.autoQuit", category: category)
    return addLogger(category, logger)
}

public func getLogger(category: String?) -> Logger {
    if let category, let logger = Loggers[category] {
        return logger
    }
    return addLogger(category: nil)
}

protocol LogCarrier {
    static var category: String { get }
}

extension LogCarrier {
    static var logger: Logger { getLogger(category: category) }
    var logger: Logger { getLogger(category: Self.category) }
}
