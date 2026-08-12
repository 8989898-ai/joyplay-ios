# JoyPlay iOS H5 游戏接入 Demo

这个工程展示如何在 Swift + UIKit 应用中接入 JoyPlay H5 游戏，包括全屏、半屏、大半屏三种展示模式、JS 回调接收和充值后余额刷新。

## 环境要求

- Xcode 16 或更高版本
- Swift 5
- UIKit
- iOS 15.6 或更高版本
- 系统框架：Foundation、UIKit、WebKit
- 不依赖 CocoaPods 或其他第三方库

## 先运行 Demo

1. 使用 Xcode 打开 `joyplay-ios.xcodeproj`。
2. 选择 `joyplay-ios` Scheme 和任意 iPhone 模拟器或真机。
3. 运行工程：底部三个普通模式按钮默认选中全屏；中央圆形按钮打开全屏游戏，半屏和大半屏按钮先进入对应场景页。

Demo AppKey 和 Token 允许公开，当前 Demo 用一份源码内的模拟 JSON 表示首页一次取得的三条游戏数据，再通过 `JSONDecoder` 解码。迁移到业务工程时，宿主直接使用后端下发的完整游戏 URL、模式和宽高比，不在客户端拼接 AppKey、Token 或游戏参数。

## 业务工程最小接入

> 业务工程只复制 `joyplay-ios/JoyPlayIntegration/` 目录。不要复制 Demo 页面控制器、导航结构、充值弹窗或资源。

### 需要复制的核心文件

| 文件 | 作用 |
| --- | --- |
| `joyplay-ios/JoyPlayIntegration/GameConfiguration.swift` | 游戏模式、URL 与比例校验、全屏运行时参数、事件名称、充值刷新 JS |
| `joyplay-ios/JoyPlayIntegration/GameWebView.swift` | 宿主唯一入口，负责 WKWebView、后端 URL 加载、布局、JS 回调注册和释放 |

复制整个目录可以避免漏掉依赖文件。复制后在 Xcode 的 File Inspector 中确认两个 Swift 文件都已加入业务 App Target。

### 使用 AI 直接接入

本工程同时提供：

- `AGENTS.md`：约束 AI 只复制核心源码、遵守游戏契约并执行构建验证。
- `INTEGRATION_REQUEST.yaml`：记录目标工程、宿主控制器、后端游戏 URL 来源、关闭方式和充值行为。

先将 `INTEGRATION_REQUEST.yaml` 中所有 `<请填写>` 替换为业务工程真实信息，再让 AI 执行：

> 阅读 `AGENTS.md`、`README.md` 和 `INTEGRATION_REQUEST.yaml`，将 `joyplay-ios/JoyPlayIntegration/` 接入目标工程。不要复制 Demo 页面控制器、背景资源和导航结构；完成后执行目标 Scheme 的无签名模拟器构建，并单独报告尚未完成的真实 H5 验证。

### 游戏 URL 参数

业务接入时由后端下发可直接打开的完整 HTTPS 游戏 URL，宿主转换成 `URL` 后传给 `GameWebView`。后端负责以下参数：

| 参数 | 当前规则 |
| --- | --- |
| `appKey` | 后端加入完整 URL |
| `token` | 后端加入完整 URL |
| `gameId` | 固定为 `gameId=1` |
| `mini` | 全屏 `mini=0`、半屏 `mini=1`、大半屏 `mini=2` |
| `safeTop` | 后端不传；全屏 `GameWebView` 首次布局时追加 `safeTop=1` |
| `paddingBottom` | 后端不传；全屏 `GameWebView` 首次布局时追加当前窗口底部安全距离，单位为 UIKit 点 |
| `isNativeDemo` | 仅 Demo 的三条固定 URL 包含 `isNativeDemo=1`；业务后端默认不传 |

后端 URL 不能预先包含 `safeTop` 或 `paddingBottom`。如果 URL 使用签名，服务端验签规则必须允许客户端追加这两个参数，或将它们排除在签名字段之外。全屏首次加载时追加 `safeTop=1` 和当前底部安全距离；半屏和大半屏直接加载后端 URL，不修改查询参数。

### 添加到业务控制器

`GameWebView` 初始化后调用 `attach(to:)` 即可加入业务容器。该方法会根据展示模式完成外层布局：全屏铺满容器四边，半屏和大半屏贴容器左右及底部。接入方不需要调用 `addSubview` 或自行设置游戏视图约束。

下面代码应加入接入方已有的业务控制器，不要复制 Demo 页面控制器。

#### 方式一：直接接入全屏业务页面

在业务自己的全屏控制器中直接创建 `GameWebView`，全屏模式不传比例：

