import Combine
import Foundation

enum AppRuleStoreState: Equatable {
    case loading
    case ready
    case failed(message: String)
}

struct AppRulePersistenceIssue: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
final class AppRuleStore: ObservableObject {
    @Published private(set) var rules: [String: AppCloseCondition] = [:]
    @Published private(set) var state: AppRuleStoreState = .loading
    @Published private(set) var savingApplicationIdentifiers: Set<String> = []
    @Published private(set) var persistenceIssue: AppRulePersistenceIssue?

    private let persistence: any AppRulePersisting
    private var isLoading = false

    init(persistence: (any AppRulePersisting)? = nil) {
        self.persistence = persistence ?? CoreDataAppRulePersistence()
    }

    func load() async {
        guard !isLoading, state != .ready else { return }

        isLoading = true
        state = .loading
        defer { isLoading = false }

        do {
            rules = try await persistence.loadRules()
            state = .ready
        } catch {
            rules = [:]
            state = .failed(
                message: "无法读取已保存的规则。请检查磁盘空间后重试。"
            )
        }
    }

    func condition(for applicationIdentifier: String) -> AppCloseCondition {
        guard state == .ready else { return .doNothing }
        return rules[applicationIdentifier] ?? .doNothing
    }

    func isSaving(_ applicationIdentifier: String) -> Bool {
        savingApplicationIdentifiers.contains(applicationIdentifier)
    }

    func setCondition(
        _ condition: AppCloseCondition,
        for applicationIdentifier: String
    ) async {
        guard state == .ready,
            condition != self.condition(for: applicationIdentifier),
            savingApplicationIdentifiers.insert(applicationIdentifier).inserted
        else { return }

        defer {
            savingApplicationIdentifiers.remove(applicationIdentifier)
        }

        do {
            try await persistence.persist(
                condition,
                for: applicationIdentifier
            )

            if condition == .doNothing {
                rules.removeValue(forKey: applicationIdentifier)
            } else {
                rules[applicationIdentifier] = condition
            }
        } catch {
            persistenceIssue = AppRulePersistenceIssue(
                title: "无法保存规则",
                message: "原来的关闭条件已保留。请重试。"
            )
        }
    }

    func dismissPersistenceIssue() {
        persistenceIssue = nil
    }
}
