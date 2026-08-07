# JoyPlay iOS AI 接入规则

本文件适用于两类任务：维护当前 Demo，以及把 JoyPlay 游戏接入另一个 Swift + UIKit 工程。用户的明确要求始终优先。

## 接入前必须读取

1. 阅读根目录 `README.md`，确认游戏模式、事件、充值和释放规则。
2. 阅读并填写 `INTEGRATION_REQUEST.yaml`。
3. 如果模板中仍有 `<请填写>`，停止接入并向用户确认；不要猜测业务控制器、Token 来源、关闭方式或充值页面。
4. 检查目标工程及其父目录中的其他 `AGENTS.md`，同时遵守目标工程规则。
5. `docs/plans/` 是历史实施记录，可能保留旧文件路径或已被后续需求替代的参数；接入时不要把它作为当前契约，当前契约以 `README.md`、本文件和核心源码为准。

## 可分发核心源码

接入目标工程时，只复制整个 `joyplay-ios/JoyPlayIntegration/` 目录，并确认其中两个 Swift 文件都加入目标 App Target：

- `GameConfiguration.swift`
- `GameWebView.swift`

除非用户明确要求复刻 Demo UI，否则不要复制以下 Demo 专用内容：

- `GameModeTabBarController.swift`
- `GameViewController.swift`
- `ViewController.swift`
- `Localizable.xcstrings`
- `Assets.xcassets` 中的按钮颜色和场景背景图

## 不得擅自改变的接入契约

- 游戏地址由 `GameURLBuilder` 生成。
- `gameId=1`。
- 全屏、半屏、大半屏分别使用 `mini=0`、`mini=1`、`mini=2`。
- 半屏宽高比为 `1:1`，大半屏为 `1:1.5`，并底部对齐安全区。
- H5 消息名称固定为 `recharge`、`clickRecharge`、`newTppClose`、`OpenGameSucc`。
- `newTppClose` 到达后，宿主根据模板选择移除游戏视图或 Pop；不要擅自关闭直播间、语聊房等业务控制器。
- 宿主主动退出时调用 `stop()`。
- 自定义充值流程使用 `automaticallyShowsRechargePrompt: false`；充值成功后调用 `notifyGameBalanceDidChange()`。
- Demo AppKey 和 Token 允许公开，不要仅因其出现在源码或日志中而移除。

## AI 接入步骤

1. 根据 `INTEGRATION_REQUEST.yaml` 定位目标工程、Scheme、App Target 和宿主控制器。
2. 复制 `JoyPlayIntegration` 目录，保持两个文件在同一个 Target 中。
3. 根据启用的模式创建 `GameWebView`，不要引入 Demo Tab Bar 或背景资源。
4. 实现全部 `GameEvent` 分支，即使某个事件当前只记录日志。
5. 按模板实现关闭与充值行为。
6. 检查每个主动移除路径都调用 `stop()`。
7. 只修改完成接入所需的目标文件，不重构邻近业务代码。

## 验证要求

先使用 `xcodebuild -list` 确认目标容器和 Scheme，再使用模板指定的 Scheme 进行无签名模拟器构建。例如：

```sh
xcodebuild -project <目标工程.xcodeproj> \
  -scheme <目标Scheme> \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/joyplay-customer-derived-data \
  build CODE_SIGNING_ALLOWED=NO
```

如果目标使用 Workspace，将 `-project` 改为 `-workspace`。构建通过只能证明静态集成成功，不能替代真实 H5 的游戏渲染、四个回调、关闭行为和充值刷新验证。

## 完成报告

AI 完成后必须报告：

- 复制或修改了哪些文件。
- 每种启用模式接入到哪个宿主控制器。
- AppKey、Token、关闭和充值行为来自模板中的哪项配置。
- 执行了哪些测试或 `xcodebuild` 命令及其结果。
- 哪些真实 H5 或视觉验证仍待人工完成。
