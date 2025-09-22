//
//  AppState.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/21.
//

import Combine
import Foundation

@MainActor
class AppState: NSObject, ObservableObject {

    var anyCancelables: Set<AnyCancellable>

    let activitiedMonitor: AppActivitiesMonitor
    let permissions: Permissions

    override init() {
        self.anyCancelables = .init()
        self.activitiedMonitor = .init()
        self.permissions = .init()
    }

    func setup() {

        Task {
            for await ok in permissions.isOK {
                guard ok else { continue }

                activitiedMonitor.setup()
            }
        }

        //        let it = Timer.publish(every: 1.0, on: .main, in: .common)
        //            .autoconnect()
        //            .values
        //
        //        Task {
        //            var tt: Bool = false
        //            for try await _ in it {
        //                let apps = NSWorkspace.shared.runningApplications
        //                apps.forEach { app in
        //                    if app.activationPolicy != .regular { return }
        //
        //                    logger.info("\(app.bundleIdentifier ?? "nil") - isActive: \(app.isActive) - isHidden: \(app.isHidden)")
        //                    logger.info("\(app.bundleIdentifier ?? "nil") - window: \(app.hasAnyWindowAX(promptForAccessIfNeeded: true))")
        //
        //                    if app.bundleIdentifier == "com.apple.Preview" {
        //                        if !tt, app.isActive == false && !app.hasAnyWindowAX() {
        //                            app.terminate()
        //                            tt = true
        //                        }
        //                    }
        //
        //                }
        //            }
        //        }
        //
        //        NSWorkspace.shared.publisher(for: \.runningApplications).sink { apps in
        //            apps.forEach { app in
        //                if app.activationPolicy != .regular { return }
        //
        //                logger.info("\(app.bundleIdentifier ?? "nil") - isActive: \(app.isActive) - isHidden: \(app.isHidden)")
        //                logger.info("\(app.bundleIdentifier ?? "nil") - window: \(app.hasAnyWindowAX(promptForAccessIfNeeded: true))")
        //
        //            }
        //        }.store(in: &anyCancelables)

    }
}
