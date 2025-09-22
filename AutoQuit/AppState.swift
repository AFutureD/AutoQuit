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
    let applicationManager: ApplicationManager

    override init() {
        self.anyCancelables = .init()
        self.activitiedMonitor = .init()
        self.permissions = .init()
        self.applicationManager = .init()
    }

    func setup() {

        Task {
            for await ok in permissions.isOK {
                guard ok else { continue }

                activitiedMonitor.setup()
            }
        }

        Task {
            for await update in activitiedMonitor.updates(idle: 1) {
                if !update.hasAnyWindow {
                    applicationManager.shutdown(update.appProcessIdentifier)
                }
            }
        }
    }
}
