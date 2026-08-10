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
3. 运行工程，在底部选择全屏、半屏或大半屏模式。

Demo AppKey 和 Token 允许公开，当前固定值仅用于让接入方直接运行和观察完整 URL。迁移到业务工程时，也可以继续使用接入方约定的固定值，或者由宿主在创建游戏视图时动态传入。

## 文件说明

接入业务工程时，只需要复制核心文件。不要直接复制整个 Demo 页面结构。

| 文件 | 是否必需 | 作用 |
| --- | --- | --- |
| `joyplay-ios/JoyPlayIntegration/GameConfiguration.swift` | 必需 | 游戏模式、URL 参数、事件名称、充值刷新 JS |
| `joyplay-ios/JoyPlayIntegration/GameWebView.swift` | 必需 | WKWebView、URL 加载、JS 回调注册和释放 |
| `joyplay-ios/GameViewController.swift` | 可选 | 全屏游戏的导航 Push 示例 |
| `joyplay-ios/GameModeTabBarController.swift` | 可选 | 三种模式入口以及半屏嵌入示例 |
| `joyplay-ios/Localizable.xcstrings` | 可选 | Demo 页面中英文文案 |
| `joyplay-ios/Assets.xcassets` | 可选 | Demo 按钮颜色和场景背景图 |

接入时建议复制整个 `joyplay-ios/JoyPlayIntegration/` 文件夹，避免漏掉依赖文件。复制后在 Xcode 的 File Inspector 中确认两个 Swift 文件都已加入业务 App Target。

## 使用 AI 直接接入

本工程同时提供：

- `AGENTS.md`：约束 AI 只复制核心源码、遵守游戏契约并执行构建验证。
- `INTEGRATION_REQUEST.yaml`：记录目标工程、宿主控制器、凭证来源、关闭方式和充值行为。

先将 `INTEGRATION_REQUEST.yaml` 中所有 `<请填写>` 替换为业务工程真实信息，再让 AI 执行：

> 阅读 `AGENTS.md`、`README.md` 和 `INTEGRATION_REQUEST.yaml`，将 `joyplay-ios/JoyPlayIntegration/` 接入目标工程。不要复制 Demo Tab Bar、背景资源和导航结构；完成后执行目标 Scheme 的无签名模拟器构建，并单独报告尚未完成的真实 H5 验证。

## 游戏 URL 参数

`GameURLBuilder` 使用 `URLComponents` 生成 `https://joyplay.cn/release/index.html`，参数如下：

| 参数 | 当前规则 |
| --- | --- |
| `appKey` | 创建 `GameWebView` 时传入 |
| `token` | 创建 `GameWebView` 时传入 |
| `gameId` | 固定为 `gameId=1` |
| `mini` | 全屏 `mini=0`、半屏 `mini=1`、大半屏 `mini=2` |
| `isNativeDemo` | 当前 Demo 固定传 `isNativeDemo=1`；业务工程默认不传 |

## 最快接入方式

### 方式一：复用全屏示例控制器

同时复制 `GameViewController.swift` 后，在现有导航控制器中 Push：

```swift
let gameViewController = GameViewController(
    displayMode: .full,
    appKey: GameLaunchCredentials.appKey,
    token: GameLaunchCredentials.token
)
gameViewController.hidesBottomBarWhenPushed = true
navigationController?.pushViewController(gameViewController, animated: true)
```

游戏发送 `newTppClose` 时，示例控制器会自动返回上一页。

### 方式二：直接嵌入业务页面

直播间或语聊房只复制两个核心文件。业务后端返回 `widthHeightRatio`（宽 ÷ 高）后，宿主先校验比例，再直接添加 `GameWebView`：

