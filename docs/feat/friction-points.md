# 用户摩擦点与恢复路径

先按可见症状定位问题，再执行当前产品提供的恢复步骤。

## 快速定位

**权限与范围**

- [不知道“Click Me”有什么作用](#click-me-purpose-unclear)
- [AutoQuit 窗口没有显示权限状态](#permission-status-hidden)
- [其他应用没有自动退出](#other-apps-stay-running)

**运行结果**

- [Preview 超过 10 秒仍在运行](#preview-still-running)
- [Preview 仍有窗口却被请求退出](#preview-windowed-exit)
- [关闭设置窗口后 AutoQuit 仍在运行](#autoquit-still-running)

<a id="click-me-purpose-unclear"></a>

## 不知道“Click Me”有什么作用

受影响目标：首次启用 Preview 自动退出。

用户会看到：“General”只有“Click Me”，没有用途说明。

触发条件：用户尚未了解该按钮只用于请求 macOS 辅助功能授权。

实际影响：用户可能无法开始授权，或误以为点击按钮已经完成设置。

规则引用：[`CTL-R-002`](modules/menu-bar-and-settings.md#ctl-r-002)

### 恢复步骤

1. 点击“Click Me”，按 macOS 提供的入口前往系统设置。
2. 打开“隐私与安全性 > 辅助功能”。
3. 为 AutoQuit 开启权限。

完成信号：macOS 系统设置显示 AutoQuit 权限已开启；AutoQuit 自身没有成功提示。

相关文档：[菜单栏与设置](modules/menu-bar-and-settings.md) / [让无窗口的 Preview 自动退出](journeys/automatically-quit-preview.md)

<a id="permission-status-hidden"></a>

## AutoQuit 窗口没有显示权限状态

受影响目标：确认自动退出是否已经准备好。

用户会看到：“General”始终只显示“Click Me”，没有已授权、未授权或错误状态。

触发条件：当前版本没有应用内权限状态组件。

实际影响：用户不能从 AutoQuit 窗口判断授权是否生效。

规则引用：[`CTL-R-002`](modules/menu-bar-and-settings.md#ctl-r-002)、[`CTL-R-003`](modules/menu-bar-and-settings.md#ctl-r-003)

### 恢复步骤

1. 打开 macOS“系统设置 > 隐私与安全性 > 辅助功能”。
2. 找到 AutoQuit，确认开关已经开启。
3. 保持 AutoQuit 在菜单栏运行，用无窗口的 Preview 验证结果。

完成信号：系统设置显示权限开启；AutoQuit 当前没有单独的应用内完成信号。

相关文档：[菜单栏与设置](modules/menu-bar-and-settings.md) / [让无窗口的 Preview 自动退出](journeys/automatically-quit-preview.md)

<a id="other-apps-stay-running"></a>

## 其他应用没有自动退出

受影响目标：让 Preview 以外的应用自动退出。

用户会看到：其他应用即使离开前台且没有窗口，也继续运行。

触发条件：当前固定目标只有 macOS 自带的 Preview。

实际影响：用户不能为其他应用使用 AutoQuit，也不能添加目标。

规则引用：[`PAQ-R-002`](modules/preview-auto-quit.md#paq-r-002)

### 恢复步骤

当前无恢复或扩展入口。使用 AutoQuit 时只验证 Preview；其他应用需要由用户自行退出。

完成信号：当前产品没有让其他应用进入自动退出的完成信号。

相关文档：[Preview 自动退出](modules/preview-auto-quit.md) / [让无窗口的 Preview 自动退出](journeys/automatically-quit-preview.md)

<a id="preview-still-running"></a>

## Preview 超过 10 秒仍在运行

受影响目标：自动结束已经没有窗口的 Preview。

用户会看到：Preview 仍处于运行状态，AutoQuit 没有错误或重试提示。

触发条件：以下任一条件成立：辅助功能权限未开启；AutoQuit 已退出；Preview 仍在前台或离开不足 10 秒；检查时 macOS 成功返回至少一个窗口；正常退出请求没有结束 Preview。

实际影响：当前这次自动退出没有完成，且没有失败记录或手动重试按钮。

规则引用：[`PAQ-R-003`](modules/preview-auto-quit.md#paq-r-003)、[`PAQ-R-004`](modules/preview-auto-quit.md#paq-r-004)、[`PAQ-R-005`](modules/preview-auto-quit.md#paq-r-005)、[`PAQ-R-006`](modules/preview-auto-quit.md#paq-r-006)

### 恢复步骤

1. 如果菜单栏图标不存在，重新启动 AutoQuit；再在系统设置中确认辅助功能权限开启。
2. 让 Preview 回到前台，并关闭全部窗口。
3. 切换到其他应用，保持 Preview 不在前台并等待超过 10 秒。

完成信号：Preview 未固定在 Dock 时，其图标消失；已固定时，图标下方的运行指示点消失。当前没有应用内成功通知；如果仍未退出，产品没有强制退出入口。

相关文档：[Preview 自动退出](modules/preview-auto-quit.md) / [让无窗口的 Preview 自动退出](journeys/automatically-quit-preview.md)

<a id="preview-windowed-exit"></a>

## Preview 仍有窗口却被请求退出

受影响目标：保留仍有窗口的 Preview。

用户会看到：Preview 在离开前台超过 10 秒后关闭或开始退出，但用户原本仍有窗口。

触发条件：辅助功能权限可用，但 macOS 返回窗口读取错误、无值或产品无法使用的列表；当前版本把这些结果按无窗口处理。

实际影响：AutoQuit 可能向仍有窗口的 Preview 发送正常退出请求，且不会显示错误原因。

规则引用：[`PAQ-R-007`](modules/preview-auto-quit.md#paq-r-007)

### 恢复步骤

1. 如果 Preview 已关闭，重新启动 Preview。
2. 需要阻止后续自动处理时，点击 AutoQuit 菜单栏图标。
3. 选择“Quit”，确认菜单栏图标消失。

完成信号：AutoQuit 已停止；当前没有忽略本次检查或诊断窗口读取错误的入口，AutoQuit 本身不恢复已关闭的 Preview。

相关文档：[Preview 自动退出](modules/preview-auto-quit.md) / [让无窗口的 Preview 自动退出](journeys/automatically-quit-preview.md)

<a id="autoquit-still-running"></a>

## 关闭设置窗口后 AutoQuit 仍在运行

受影响目标：停止 AutoQuit。

用户会看到：设置窗口消失，但菜单栏中的窗口形图标仍然存在，Preview 自动退出仍可继续。

触发条件：用户关闭了最后一个设置窗口，但没有从菜单栏选择“Quit”。

实际影响：关闭窗口只切换为菜单栏运行，不等于退出应用。

规则引用：[`CTL-R-004`](modules/menu-bar-and-settings.md#ctl-r-004)、[`CTL-R-006`](modules/menu-bar-and-settings.md#ctl-r-006)

### 恢复步骤

1. 点击菜单栏中的窗口形图标。
2. 选择“Quit”。
3. 确认菜单栏图标消失。

完成信号：AutoQuit 已退出，不再读取或自动处理 Preview 状态。

相关文档：[菜单栏与设置](modules/menu-bar-and-settings.md)；当前没有独立的“停止 AutoQuit”旅程。

## 当前支持边界

完成现有恢复步骤后仍失败时，产品内没有进一步恢复或反馈入口。
