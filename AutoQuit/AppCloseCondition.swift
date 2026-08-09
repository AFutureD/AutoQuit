import Foundation

enum AppCloseCondition: String, CaseIterable, Codable, Identifiable {
    case doNothing
    case always
    case whenNoWindows

    var id: Self { self }

    var title: String {
        switch self {
        case .doNothing:
            "不处理"
        case .always:
            "无条件关闭"
        case .whenNoWindows:
            "无窗口关闭"
        }
    }

    func shouldQuit(hasAnyWindow: Bool?) -> Bool {
        switch self {
        case .doNothing:
            false
        case .always:
            true
        case .whenNoWindows:
            hasAnyWindow == false
        }
    }
}
