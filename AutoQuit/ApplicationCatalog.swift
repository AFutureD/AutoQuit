import Combine
import Foundation

@MainActor
final class ApplicationCatalog: ObservableObject {
    @Published private(set) var applications: [InstalledApplication] = []
    @Published private(set) var isRefreshing = false

    private let loader: @Sendable () -> [InstalledApplication]

    init(
        automaticallyLoads: Bool = true,
        loader: (@Sendable () -> [InstalledApplication])? = nil
    ) {
        let excludedBundleIdentifier = Bundle.main.bundleIdentifier
        self.loader = loader ?? {
            Self.loadApplications(excluding: excludedBundleIdentifier)
        }

        if automaticallyLoads {
            Task { await reload() }
        }
    }

    func reload() async {
        guard !isRefreshing else { return }
        isRefreshing = true

        let loader = self.loader
        let loadedApplications = await Task.detached(priority: .userInitiated) {
            loader()
        }.value

        applications = loadedApplications
        isRefreshing = false
    }

    nonisolated private static func loadApplications(
        excluding excludedBundleIdentifier: String?
    ) -> [InstalledApplication] {
        let fileManager = FileManager.default
        let searchRoots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true),
        ]

        var applicationsByIdentifier: [String: InstalledApplication] = [:]

        for root in searchRoots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let url as URL in enumerator where url.pathExtension.lowercased() == "app" {
                guard let bundle = Bundle(url: url) else { continue }

                let bundleIdentifier = bundle.bundleIdentifier
                guard bundleIdentifier != excludedBundleIdentifier else { continue }
                let fallbackIdentifier = "path:\(url.standardizedFileURL.path)"
                let identifier = bundleIdentifier ?? fallbackIdentifier
                let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? url.deletingPathExtension().lastPathComponent

                let application = InstalledApplication(
                    id: identifier,
                    name: name,
                    bundleIdentifier: bundleIdentifier,
                    url: url
                )

                if let existing = applicationsByIdentifier[identifier] {
                    if url.path.count < existing.url.path.count {
                        applicationsByIdentifier[identifier] = application
                    }
                } else {
                    applicationsByIdentifier[identifier] = application
                }
            }
        }

        return applicationsByIdentifier.values.sorted {
            let nameOrder = $0.name.localizedStandardCompare($1.name)
            if nameOrder == .orderedSame {
                return $0.url.path.localizedStandardCompare($1.url.path) == .orderedAscending
            }
            return nameOrder == .orderedAscending
        }
    }
}