```swift
private var gameWebView: GameWebView?

private func openFullScreenGame(backendGameURL: URL) {
    guard let gameWebView = GameWebView(
        gameURL: backendGameURL,
        displayMode: .full,
        onEvent: { [weak self] event in
            self?.handleGameEvent(event)
        }
    ) else {
        handleInvalidGameConfiguration()
        return
    }
    gameWebView.attach(to: view)
    self.gameWebView = gameWebView
}
```

宿主收到 `.close` 后，根据自己的导航结构 Pop、Dismiss 或移除游戏视图；核心会在回调前停止游戏。

#### 方式二：直接嵌入业务页面

直播间或语聊房只复制两个核心文件，并把以下最小接入代码放进已有的直播间或语聊房控制器。业务后端返回 `widthHeightRatio`（宽 ÷ 高）后，宿主把完整 URL、模式和原始比例直接传给 `GameWebView`：

```swift
private var gameWebView: GameWebView?

private func openEmbeddedGame(
    backendGameURL: URL,
    displayMode: GameDisplayMode,
    widthHeightRatio: CGFloat
) {
    guard let gameWebView = GameWebView(
        gameURL: backendGameURL,
        displayMode: displayMode,
        widthHeightRatio: widthHeightRatio,
        onEvent: { [weak self] event in
            self?.handleGameEvent(event)
        }
    ) else {
        handleInvalidGameConfiguration()
        return
    }
    gameWebView.attach(to: view)
    self.gameWebView = gameWebView
}

private func handleGameEvent(_ event: GameEvent) {
    switch event {
    case .insufficientBalance, .recharge:
        openAppRechargePage()
    case .close:
        removeEmbeddedGame()
    case .openGameSuccess:
        recordGameOpened()
    }
}

private func removeEmbeddedGame() {
    gameWebView?.stop()
    gameWebView?.removeFromSuperview()
    gameWebView = nil
}
```

业务充值成功后调用 `gameWebView?.notifyGameBalanceDidChange()`。宿主主动退出直播间或语聊房时也调用 `removeEmbeddedGame()`；收到 `.close` 时核心已经先执行 `stop()`，再次调用是安全的。

例如后端返回 `widthHeightRatio=1.0` 时，内部 `WKWebView` 为 `1:1`；返回约 `0.6667` 时，`WKWebView` 高度约为宽度的 `1.5` 倍。半屏和大半屏的外层 `GameWebView` 底部贴屏幕底部，高度为 `WKWebView` 高度加底部安全距离；`WKWebView` 顶部与外层顶部对齐，底部安全区域显示外层黑色背景。

`GameWebView` 是可失败初始化：它会在内部拒绝非 HTTPS、缺少主机名、预先包含 `safeTop` 或 `paddingBottom` 的 URL；半屏和大半屏还会拒绝缺少、小于等于零、无限或非数字的比例，全屏则不接收比例。初始化返回 `nil` 时如何提示或重试由业务宿主决定，核心不写死兜底 URL 或比例。

直接嵌入全屏时使用 `.full` 且不传 `widthHeightRatio`，让 `GameWebView` 约束到页面四条边。比例只控制嵌入模式的原生容器高度；`mini` 已包含在后端 URL 中。

### 统一事件回调

`onEvent` 会把所有已注册的 JS 回调传给宿主：

| H5 消息名称 | `GameEvent` | 含义 |
| --- | --- | --- |
| `recharge` | `.insufficientBalance` | 用户下注时余额不足 |
| `clickRecharge` | `.recharge` | 用户主动点击充值 |
| `newTppClose` | `.close` | 用户关闭游戏 |
| `OpenGameSucc` | `.openGameSuccess` | 游戏加载成功 |

前面的最小接入示例已经处理全部四类事件。`newTppClose` 到达时，`GameWebView` 会先停止加载并移除 JS handler，再发送 `.close` 事件。宿主只需要决定是移除视图、Pop 页面还是执行自己的场景关闭逻辑。

### 充值处理

`GameWebView` 只上报 `.insufficientBalance` 和 `.recharge`，核心源码不展示充值 UI。宿主应在这两个事件中打开自己的充值页面。

业务 App 充值成功后，通过以下方法通知游戏刷新余额：

```swift
gameWebView?.notifyGameBalanceDidChange()
```

该方法会执行：

```javascript
HttpTool.NativeToJs('recharge')
```

充值页面、取消行为和失败提示都由宿主决定。核心不包含充值文案，因此接入其他业务工程时不需要复制 Demo 的充值本地化资源。

### 主动关闭与释放

