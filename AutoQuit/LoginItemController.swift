import AppKit
import AsyncAlgorithms
import OSLog
import ServiceManagement

extension SMAppService.Status: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notRegistered:
            "notRegistered"
        case .enabled:
            "enabled"
        case .requiresApproval:
            "requiresApproval"
        case .notFound:
            "notFound"
        @unknown default:
            "@unknown"
        }
    }
}


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

    func updates() -> some AsyncSequence<SMAppService.Status, Never> {
        AsyncTimerSequence(interval: .seconds(1), clock: .continuous)
            .map { _ in
                SMAppService.mainApp.status
            }.removeDuplicates()
    }

    func setEnabled(_ isEnabled: Bool) {
        logger.info("switch to \(isEnabled), when \(String(describing: self.status))")
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
