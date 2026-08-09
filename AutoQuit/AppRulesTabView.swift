import AppKit
import SwiftUI

struct AppRulesTabView: View {
    @ObservedObject var applicationCatalog: ApplicationCatalog
    @ObservedObject var appRuleStore: AppRuleStore
    @State private var searchText = ""

    private var filteredApplications: [InstalledApplication] {
        guard !searchText.isEmpty else {
            return applicationCatalog.applications
        }

        return applicationCatalog.applications.filter { application in
            application.name.localizedCaseInsensitiveContains(searchText)
                || application.bundleIdentifier?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    private var persistenceIssue: Binding<AppRulePersistenceIssue?> {
        Binding(
            get: { appRuleStore.persistenceIssue },
            set: { issue in
                if issue == nil {
                    appRuleStore.dismissPersistenceIssue()
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("APP Rules")
                        .font(.largeTitle.bold())
                    Text("应用离开前台 10 秒后，根据所选条件决定是否正常关闭。")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task { await applicationCatalog.reload() }
                } label: {
                    if applicationCatalog.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                            .accessibilityLabel("正在刷新应用列表")
                    } else {
                        Label("刷新应用列表", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(applicationCatalog.isRefreshing)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 16)

            rulesContent
        }
        .alert(item: persistenceIssue) { issue in
            Alert(
                title: Text(issue.title),
                message: Text(issue.message),
                dismissButton: .default(Text("好"))
            )
        }
    }

    @ViewBuilder
    private var rulesContent: some View {
        switch appRuleStore.state {
        case .loading:
            Spacer()
            ProgressView("正在加载规则…")
                .frame(maxWidth: .infinity)
            Spacer()
        case .failed(let message):
            ContentUnavailableView {
                Label("无法加载 APP Rules", systemImage: "externaldrive.badge.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("重新加载") {
                    Task { await appRuleStore.load() }
                }
            }
        case .ready:
            List(filteredApplications) { application in
                let applicationIdentifier = application.ruleIdentifier

                ApplicationRuleRow(
                    application: application,
                    isSaving: appRuleStore.isSaving(applicationIdentifier),
                    condition: Binding(
                        get: {
                            appRuleStore.condition(
                                for: applicationIdentifier
                            )
                        },
                        set: { newCondition in
                            Task {
                                await appRuleStore.setCondition(
                                    newCondition,
                                    for: applicationIdentifier
                                )
                            }
                        }
                    )
                )
            }
            .searchable(text: $searchText, prompt: "搜索应用或 Bundle ID")
            .overlay {
                if applicationCatalog.isRefreshing && applicationCatalog.applications.isEmpty {
                    ProgressView("正在扫描应用…")
                } else if filteredApplications.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }

            Text("共 \(applicationCatalog.applications.count) 个应用；新应用默认“不处理”。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
        }
    }
}

private struct ApplicationRuleRow: View {
    let application: InstalledApplication
    let isSaving: Bool
    @Binding var condition: AppCloseCondition

    var body: some View {
        HStack(spacing: 12) {
            ApplicationIconView(applicationURL: application.url)

            VStack(alignment: .leading, spacing: 2) {
                Text(application.name)
                    .lineLimit(1)
                Text(application.bundleIdentifier ?? application.url.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("正在保存规则")
                }

                Picker("关闭条件", selection: $condition) {
                    ForEach(AppCloseCondition.allCases) { condition in
                        Text(condition.title).tag(condition)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 150)
                .disabled(isSaving)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ApplicationIconView: View {
    let applicationURL: URL

    @State private var icon: NSImage?

    var body: some View {
        Group {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "app")
                    .resizable()
                    .scaledToFit()
                    .padding(5)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 32, height: 32)
        .task(id: applicationURL) {
            icon = await ApplicationIconCache.shared.icon(for: applicationURL)
        }
    }
}

actor ApplicationIconCache {
    static let shared = ApplicationIconCache()

    private var cachedIcons: [URL: NSImage] = [:]
    private var missingIcons: Set<URL> = []
    private let loader: @Sendable (URL) -> NSImage?

    init() {
        loader = ApplicationIconCache.loadIcon
    }

    init(loader: @escaping @Sendable (URL) -> NSImage?) {
        self.loader = loader
    }

    func icon(for applicationURL: URL) -> NSImage? {
        if let cachedIcon = cachedIcons[applicationURL] {
            return cachedIcon
        }
        guard !missingIcons.contains(applicationURL), !Task.isCancelled else {
            return nil
        }

        guard let icon = loader(applicationURL) else {
            missingIcons.insert(applicationURL)
            return nil
        }

        cachedIcons[applicationURL] = icon
        return icon
    }

    nonisolated private static func loadIcon(for applicationURL: URL) -> NSImage? {
        guard !Task.isCancelled else { return nil }
        return NSWorkspace.shared.icon(forFile: applicationURL.path)
    }
}

#Preview {
    AppRulesTabView(
        applicationCatalog: ApplicationCatalog(),
        appRuleStore: AppRuleStore()
    )
    .frame(width: 820, height: 560)
}
