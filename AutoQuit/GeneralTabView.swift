import SwiftUI

struct GeneralTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("General")
                        .font(.largeTitle.bold())
                    Text("检查 AutoQuit 正常工作所需的系统权限。")
                        .foregroundStyle(.secondary)
                }

                GroupBox {
                    HStack(spacing: 14) {
                        Image(
                            systemName: appState.accessibilityPermissionGranted
                                ? "checkmark.circle.fill"
                                : "exclamationmark.triangle.fill"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            appState.accessibilityPermissionGranted ? .green : .orange
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("辅助功能权限")
                                .font(.headline)
                            Text(
                                appState.accessibilityPermissionGranted
                                    ? "已授权，可以按 APP Rules 处理应用。"
                                    : "未授权，AutoQuit 暂时不会关闭任何应用。"
                            )
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if !appState.accessibilityPermissionGranted {
                            Button("请求权限") {
                                appState.permissions.accessibility
                                    .checkPermissionAndPromptIfNeeded()
                            }
                        }
                    }
                    .padding(6)
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(28)
        }
    }
}

#Preview {
    GeneralTabView()
        .environmentObject(AppState())
        .frame(width: 760, height: 500)
}