```swift
private var gameWebView: GameWebView?

private func openEmbeddedGame(
    displayMode: GameDisplayMode,
    widthHeightRatio: CGFloat
) {
    guard let aspectRatio = GameAspectRatio(widthHeightRatio: widthHeightRatio) else {
        return
    }

    let gameWebView = GameWebView(
        displayMode: displayMode,
        appKey: GameLaunchCredentials.appKey,
        token: GameLaunchCredentials.token,
        automaticallyShowsRechargePrompt: false,
        onEvent: { [weak self] event in
            self?.handleGameEvent(event)
        }
    )
    gameWebView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(gameWebView)
    NSLayoutConstraint.activate([
        gameWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        gameWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        gameWebView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        gameWebView.heightAnchor.constraint(
            equalTo: gameWebView.widthAnchor,
            multiplier: aspectRatio.heightMultiplier
        )
    ])
    self.gameWebView = gameWebView
}
```

例如后端返回 `widthHeightRatio=1.0` 时 WebView 为 `1:1`；返回约 `0.6667` 时，高度约为宽度的 `1.5` 倍。`GameAspectRatio` 会拒绝小于等于零、无限或非数字的值。比例无效时如何提示或重试由业务宿主决定，不要在核心源码中写死兜底比例。

直接嵌入全屏时使用 `.full`，让 `GameWebView` 约束到页面安全区的四条边，不读取 `widthHeightRatio`。比例只控制原生容器高度，不改变 `mini` 参数。

## 统一事件回调

`onEvent` 会把所有已注册的 JS 回调传给宿主：

| H5 消息名称 | `GameEvent` | 含义 |
| --- | --- | --- |
| `recharge` | `.insufficientBalance` | 用户下注时余额不足 |
| `clickRecharge` | `.recharge` | 用户主动点击充值 |
| `newTppClose` | `.close` | 用户关闭游戏 |
| `OpenGameSucc` | `.openGameSuccess` | 游戏加载成功 |

宿主可以统一处理：

```swift
private func handleGameEvent(_ event: GameEvent) {
    switch event {
    case .insufficientBalance, .recharge:
        openAppRechargePage()
    case .close:
        gameWebView?.removeFromSuperview()
        gameWebView = nil
    case .openGameSuccess:
        recordGameOpened()
    }
}
```

`newTppClose` 到达时，`GameWebView` 会先停止加载并移除 JS handler，再发送 `.close` 事件。宿主只需要决定是移除视图、Pop 页面还是执行自己的场景关闭逻辑。

## 充值处理

`automaticallyShowsRechargePrompt` 默认为 `true`，行为与本 Demo 一致：收到 `recharge` 或 `clickRecharge` 后展示演示弹窗，点击“通知游戏”会执行：

```javascript
HttpTool.NativeToJs('recharge')
```

业务 App 有自己的充值页面时，创建 `GameWebView` 应传入：

```swift
automaticallyShowsRechargePrompt: false
```

在 `.insufficientBalance` 或 `.recharge` 事件中打开业务充值页面。充值成功并且游戏视图仍存在时调用：

```swift
gameWebView?.notifyGameBalanceDidChange()
```

## 主动关闭与释放

如果是宿主主动退出页面，而不是收到 `newTppClose`，请先停止 WebView，再移除它：

```swift
gameWebView?.stop()
gameWebView?.removeFromSuperview()
gameWebView = nil
```

`stop()` 会停止页面加载并注销全部 JS 消息 handler。全屏页面可在 Pop 前调用；嵌入式页面可在场景退出或重新创建游戏前调用。

## 接入检查清单

- 核心 Swift 文件已加入业务 App Target。
- 传入的 AppKey、Token 符合接入约定。
- 半屏和大半屏使用后端 `widthHeightRatio`，并已处理无效比例。
- 全屏、半屏和大半屏分别生成正确的 `mini`。
- 四个 `GameEvent` 均已按业务需要处理。
- 自定义充值流程关闭了自动 Demo 弹窗，并在充值成功后通知游戏。
- 主动退出场景时调用了 `stop()`。
- 使用真实 H5 环境验证游戏渲染、关闭和充值回调。

## 本工程验证命令

配置契约测试：

```sh
swiftc -module-cache-path /tmp/joyplay-module-cache \
  joyplay-ios/JoyPlayIntegration/GameConfiguration.swift Tests/main.swift \
  -o /tmp/joyplay-tests && /tmp/joyplay-tests
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
