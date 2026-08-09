import AppKit
import CoreData
import Foundation
import Testing

@testable import AutoQuit

struct AutoQuitTests {

    @MainActor
    @Test func launchAtLoginDoesNotOpenPreferences() {
        #expect(AppDelegate.shouldOpenPreferences(wasLaunchedAtLogin: false))
        #expect(AppDelegate.shouldOpenPreferences(wasLaunchedAtLogin: true) == false)
    }

    @Test func closeConditionsMatchTheirDocumentedBehavior() {
        #expect(AppCloseCondition.doNothing.shouldQuit(hasAnyWindow: false) == false)
        #expect(AppCloseCondition.always.shouldQuit(hasAnyWindow: true) == true)
        #expect(AppCloseCondition.whenNoWindows.shouldQuit(hasAnyWindow: false) == true)
        #expect(AppCloseCondition.whenNoWindows.shouldQuit(hasAnyWindow: true) == false)
        #expect(AppCloseCondition.whenNoWindows.shouldQuit(hasAnyWindow: nil) == false)
    }

    @MainActor
    @Test func appRulesDefaultToDoNothingAndPersistSelections() async throws {
        let container = CoreDataAppRulePersistence.makeContainer(inMemory: true)
        let persistence = CoreDataAppRulePersistence(container: container)
        let store = AppRuleStore(persistence: persistence)

        await store.load()

        #expect(store.state == .ready)
        #expect(store.condition(for: "com.example.App") == .doNothing)

        await store.setCondition(.whenNoWindows, for: "com.example.App")
        await store.setCondition(.always, for: "com.example.OtherApp")

        let restoredStore = AppRuleStore(
            persistence: CoreDataAppRulePersistence(container: container)
        )
        await restoredStore.load()

        #expect(restoredStore.condition(for: "com.example.App") == .whenNoWindows)
        #expect(restoredStore.condition(for: "com.example.OtherApp") == .always)

        await restoredStore.setCondition(.always, for: "com.example.App")
        var records = try container.viewContext.fetch(AppRuleRecord.fetchRequest())
        #expect(records.count == 2)

        await restoredStore.setCondition(.doNothing, for: "com.example.App")
        records = try container.viewContext.fetch(AppRuleRecord.fetchRequest())
        #expect(records.count == 1)
        #expect(restoredStore.condition(for: "com.example.App") == .doNothing)
        #expect(restoredStore.condition(for: "com.example.OtherApp") == .always)
    }

    @MainActor
    @Test func appRuleStoreSkipsUnchangedConditions() async {
        let persistence = AppRulePersistenceDouble(
            rules: ["com.example.App": .always]
        )
        let store = AppRuleStore(persistence: persistence)

        await store.load()
        await store.setCondition(.always, for: "com.example.App")

        #expect(persistence.persistCallCount == 0)
        #expect(store.condition(for: "com.example.App") == .always)
    }

    @MainActor
    @Test func appRuleStoreCanRetryAfterLoadFailure() async {
        let persistence = AppRulePersistenceDouble(
            rules: ["com.example.App": .whenNoWindows]
        )
        persistence.remainingLoadFailures = 1
        let store = AppRuleStore(persistence: persistence)

        await store.load()
        guard case .failed = store.state else {
            Issue.record("Expected the first load to fail")
            return
        }
        #expect(store.condition(for: "com.example.App") == .doNothing)

        await store.load()

        #expect(store.state == .ready)
        #expect(store.condition(for: "com.example.App") == .whenNoWindows)
        #expect(persistence.loadCallCount == 2)
    }

    @MainActor
    @Test func appRuleStoreKeepsTheOldConditionWhenSavingFails() async {
        let persistence = AppRulePersistenceDouble(
            rules: ["com.example.App": .whenNoWindows]
        )
        persistence.shouldFailPersistence = true
        let store = AppRuleStore(persistence: persistence)

        await store.load()
        await store.setCondition(.always, for: "com.example.App")

        #expect(store.condition(for: "com.example.App") == .whenNoWindows)
        #expect(store.savingApplicationIdentifiers.isEmpty)
        #expect(store.persistenceIssue != nil)
        #expect(persistence.persistCallCount == 1)
    }

    @MainActor
    @Test func appRuleStorePublishesSavingStateWhilePersistenceIsInFlight() async {
        let persistence = AppRulePersistenceDouble(rules: [:])
        persistence.persistenceDelay = .milliseconds(100)
        let store = AppRuleStore(persistence: persistence)

        await store.load()
        let saveTask = Task {
            await store.setCondition(.always, for: "com.example.App")
        }
        await Task.yield()

        #expect(store.isSaving("com.example.App"))

        await saveTask.value
        #expect(store.isSaving("com.example.App") == false)
        #expect(store.condition(for: "com.example.App") == .always)
    }

