import CoreData
import Foundation
import os.log

@MainActor
protocol AppRulePersisting: AnyObject {
    func loadRules() async throws -> [String: AppCloseCondition]
    func persist(
        _ condition: AppCloseCondition,
        for applicationIdentifier: String
    ) async throws
}

@objc(AppRuleRecord)
final class AppRuleRecord: NSManagedObject {
    @NSManaged var appID: String
    @NSManaged var quitCondition: String

    @nonobjc class func fetchRequest() -> NSFetchRequest<AppRuleRecord> {
        NSFetchRequest<AppRuleRecord>(entityName: "AppRuleRecord")
    }
}

@MainActor
final class CoreDataAppRulePersistence: AppRulePersisting, LogCarrier {
    static let category = "AppRulePersistence"

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    private var hasLoadedPersistentStores: Bool

    init(
        container: NSPersistentContainer? = nil,
        context: NSManagedObjectContext? = nil
    ) {
        let container = container ?? Self.makeContainer()
        let context = context ?? container.newBackgroundContext()
        self.container = container
        self.context = context
        self.hasLoadedPersistentStores = !container.persistentStoreCoordinator.persistentStores.isEmpty

        container.viewContext.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
    }

    static func makeContainer(inMemory: Bool = false) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "AppRules")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.shouldAddStoreAsynchronously = false
            container.persistentStoreDescriptions = [description]
        }

        return container
    }

    func loadRules() async throws -> [String: AppCloseCondition] {
        try await loadPersistentStoresIfNeeded()

        do {
            let logger = self.logger
            return try await context.perform {
                let records = try self.context.fetch(AppRuleRecord.fetchRequest())
                return records.reduce(into: [:]) { rules, record in
                    guard let condition = AppCloseCondition(rawValue: record.quitCondition),
                        condition != .doNothing
                    else {
                        logger.error(
                            "Ignoring invalid app rule for \(record.appID, privacy: .public)"
                        )
                        return
                    }

                    rules[record.appID] = condition
                }
            }
        } catch {
            logger.error("Failed to fetch app rules: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func persist(
        _ condition: AppCloseCondition,
        for applicationIdentifier: String
    ) async throws {
        try await loadPersistentStoresIfNeeded()

        do {
            try await context.perform {
                let request = AppRuleRecord.fetchRequest()
                request.predicate = NSPredicate(
                    format: "appID == %@",
                    applicationIdentifier
                )

                do {
                    let records = try self.context.fetch(request)

                    if condition == .doNothing {
                        records.forEach(self.context.delete)
                    } else {
                        let record = records.first ?? AppRuleRecord(context: self.context)
                        record.appID = applicationIdentifier
                        record.quitCondition = condition.rawValue

                        for duplicate in records.dropFirst() {
                            self.context.delete(duplicate)
                        }
                    }

                    guard self.context.hasChanges else { return }
                    try self.context.save()
                } catch {
                    self.context.rollback()
                    throw error
                }
            }
        } catch {
            logger.error(
                "Failed to save app rule for \(applicationIdentifier, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
    }

    private func loadPersistentStoresIfNeeded() async throws {
        guard !hasLoadedPersistentStores else { return }

        do {
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Void, Error>) in
                container.loadPersistentStores { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            hasLoadedPersistentStores = true
        } catch {
            logger.error(
                "Failed to load app rule storage: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
    }
}
