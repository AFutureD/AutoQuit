# 让无窗口的 Preview 自动退出

最短路径（已授权）：启动 AutoQuit > 关闭 Preview 全部窗口 > 切换到其他应用 > Preview 离开前台超过 10 秒后结束运行。

## 用户目标

- **触发场景**：用户已经看完 PDF 或图片并关闭窗口，但 Preview 仍留在运行中的应用里。
- **想改变的状态**：无需再次手动退出已经没有窗口的 Preview。
- **预期结果**：当 macOS 正常报告 Preview 的窗口列表为空时，Preview 自动结束运行。

## 前置条件

- **入口出现条件**：macOS 26.0 或以上；AutoQuit 可以启动并显示设置窗口或菜单栏图标。
- **继续操作条件**：AutoQuit 正在运行；辅助功能权限已开启；Preview 正在运行。
- **不满足时**：首次使用或权限缺失时，先完成授权分支；AutoQuit 已退出时先重新启动。

## 实际入口

- **主入口**：启动 AutoQuit。
- **替代入口**：AutoQuit 已在菜单栏运行时，直接从当前 Preview 开始。
- **到达状态**：菜单栏出现 AutoQuit 窗口形图标；Preview 尚未收到退出请求。
- **规则引用**：[`CTL-R-001`](../modules/menu-bar-and-settings.md#ctl-r-001)、[`PAQ-R-001`](../modules/preview-auto-quit.md#paq-r-001)

## 主路径

1. 启动 AutoQuit；如果它已经在菜单栏运行，则从第 2 步开始。
   - 系统反馈：启动后显示无标题设置窗口和菜单栏图标。
   - 数据变化：产品不创建用户设置或运行历史。
   - 规则引用：[`CTL-R-001`](../modules/menu-bar-and-settings.md#ctl-r-001)
2. 关闭 Preview 的全部窗口。
   - 系统反馈：Preview 当前不再显示窗口，但可以暂时继续运行。
   - 数据变化：AutoQuit 不保存窗口关闭记录。
   - 规则引用：[`PAQ-R-003`](../modules/preview-auto-quit.md#paq-r-003)
3. 切换到其他应用。
   - 系统反馈：Preview 离开前台；AutoQuit 不显示倒计时。
   - 数据变化：开始新的 10 秒离开前台周期；该周期不作为用户历史保存。
   - 规则引用：[`PAQ-R-004`](../modules/preview-auto-quit.md#paq-r-004)
4. 保持 Preview 不在前台并等待超过 10 秒。
   - 系统反馈：下一次检查时，如果当前窗口列表被判断为空，Preview 收到正常退出请求；AutoQuit 没有结果通知。
   - 数据变化：AutoQuit 不保存退出结果。
   - 规则引用：[`PAQ-R-004`](../modules/preview-auto-quit.md#paq-r-004)、[`PAQ-R-006`](../modules/preview-auto-quit.md#paq-r-006)

## 分支和失败路径

### 首次使用或权限缺失

- **触发条件**：macOS 尚未为 AutoQuit 开启辅助功能权限。
- **用户看到**：“General”只有“Click Me”，没有权限状态。
- **可执行动作**：点击“Click Me”，按系统入口打开“隐私与安全性 > 辅助功能”，开启 AutoQuit。
- **持久化影响**：macOS 保存授权；AutoQuit 不保存设置副本。
- **结束状态**：返回主路径第 2 步。
- **规则引用**：[`CTL-R-002`](../modules/menu-bar-and-settings.md#ctl-r-002)、[`CTL-R-003`](../modules/menu-bar-and-settings.md#ctl-r-003)

### 等待期间退出 AutoQuit

- **触发条件**：用户选择“Quit”，或 AutoQuit 已不在运行。
- **用户看到**：菜单栏图标消失；Preview 继续运行，AutoQuit 没有中断提示。
- **可执行动作**：重新启动 AutoQuit，确认菜单栏图标出现，再让 Preview 回到前台后重新切换离开。
- **持久化影响**：不会保存未完成的等待；macOS 权限不由退出 AutoQuit 撤销。
- **结束状态**：回到主路径第 2 步或第 3 步。
- **规则引用**：[`CTL-R-006`](../modules/menu-bar-and-settings.md#ctl-r-006)、[`PAQ-R-004`](../modules/preview-auto-quit.md#paq-r-004)

### 等待期间撤销权限

- **触发条件**：用户在 macOS 中关闭 AutoQuit 的辅助功能权限。
- **用户看到**：AutoQuit 没有权限错误；Preview 保持运行。
- **可执行动作**：在系统设置中重新开启权限，让 Preview 回到前台后重新切换离开。
- **持久化影响**：macOS 保存新的权限状态；AutoQuit 不保存失败记录。
- **结束状态**：回到主路径第 3 步。
- **规则引用**：[`PAQ-R-005`](../modules/preview-auto-quit.md#paq-r-005)

### Preview 仍有窗口

- **触发条件**：检查时，macOS 成功返回至少一个 Preview 窗口。
- **用户看到**：等待超过 10 秒后 Preview 仍在运行，AutoQuit 没有提示。
- **可执行动作**：让 Preview 回到前台，关闭全部窗口，再切换离开。
- **持久化影响**：不会创建待处理任务或退出记录。
- **结束状态**：回到主路径第 3 步。
- **规则引用**：[`PAQ-R-003`](../modules/preview-auto-quit.md#paq-r-003)

### Preview 再次回到前台或等待不足

- **触发条件**：Preview 在等待期间重新成为当前应用，或离开前台尚未超过 10 秒。
- **用户看到**：Preview 继续运行，没有倒计时。
- **可执行动作**：再次切换离开并完成新的 10 秒周期。
- **持久化影响**：上一次等待不会形成用户可查看的记录。
- **结束状态**：回到主路径第 3 步。
- **规则引用**：[`PAQ-R-004`](../modules/preview-auto-quit.md#paq-r-004)

### Preview 收到请求后仍在运行

- **触发条件**：正常退出请求没有结束 Preview。
- **用户看到**：Preview 仍处于运行状态；AutoQuit 没有失败提示或重试按钮。
- **可执行动作**：让 Preview 回到前台、确认窗口关闭，再切换离开以形成新的 10 秒周期。
- **持久化影响**：不会创建失败记录或手动重试项。
- **结束状态**：回到主路径第 3 步；当前没有强制退出入口。
- **规则引用**：[`PAQ-R-006`](../modules/preview-auto-quit.md#paq-r-006)

### 窗口读取错误

- **触发条件**：权限可用，但 macOS 返回窗口读取错误、无值或产品无法使用的列表。
- **用户看到**：Preview 可能在仍有窗口时收到退出请求；AutoQuit 没有错误提示。
- **可执行动作**：如果 Preview 关闭，重新启动 Preview；需要阻止后续自动处理时，从菜单栏退出 AutoQuit。
- **持久化影响**：不会保存错误或退出记录。
- **结束状态**：当前没有忽略本次检查的入口；AutoQuit 本身不恢复已关闭的 Preview。
- **规则引用**：[`PAQ-R-007`](../modules/preview-auto-quit.md#paq-r-007)

## 持久化结果

- **成功后**：Preview 结束运行；AutoQuit 不保存退出历史。macOS 保存的辅助功能授权可供后续运行使用。
- **取消或失败后**：不会创建待退出任务、失败记录或通知；退出 AutoQuit 后，未完成的等待不会保留。
- **后续消费者**：下一次 Preview 运行时，AutoQuit 根据当时可读到的前台与窗口状态重新判断。
- **数据流**：[辅助功能授权与 Preview 当前状态](../data-flows.md)

## 用户可见的完成状态

- **完成信号**：Preview 未固定在 Dock 时，其图标从 Dock 消失；已固定时，图标下方的运行指示点消失。
- **尚未完成的区别**：只关闭窗口、只切换应用、只完成授权或只达到 10 秒都不是独立完成信号；AutoQuit 也不会显示中间状态。

## 下一目标

下次使用 Preview 时，保持 AutoQuit 在菜单栏运行即可继续使用[Preview 自动退出](../modules/preview-auto-quit.md)。

## 涉及模块与数据

- [Preview 自动退出](../modules/preview-auto-quit.md)
- [菜单栏与设置](../modules/menu-bar-and-settings.md)
- [业务数据结构与流转](../data-flows.md)
- [用户摩擦点与恢复路径](../friction-points.md)
