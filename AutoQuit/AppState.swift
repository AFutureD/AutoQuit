//
//  AppState.swift
//  AutoQuit
//
//  Created by Huanan on 2025/9/21.
//

import Combine
import Foundation
import ServiceManagement
import OSLog

@MainActor
class AppState: NSObject, ObservableObject, LogCarrier {
    static let category: String = "AppState"

    var anyCancelables: Set<AnyCancellable>

    let activitiedMonitor: AppActivitiesMonitor
    let permissions: Permissions
    let applicationManager: ApplicationManager
    let appRuleStore: AppRuleStore
    let applicationCatalog: ApplicationCatalog
    let loginItemController: LoginItemController

    @Published private(set) var accessibilityPermissionGranted: Bool
    @Published var launchAtLoginItemEnabled: Bool

    private var setupLoginItemObs: AnyCancellable?

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
        self.launchAtLoginItemEnabled = loginItemController.status == .enabled

        super.init()
    }

    private var isSetup = false
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
            for await status in loginItemController.updates().dropFirst() {
                self.launchAtLoginItemEnabled = status == .enabled
            }
        }

        Task {
            for await update in activitiedMonitor.updates(idle: 10) {
                guard accessibilityPermissionGranted else { continue }
                applicationManager.shutdown(update.appProcessIdentifier)
            }
        }

        setupLoginItemObs = self.$launchAtLoginItemEnabled
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enable in
                self?.loginItemController.setEnabled(enable)
            }
    }
}

// MARK: AppState + loginItem

extension AppState {

    var loginItemRequiresApproval: Bool {
        loginItemController.status == .requiresApproval
    }

    func openLoginItemSettings() {
        loginItemController.openSystemSettingsLoginItems()
    }

    var wasLaunchedAtLogin: Bool {
        loginItemController.wasLaunchedAtLogin
    }
}
