# AutoQuit 功能全景

> 适用版本：AutoQuit 1.0；macOS 26.0 及以上；基于 2026-08-09 的当前构建与运行行为。

AutoQuit 只处理 macOS 自带的 Preview。Preview 离开前台超过 10 秒后，AutoQuit 检查它当前的窗口列表；当产品把该列表判断为无窗口时，会请求 Preview 正常退出。

## 立即开始

1. 启动 AutoQuit。
2. 如果尚未授权，在“General”中点击“Click Me”，再按 macOS 提供的入口开启辅助功能权限。
3. 关闭 Preview 的所有窗口。
4. 切换到其他应用。
5. 保持 Preview 不在前台，等待超过 10 秒。

完成信号：Preview 未固定在 Dock 时，其图标从 Dock 消失；已固定时，图标下方的运行指示点消失。AutoQuit 不显示倒计时、完成通知或退出记录。

## 功能模块

### Preview 自动退出

用户目标：让已经没有窗口的 Preview 在离开前台后自动结束运行。

入口与前置条件：启动 AutoQuit 并保持运行；首次使用或权限缺失时，先通过“General > Click Me”前往 macOS 辅助功能设置完成授权。

该模块拥有固定目标、10 秒起算方式、窗口判断、正常退出请求和失败恢复规则。当前窗口读取错误会被产品按“无窗口”处理，详见模块限制。

[查看 Preview 自动退出详情](modules/preview-auto-quit.md)

### 菜单栏与设置

用户目标：打开权限入口、关闭设置窗口后继续后台运行，或明确退出 AutoQuit。

入口与前置条件：启动 AutoQuit 后使用无标题设置窗口；关闭窗口后使用菜单栏中的窗口形图标。

当前设置只有“General”标签和“Click Me”按钮。菜单提供“Preferences”和“Quit”；关闭设置窗口不会退出 AutoQuit。

[查看菜单栏与设置详情](modules/menu-bar-and-settings.md)

## 主要用户旅程

- [让无窗口的 Preview 自动退出](journeys/automatically-quit-preview.md)：已授权用户从启动 AutoQuit 开始；首次使用者先完成一次系统授权，最终看到 Preview 结束运行。

## 核心业务数据

- [辅助功能授权](data-flows.md#accessibility-authorization)：由用户在 macOS 系统设置中授予或撤销，供 AutoQuit 读取 Preview 当前状态。
- [Preview 当前状态](data-flows.md#preview-current-state)：由 Preview 是否运行、是否在前台和当前窗口列表组成；AutoQuit 不把这些状态保存为历史。

## 数据如何连接功能

```mermaid
flowchart LR
    A["macOS 辅助功能授权"] --> C["退出检查"]
    B["Preview 当前状态"] --> C
    C --> D["请求 Preview 正常退出"]
```

## 遇到卡点

按“Click Me 用途不明”“权限状态不可见”“Preview 没有退出或意外退出”“关闭窗口后 AutoQuit 仍在运行”等症状，查看[用户摩擦点与恢复路径](friction-points.md)。

## 文档边界

AutoQuit 自身的界面文案为英文；macOS 系统提示会使用系统语言。产品没有目标应用选择、等待时间设置、权限状态显示、退出通知、操作历史、开机启动设置、暂停开关或应用内反馈入口。
