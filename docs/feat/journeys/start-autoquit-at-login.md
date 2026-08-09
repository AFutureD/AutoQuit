# 让 AutoQuit 登录后自动运行

最短路径：启动 AutoQuit > General > 打开“开机启动” > 下一次登录 Mac 后自动运行。

## 用户目标

- **触发场景**：用户希望每次登录 Mac 后无需手动打开 AutoQuit。
- **想改变的状态**：AutoQuit 只在用户主动启动后才会执行应用规则。
- **预期结果**：下一次登录 Mac 后，AutoQuit 自动启动并继续使用现有权限和规则。

## 前置条件

- **入口出现条件**：macOS 26.0 或以上；AutoQuit 可以启动并显示 General。
- **继续操作条件**：用户可以在当前 Mac 修改自己的登录项。
- **不满足时**：macOS 要求批准时，“开机启动”开关显示关闭，General 显示说明和“打开登录项设置”。

## 实际入口

- **主入口**：启动 AutoQuit > 设置窗口 > “General” > “开机启动”。
- **替代入口**：AutoQuit 已在菜单栏运行时，菜单栏图标 > “Preferences” > “General” > “开机启动”。
- **到达状态**：开关显示 macOS 当前保存的 AutoQuit 登录项状态。
- **规则引用**：[`GEN-R-001`](../modules/menu-bar-and-settings.md#gen-r-001)、[`GEN-R-005`](../modules/menu-bar-and-settings.md#gen-r-005)、[`GEN-R-007`](../modules/menu-bar-and-settings.md#gen-r-007)

## 主路径

1. 启用自动启动：打开“开机启动”。
   - 系统反馈：注册成功后开关保持开启。
   - 数据变化：macOS 保存 AutoQuit 的登录项状态；当前实例继续运行。
   - 规则引用：[`GEN-R-007`](../modules/menu-bar-and-settings.md#gen-r-007)
2. 验证下一次登录：退出登录或重新启动 Mac，再次登录。
   - 系统反馈：AutoQuit 自动显示菜单栏图标，但不打开设置窗口。
   - 数据变化：登录项仍保持开启；AutoQuit 读取已有权限和应用规则并开始运行。
   - 规则引用：[`GEN-R-009`](../modules/menu-bar-and-settings.md#gen-r-009)

## 分支和失败路径

### macOS 要求批准登录项

- **触发条件**：macOS 要求用户批准 AutoQuit，包括首次启用未获批准，或用户之后在系统登录项设置中撤销允许。
- **用户看到**：“开机启动”开关显示关闭，并出现需要在 macOS 允许 AutoQuit 的说明和“打开登录项设置”。
- **可执行动作**：点击“打开登录项设置”，在 macOS 中允许 AutoQuit，再返回应用。
- **持久化影响**：批准前登录项不会自动运行；当前运行、权限和应用规则不受影响。
- **结束状态**：返回 AutoQuit 后开关刷新；显示开启时回到主路径第 2 步。
- **规则引用**：[`GEN-R-007`](../modules/menu-bar-and-settings.md#gen-r-007)

### 开关无法保持开启且没有批准提示

- **触发条件**：macOS 没有启用 AutoQuit 登录项，也没有返回需要批准的状态。
- **用户看到**：“开机启动”开关恢复为关闭，区域仍显示普通说明，没有错误详情。
- **可执行动作**：再次打开开关。
- **持久化影响**：登录项保持原状态；当前运行、权限和应用规则不受影响。
- **结束状态**：开关保持开启后回到主路径第 2 步；反复失败时当前没有进一步恢复入口。
- **规则引用**：[`GEN-R-007`](../modules/menu-bar-and-settings.md#gen-r-007)

### 用户关闭开机启动

- **触发条件**：用户把“开机启动”切换为关闭。
- **用户看到**：开关保持关闭，当前 AutoQuit 不会退出。
- **可执行动作**：需要恢复时重新开启。
- **持久化影响**：macOS 停用登录项；已有权限和应用规则保留。
- **结束状态**：后续登录不再自动启动 AutoQuit，本次旅程取消。
- **规则引用**：[`GEN-R-007`](../modules/menu-bar-and-settings.md#gen-r-007)、[`GEN-R-009`](../modules/menu-bar-and-settings.md#gen-r-009)

### 用户在登录前退出 AutoQuit

- **触发条件**：开机启动已经开启，用户从菜单栏选择“Quit”。
- **用户看到**：当前菜单栏图标消失。
- **可执行动作**：无需额外操作；也可以手动重新启动 AutoQuit。
- **持久化影响**：登录项、辅助功能权限和应用规则继续保留。
- **结束状态**：下一次登录仍会自动启动 AutoQuit。
- **规则引用**：[`GEN-R-006`](../modules/menu-bar-and-settings.md#gen-r-006)、[`GEN-R-009`](../modules/menu-bar-and-settings.md#gen-r-009)

## 持久化结果

- **成功后**：macOS 保存已开启的 AutoQuit 登录项；退出应用或关闭设置窗口不会取消。
- **取消或失败后**：关闭开关会停用登录项；注册失败不会改变原状态。
- **后续消费者**：macOS 在后续登录时读取该状态并决定是否启动 AutoQuit。
- **数据流**：[开机启动选择](../data-flows.md#launch-at-login-setting)

## 用户可见的完成状态

- **完成信号**：重新登录后，无需手动启动即可看到 AutoQuit 菜单栏图标；设置窗口保持关闭。
- **尚未完成的区别**：开关保持开启只表示登录项已保存；首次自动启动要到下一次登录时才能确认。

## 下一目标

从菜单栏选择“Preferences”，前往 [APP Rules](../modules/app-rules.md) 确认需要自动处理的应用规则。

## 涉及模块与数据

- [General 与运行控制](../modules/menu-bar-and-settings.md)
- [`GEN-R-007`](../modules/menu-bar-and-settings.md#gen-r-007)、[`GEN-R-009`](../modules/menu-bar-and-settings.md#gen-r-009)
- [业务数据结构与流转](../data-flows.md)
- [用户摩擦点与恢复路径](../friction-points.md)
