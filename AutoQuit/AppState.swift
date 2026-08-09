//
//  AppState.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/21.
//

import Combine
import Foundation
import ServiceManagement

@MainActor
class AppState: NSObject, ObservableObject {

    var anyCancelables: Set<AnyCancellable>

    let activitiedMonitor: AppActivitiesMonitor
    let permissions: Permissions
    let applicationManager: ApplicationManager
    let appRuleStore: AppRuleStore
    let applicationCatalog: ApplicationCatalog

    @Published private(set) var accessibilityPermissionGranted: Bool
    @Published private(set) var loginItemStatus: SMAppService.Status

    private let loginItemController: LoginItemController
    private var isSetup = false

    override init() {
        let appRuleStore = AppRuleStore()
        let loginItemController = LoginItemController()
        self.anyCancelables = .init()
        self.activitiedMonitor = .init()
        self.permissions = .init()
        self.appRuleStore = appRuleStore
        self.applicationManager = .init(ruleStore: appRuleStore)
        self.applicationCatalog = .init()
        self.accessibilityPermissionGranted = AccessibilityMonitor.hasPermission
        self.loginItemController = loginItemController
        self.loginItemStatus = loginItemController.status

        super.init()
    }

    func setup() {
        guard !isSetup else { return }
        isSetup = true

        Task {
            await appRuleStore.load()
        }

        Task {
            for await ok in permissions.isOK {
                accessibilityPermissionGranted = ok
                guard ok else { continue }

                activitiedMonitor.setup()
            }
        }

        Task {
            for await status in loginItemController.updates() {
                loginItemStatus = status
            }
        }

        Task {
            for await update in activitiedMonitor.updates(idle: 10) {
                guard accessibilityPermissionGranted else { continue }
                applicationManager.shutdown(update.appProcessIdentifier)
            }
        }
    }
}

// MARK: AppState + loginItem

extension AppState {

    var loginItemRequiresApproval: Bool {
        loginItemStatus == .requiresApproval
    }

    func openLoginItemSettings() {
        loginItemController.openSystemSettingsLoginItems()
    }

    var wasLaunchedAtLogin: Bool {
        loginItemController.wasLaunchedAtLogin
    }

    var launchAtLoginEnabled: Bool {
        loginItemStatus == .enabled
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        loginItemController.setEnabled(isEnabled)
    }
}
