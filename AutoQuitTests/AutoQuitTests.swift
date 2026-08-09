import AppKit
import Foundation
import Testing

@testable import AutoQuit

struct AutoQuitTests {

    @Test func closeConditionsMatchTheirDocumentedBehavior() {
        #expect(AppCloseCondition.doNothing.shouldQuit(hasAnyWindow: false) == false)
        #expect(AppCloseCondition.always.shouldQuit(hasAnyWindow: true) == true)
        #expect(AppCloseCondition.whenNoWindows.shouldQuit(hasAnyWindow: false) == true)
        #expect(AppCloseCondition.whenNoWindows.shouldQuit(hasAnyWindow: true) == false)
        #expect(AppCloseCondition.whenNoWindows.shouldQuit(hasAnyWindow: nil) == false)
    }

    @MainActor
    @Test func appRulesDefaultToDoNothingAndPersistSelections() throws {
        let suiteName = "AutoQuitTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AppRuleStore(defaults: defaults)
        #expect(store.condition(for: "com.example.App") == .doNothing)

        store.setCondition(.whenNoWindows, for: "com.example.App")

        let restoredStore = AppRuleStore(defaults: defaults)
        #expect(restoredStore.condition(for: "com.example.App") == .whenNoWindows)

        restoredStore.setCondition(.doNothing, for: "com.example.App")
        #expect(restoredStore.rules.isEmpty)
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
