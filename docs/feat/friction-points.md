# 用户摩擦点与恢复路径

先按可见症状定位问题，再执行当前产品提供的恢复步骤。

## 快速定位

**规则配置**

- [General 一直显示未授权](#permission-not-granted)
- [APP Rules 无法加载](#app-rules-load-failed)
- [新的规则没有保存](#app-rule-save-failed)
- [APP Rules 中找不到目标应用](#app-not-found)

**规则运行**

- [规则已选择，但应用仍在运行](#app-still-running)
- [关闭设置窗口后 AutoQuit 仍在运行](#autoquit-still-running)

**开机启动**

- [开机启动等待系统批准](#launch-at-login-not-enabled)
- [开机启动开关无法保持开启](#launch-at-login-failed)

**软件更新**

- [检查更新或安装新版失败](#update-check-failed)

<a id="permission-not-granted"></a>

## General 一直显示未授权

受影响目标：让 APP Rules 实际执行。

用户会看到：General 显示橙色警告、“未授权”和“请求权限”。

触发条件：用户尚未在 macOS 中开启 AutoQuit，或已撤销权限。

实际影响：所有已保存规则暂停，目标应用继续运行。

规则引用：[`GEN-R-002`](modules/menu-bar-and-settings.md#gen-r-002)、[`APP-R-007`](modules/app-rules.md#app-r-007)

### 恢复步骤

1. 点击“请求权限”，按 macOS 提示前往系统设置。
2. 打开“隐私与安全性 > 辅助功能”，为 AutoQuit 开启权限。
3. 返回 General，确认状态显示已授权。

完成信号：General 显示绿色已授权状态；已有应用规则保持原选择。

相关文档：[General 与运行控制](modules/menu-bar-and-settings.md) / [为一个应用设置自动关闭](journeys/configure-app-auto-quit.md)

<a id="app-rules-load-failed"></a>

## APP Rules 无法加载

受影响目标：查看或编辑应用关闭规则。

用户会看到：“无法加载 APP Rules”、失败说明和“重新加载”，没有可编辑的规则列表。

触发条件：AutoQuit 无法读取当前 Mac 中已保存的规则。

实际影响：加载成功前不能编辑规则，后台对所有应用按“不处理”执行；已保存规则不会被清除。

规则引用：[`APP-R-010`](modules/app-rules.md#app-r-010)

### 恢复步骤

1. 确认当前 Mac 有可用磁盘空间。
2. 点击“重新加载”。
3. 等待应用列表和当前条件出现。

完成信号：加载失败状态消失，APP Rules 显示可编辑的应用列表和已保存条件。再次失败时仍保留“重新加载”。

相关文档：[APP Rules](modules/app-rules.md) / [为一个应用设置自动关闭](journeys/configure-app-auto-quit.md)

<a id="app-rule-save-failed"></a>

## 新的规则没有保存

受影响目标：为应用设置新的关闭条件。

用户会看到：保存进度结束后仍显示原条件，并出现“无法保存规则”。

触发条件：AutoQuit 无法把新选择保存到当前 Mac。

实际影响：失败的选择不会生效；该应用继续使用原规则，其他应用不受影响。

规则引用：[`APP-R-011`](modules/app-rules.md#app-r-011)

### 恢复步骤

1. 关闭“无法保存规则”提示。
2. 确认当前 Mac 有可用磁盘空间。
3. 从该应用的条件菜单重新选择。

完成信号：保存进度结束后，该行显示新条件且不再出现失败提示。

相关文档：[APP Rules](modules/app-rules.md) / [为一个应用设置自动关闭](journeys/configure-app-auto-quit.md)

<a id="app-not-found"></a>

## APP Rules 中找不到目标应用

受影响目标：为目标应用设置关闭条件。

用户会看到：搜索结果为空，或列表中没有刚安装的应用。

触发条件：搜索文字不匹配、列表尚未刷新，或应用不在系统、全局及当前用户的 Applications 目录中。

实际影响：用户不能从当前列表为该应用选择规则。

规则引用：[`APP-R-001`](modules/app-rules.md#app-r-001)、[`APP-R-008`](modules/app-rules.md#app-r-008)

### 恢复步骤

1. 清除搜索框内容。
2. 点击“刷新应用列表”，等待按钮上的进度结束。
3. 再按应用名称或 Bundle ID 搜索。

完成信号：扫描结束后应用总数和列表已更新，目标应用出现在列表中。应用位于其他目录时，当前没有添加或选择文件入口。

相关文档：[APP Rules](modules/app-rules.md) / [为一个应用设置自动关闭](journeys/configure-app-auto-quit.md)

<a id="app-still-running"></a>

## 规则已选择，但应用仍在运行

受影响目标：让目标应用按规则结束运行。

用户会看到：应用离开前台超过 10 秒后仍在运行；AutoQuit 没有错误或重试提示。

触发条件：以下任一条件成立：权限未授权；规则为“不处理”；应用重新回到前台；“无窗口关闭”读取到仍有窗口或无法读取窗口；应用不是标准前台应用；正常退出请求未结束应用。

实际影响：本次自动关闭未完成，但已保存规则不会丢失。

规则引用：[`APP-R-003`](modules/app-rules.md#app-r-003)、[`APP-R-004`](modules/app-rules.md#app-r-004)、[`APP-R-005`](modules/app-rules.md#app-r-005)、[`APP-R-006`](modules/app-rules.md#app-r-006)、[`APP-R-007`](modules/app-rules.md#app-r-007)

### 恢复步骤

1. 在 General 确认已授权，并在 APP Rules 确认目标应用不是“不处理”。
2. 使用“无窗口关闭”时，关闭目标应用的所有窗口。
3. 让目标应用回到前台，再切换到其他应用并保持超过 10 秒。

完成信号：目标应用结束运行。仍未退出时，当前没有强制退出或应用内诊断入口，需要用户自行退出目标应用。

相关文档：[APP Rules](modules/app-rules.md) / [为一个应用设置自动关闭](journeys/configure-app-auto-quit.md)

<a id="autoquit-still-running"></a>

## 关闭设置窗口后 AutoQuit 仍在运行

受影响目标：停止 AutoQuit。

用户会看到：设置窗口消失，但菜单栏图标仍然存在，应用规则仍可执行。

触发条件：用户关闭了设置窗口，但没有选择“Quit”。

实际影响：关闭窗口只保留后台运行，不等于退出应用。

规则引用：[`GEN-R-004`](modules/menu-bar-and-settings.md#gen-r-004)、[`GEN-R-006`](modules/menu-bar-and-settings.md#gen-r-006)

### 恢复步骤

1. 点击 AutoQuit 菜单栏图标。
2. 选择“Quit”。
3. 确认菜单栏图标消失。

完成信号：AutoQuit 已退出，规则停止执行；权限和规则仍保留。

相关文档：[General 与运行控制](modules/menu-bar-and-settings.md)

<a id="launch-at-login-not-enabled"></a>

## 开机启动等待系统批准

受影响目标：让 AutoQuit 在登录 Mac 后自动运行。

用户会看到：“开机启动”开关显示关闭，并出现需要在 macOS 登录项设置中允许 AutoQuit 的说明和“打开登录项设置”。

触发条件：macOS 要求用户批准 AutoQuit，包括首次启用未获批准，或用户之后在系统登录项设置中撤销允许。

实际影响：后续登录不会自动启动 AutoQuit；当前运行、权限和应用规则不受影响。

规则引用：[`GEN-R-007`](modules/menu-bar-and-settings.md#gen-r-007)

### 恢复步骤

1. 点击“打开登录项设置”。
2. 在 macOS 登录项设置中允许 AutoQuit。
3. 返回 AutoQuit，确认“开机启动”显示开启。

完成信号：开关显示开启；最终自动启动要在下一次登录 Mac 后确认。

相关文档：[General 与运行控制](modules/menu-bar-and-settings.md) / [让 AutoQuit 登录后自动运行](journeys/start-autoquit-at-login.md)

<a id="launch-at-login-failed"></a>

## 开机启动开关无法保持开启

受影响目标：让 AutoQuit 在登录 Mac 后自动运行。

用户会看到：打开“开机启动”后，开关恢复为关闭，且没有系统批准提示或错误详情。

触发条件：macOS 没有启用 AutoQuit 登录项，也没有返回需要批准的状态。

实际影响：后续登录不会自动启动 AutoQuit；当前运行、权限和应用规则不受影响。

规则引用：[`GEN-R-007`](modules/menu-bar-and-settings.md#gen-r-007)

### 恢复步骤

1. 再次打开“开机启动”。
2. 确认开关保持开启。

完成信号：开关显示开启；反复恢复为关闭时，当前没有错误详情或进一步恢复入口。

相关文档：[General 与运行控制](modules/menu-bar-and-settings.md) / [让 AutoQuit 登录后自动运行](journeys/start-autoquit-at-login.md)

<a id="update-check-failed"></a>

## 检查更新或安装新版失败

受影响目标：确认当前版本或安装新版 AutoQuit。

用户会看到：通常会出现检查、授权或安装没有完成的提示，AutoQuit 继续运行当前版本；只读或临时安装位置等场景可能没有错误提示。

触发条件：首个正式版本尚未成功发布、网络不可用、GitHub Releases 更新信息不可访问、发布信息和安装包未通过检查、用户没有完成管理员授权，或 AutoQuit 位于不可写、只读或临时打开位置。

实际影响：本次更新结束；辅助功能授权、开机启动选择和应用规则不受影响。

规则引用：[`UPD-R-003`](modules/software-updates.md#upd-r-003)、[`UPD-R-004`](modules/software-updates.md#upd-r-004)

### 恢复步骤

1. 关闭更新窗口，确认 AutoQuit 仍显示菜单栏图标。
2. 确认 Mac 可以访问 GitHub。
3. 确认 AutoQuit 已移到“应用程序”文件夹，而不是从磁盘映像或临时下载位置直接打开。
4. 从菜单栏重新选择“Check for Updates…”；macOS 请求管理员用户名和密码时，确认请求来自 AutoQuit 的更新操作后再允许。

完成信号：更新窗口报告当前已是最新，或显示可继续安装的新版本。持续失败时，当前没有备用更新源或应用内诊断入口。

相关文档：[软件更新](modules/software-updates.md) / [将 AutoQuit 更新到新版本](journeys/update-autoquit.md)

## 什么时候联系反馈

当前没有应用内反馈入口。完成对应恢复步骤后仍失败时，保留相关目标、General 权限状态、开机启动开关状态和可见结果，避免包含文档内容或其他敏感信息。