    @MainActor
    @Test func coreDataPersistenceRollsBackAfterSaveFailure() async throws {
        let container = CoreDataAppRulePersistence.makeContainer(inMemory: true)
        let context = container.newBackgroundContext()
        let persistence = CoreDataAppRulePersistence(
            container: container,
            context: context
        )
        _ = try await persistence.loadRules()

        await context.perform {
            _ = AppRuleRecord(context: context)
        }

        var didThrow = false
        do {
            try await persistence.persist(.always, for: "com.example.App")
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        let hasChanges = await context.perform { context.hasChanges }
        let records = try await context.perform {
            try context.fetch(AppRuleRecord.fetchRequest())
        }
        #expect(hasChanges == false)
        #expect(records.isEmpty)
    }

    @MainActor
    @Test func applicationCatalogPublishesEveryCompletedRefresh() async {
        let firstApplication = InstalledApplication(
            id: "first",
            name: "First",
            bundleIdentifier: "com.example.first",
            url: URL(fileURLWithPath: "/Applications/First.app")
        )
        let secondApplication = InstalledApplication(
            id: "second",
            name: "Second",
            bundleIdentifier: "com.example.second",
            url: URL(fileURLWithPath: "/Applications/Second.app")
        )
        let loader = ApplicationCatalogLoader(
            results: [[firstApplication], [secondApplication]]
        )
        let catalog = ApplicationCatalog(
            automaticallyLoads: false,
            loader: { loader.load() }
        )

        await catalog.reload()
        #expect(catalog.applications == [firstApplication])

        await catalog.reload()
        #expect(catalog.applications == [secondApplication])
        #expect(loader.loadCount == 2)
    }

    @MainActor
    @Test func applicationCatalogReloadDoesNotBlockTheMainActor() async {
        let loader = ApplicationCatalogLoader(results: [[]], delay: 0.4)
        let catalog = ApplicationCatalog(
            automaticallyLoads: false,
            loader: { loader.load() }
        )
        let clock = ContinuousClock()
        let start = clock.now

        let refreshTask = Task { await catalog.reload() }
        for _ in 0..<20 where !catalog.isRefreshing {
            await Task.yield()
        }

        let timeUntilMainActorResponded = start.duration(to: clock.now)
        #expect(catalog.isRefreshing)
        #expect(timeUntilMainActorResponded < .milliseconds(200))

        await refreshTask.value
        #expect(catalog.isRefreshing == false)
    }

    @MainActor
    @Test func applicationIconLoadingDoesNotBlockTheMainActorAndCachesMisses() async {
        let loader = ApplicationIconLoader(delay: 0.4)
        let cache = ApplicationIconCache(loader: { url in loader.load(url) })
        let applicationURL = URL(fileURLWithPath: "/Applications/Example.app")
        let clock = ContinuousClock()
        let start = clock.now

        let iconTask = Task { await cache.icon(for: applicationURL) }
        await Task.yield()

        let timeUntilMainActorResponded = start.duration(to: clock.now)
        #expect(timeUntilMainActorResponded < .milliseconds(200))

        _ = await iconTask.value
        _ = await cache.icon(for: applicationURL)
        #expect(loader.loadCount == 1)
    }
}

@MainActor
private final class AppRulePersistenceDouble: AppRulePersisting {
    private(set) var loadCallCount = 0
    private(set) var persistCallCount = 0
    var remainingLoadFailures = 0
    var shouldFailPersistence = false
    var persistenceDelay: Duration?

    private var rules: [String: AppCloseCondition]

    init(rules: [String: AppCloseCondition]) {
        self.rules = rules
    }

    func loadRules() async throws -> [String: AppCloseCondition] {
        loadCallCount += 1

        if remainingLoadFailures > 0 {
            remainingLoadFailures -= 1
            throw AppRulePersistenceDoubleError.expectedFailure
        }

        return rules
    }

    func persist(
        _ condition: AppCloseCondition,
        for applicationIdentifier: String
    ) async throws {
        persistCallCount += 1

        if let persistenceDelay {
            try await Task.sleep(for: persistenceDelay)
        }

        if shouldFailPersistence {
            throw AppRulePersistenceDoubleError.expectedFailure
        }

        if condition == .doNothing {
            rules.removeValue(forKey: applicationIdentifier)
        } else {
            rules[applicationIdentifier] = condition
        }
    }
}

private enum AppRulePersistenceDoubleError: Error {
    case expectedFailure
}

private final class ApplicationCatalogLoader: @unchecked Sendable {
    private let lock = NSLock()
    private var results: [[InstalledApplication]]
    private let delay: TimeInterval
    private var storedLoadCount = 0

    init(results: [[InstalledApplication]], delay: TimeInterval = 0) {
        self.results = results
        self.delay = delay
    }

    var loadCount: Int {
        lock.withLock { storedLoadCount }
    }

    func load() -> [InstalledApplication] {
        if delay > 0 {
            Thread.sleep(forTimeInterval: delay)
        }

        return lock.withLock {
            let index = min(storedLoadCount, results.count - 1)
            storedLoadCount += 1
            return results[index]
        }
    }
}

private final class ApplicationIconLoader: @unchecked Sendable {
    private let lock = NSLock()
    private let delay: TimeInterval
    private var storedLoadCount = 0

    init(delay: TimeInterval) {
        self.delay = delay
    }

    var loadCount: Int {
        lock.withLock { storedLoadCount }
    }

    func load(_ url: URL) -> NSImage? {
        _ = url
        Thread.sleep(forTimeInterval: delay)
        lock.withLock { storedLoadCount += 1 }
        return nil
    }
}
