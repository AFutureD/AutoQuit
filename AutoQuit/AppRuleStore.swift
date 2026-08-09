import Combine
import Foundation

@MainActor
final class AppRuleStore: ObservableObject {
    @Published private(set) var rules: [String: AppCloseCondition]

    private let defaults: UserDefaults
    private let storageKey = "appCloseConditions"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        guard let data = defaults.data(forKey: storageKey),
              let storedRules = try? JSONDecoder().decode(
                  [String: AppCloseCondition].self,
                  from: data
              )
        else {
            self.rules = [:]
            return
        }

        self.rules = storedRules
    }

    func condition(for applicationIdentifier: String) -> AppCloseCondition {
        rules[applicationIdentifier] ?? .doNothing
    }

    func setCondition(
        _ condition: AppCloseCondition,
        for applicationIdentifier: String
    ) {
        if condition == .doNothing {
            rules.removeValue(forKey: applicationIdentifier)
        } else {
            rules[applicationIdentifier] = condition
        }

        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