如果是宿主主动退出页面，而不是收到 `newTppClose`，请先停止 WebView，再移除它：

```swift
gameWebView?.stop()
gameWebView?.removeFromSuperview()
gameWebView = nil
```

`stop()` 会停止页面加载并注销全部 JS 消息 handler。全屏页面可在 Pop 前调用；嵌入式页面可在场景退出或重新创建游戏前调用。

### 接入检查清单

- 核心 Swift 文件已加入业务 App Target。
- 后端下发的游戏 URL 直接传给 `GameWebView`；初始化失败时已按业务要求提示或重试。
- 半屏和大半屏将后端 `widthHeightRatio` 直接传给 `GameWebView`，全屏不传比例。
- 后端为全屏、半屏和大半屏 URL 分别提供正确的 `mini=0/1/2`。
- 全屏追加 `safeTop=1` 和当前设备的 `paddingBottom`，半屏和大半屏不修改 URL。
- 四个 `GameEvent` 均已按业务需要处理。
- 宿主在充值事件中展示自己的充值 UI，并在充值成功后通知游戏。
- 主动退出场景时调用了 `stop()`。
- 使用真实 H5 环境验证游戏渲染、关闭和充值回调。

## Demo 实现参考

以下内容只用于让本仓库 Demo 可以直接运行，不属于业务接入代码。接入方不需要复制这些文件，也不应照搬其中的导航和充值策略。

| 文件 | Demo 中的作用 |
| --- | --- |
| `joyplay-ios/DemoGameConfiguration.swift` | 模拟 JSON、解码后的三条游戏数据、模式文案、图标和背景配置 |
| `joyplay-ios/DemoRechargePromptPresenter.swift` | 演示充值提示弹窗 |
| `joyplay-ios/DemoGameLaunchButton.swift` | 共用的圆形游戏启动按钮和呼吸动画 |
| `joyplay-ios/FullScreenGameViewController.swift` | 全屏游戏的导航 Push 示例 |
| `joyplay-ios/GameModeSelectionViewController.swift` | 三种普通模式按钮和全屏启动入口示例 |
| `joyplay-ios/PartialGameViewController.swift` | 半屏与大半屏场景、延迟加载和关闭后重开示例 |
| `joyplay-ios/Localizable.xcstrings` | Demo 页面中英文文案 |
| `joyplay-ios/Assets.xcassets` | Demo 按钮颜色和场景背景图 |

### Demo 数据流

`DemoGameDataSource.mockBackendResponseJSON` 是一份顶层数组形式的模拟响应，不代表正式后端协议。它直接展示三条完整 URL、展示模式和比例，再由 `JSONDecoder` 解码成 `[DemoGameData]`。App 启动后，首页 `GameModeSelectionViewController` 读取解码结果；客户端不通过 AppKey、Token 或模式代码动态拼接 URL。每条数据包含：

- 后端完整游戏 URL。
- 展示模式 `displayMode`。
- 后端原始 `widthHeightRatio`；全屏为 `nil`，半屏和大半屏为有效的宽 ÷ 高比例。

模式选择页只按模式取出对应数据并传给后续控制器。全屏、半屏和大半屏页面不再接收 AppKey、Token，也不再自行拼接 URL。业务工程可把后端 JSON 字典解码成等价的强类型数据，再将三个字段直接传给 `GameWebView`。

### Demo 页面行为

- `FullScreenGameViewController` 隐藏导航栏，收到 `.close` 后执行 Pop。
- `PartialGameViewController` 在当前场景嵌入游戏，收到 `.close` 后只移除游戏视图。
- 两个页面都使用 `DemoRechargePromptPresenter` 展示演示弹窗；点击“通知游戏”后调用 `notifyGameBalanceDidChange()`。

## 本工程验证命令

配置契约测试：

```sh
swiftc -module-cache-path /tmp/joyplay-module-cache \
  joyplay-ios/JoyPlayIntegration/GameConfiguration.swift Tests/main.swift \
  -o /tmp/joyplay-tests && /tmp/joyplay-tests
```

Demo 展示策略测试：

```sh
swiftc -module-cache-path /tmp/joyplay-demo-module-cache \
  joyplay-ios/JoyPlayIntegration/GameConfiguration.swift \
  joyplay-ios/DemoGameConfiguration.swift \
  Tests/DemoConfigurationTests.swift \
  -o /tmp/joyplay-demo-tests && /tmp/joyplay-demo-tests
```

无签名模拟器构建：

```sh
xcodebuild -project joyplay-ios.xcodeproj \
  -scheme joyplay-ios \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/joyplay-derived-data \
  build CODE_SIGNING_ALLOWED=NO
```
