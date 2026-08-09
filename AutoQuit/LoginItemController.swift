import AppKit
import AsyncAlgorithms
import OSLog
import ServiceManagement

final class LoginItemController: LogCarrier {
    static let category = "LoginItem"

    var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    var wasLaunchedAtLogin: Bool {
        let event = NSAppleEventManager.shared().currentAppleEvent
        return event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue
                == keyAELaunchedAsLogInItem
    }

    func openSystemSettingsLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }

    func updates() -> any AsyncSequence<SMAppService.Status, Never> {
        AsyncTimerSequence(interval: .seconds(1), clock: .continuous).map { _ in
            SMAppService.mainApp.status
        }.removeDuplicates()
    }

    func setEnabled(_ isEnabled: Bool) {
        do {
            if isEnabled {
                if SMAppService.mainApp.status == .enabled {
                    try? SMAppService.mainApp.unregister()
                }
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error(
                "Failed to \(isEnabled ? "enable" : "disable") launch at login: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
