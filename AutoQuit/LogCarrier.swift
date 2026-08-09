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
    public static let shared: Logger = addLogger(category: nil)
}

@discardableResult
private func addLogger(_ key: String, _ logger: Logger) -> Logger {
    if let old = Loggers[key] {
        return old
    }

    Loggers[key] = logger
    return logger
}

@discardableResult
private func addLogger(category: String?) -> Logger {
    let category = category ?? SharedLoggerKey
    let logger = Logger(subsystem: "me.afuture.autoQuit", category: category)
    return addLogger(category, logger)
}

private func getLogger(category: String?) -> Logger {
    if let category, let logger = Loggers[category] {
        return logger
    }
    return addLogger(category: nil)
}

public protocol LogCarrier {
    static var category: String { get }
}

extension LogCarrier {
    public static var logger: Logger { getLogger(category: category) }
    public var logger: Logger { getLogger(category: Self.category) }
}
