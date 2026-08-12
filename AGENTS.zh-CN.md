[English](AGENTS.md) | 简体中文

> 本文件是方便中文维护者阅读的翻译；如有差异，以英文 `AGENTS.md` 为准。

# JoyPlay iOS AI 接入规则

本文件适用于两类任务：维护当前 Demo，以及把 JoyPlay 游戏接入另一个 Swift + UIKit 工程。用户的明确要求始终优先。

## 接入前必须读取

1. 阅读根目录 `README.md`，确认游戏模式、事件、充值和释放规则。
2. 检查目标工程及其父目录中的其他 `AGENTS.md`，同时遵守目标工程规则。
3. 自动扫描目标工程，定位工程容器、Scheme、App Target、候选宿主控制器、后端完整游戏 URL、宽高比来源、关闭路径和充值处理。
4. `INTEGRATION_REQUEST.yaml` 是可选的业务覆盖和接入记录。字段为 `null` 表示未指定，由 AI 自动发现，不阻塞接入；已有非空值优先于自动发现结果。
5. 如果某项业务决策无法唯一确定，例如存在多个合理宿主控制器、关闭行为或充值入口，停止修改相关位置并只向用户确认有歧义的项目；不要让用户填写 AI 已能从工程确定的信息。
6. 扫描或确认完成后，可将最终选择回填到 `INTEGRATION_REQUEST.yaml`，作为接入记录。
7. `docs/plans/` 属于内部历史实施记录，不包含在交付仓库中；如果从其他渠道取得该目录，也不要把它作为当前契约。当前契约以 `README.md`、本文件和核心源码为准。

## 可分发核心源码

接入目标工程时，只复制整个 `joyplay-ios/JoyPlayIntegration/` 目录，并确认其中两个 Swift 文件都加入目标 App Target：

- `GameConfiguration.swift`
- `GameWebView.swift`

宿主直接初始化 `GameWebView`，传入后端完整 URL、展示模式、嵌入模式的原始 `widthHeightRatio` 和事件回调，再调用 `attach(to:)` 加入业务容器。`GameWebView` 会根据模式完成外层布局，是唯一推荐的宿主入口；不要让接入方重复实现游戏视图约束，也不要为普通接入额外增加 Session、Coordinator 或包装控制器。

除非用户明确要求复刻 Demo UI，否则不要复制以下 Demo 专用内容：

- `DemoGameConfiguration.swift`
- `DemoRechargePromptPresenter.swift`
- `DemoGameLaunchButton.swift`
- `GameModeSelectionViewController.swift`
- `PartialGameViewController.swift`
- `FullScreenGameViewController.swift`
- `Localizable.xcstrings`
- `Assets.xcassets` 中的按钮颜色和场景背景图

## 本地文案与多语言

- 当前 Demo 的所有用户可见文案和无障碍文案必须支持英文 `en` 与简体中文 `zh-Hans`。
- 使用 iOS 原生本地化机制和 `String(localized:defaultValue:)`，跟随系统语言，英文作为源语言和默认回退语言。
- 新增或修改本地文案时，必须同时更新 `Localizable.xcstrings` 中的英文和简体中文翻译，并更新本地化测试。
- 控制台日志、URL、查询参数、资源名称、AppKey、Token、JS 脚本以及 H5 回调名称不属于本地文案，不要本地化。
- 核心源码不展示充值 UI；Demo 充值文案只属于 `DemoRechargePromptPresenter.swift`。
- 接入其他业务工程时不要复制 Demo 的 `Localizable.xcstrings`；目标 App 使用自己的充值文案和字符串资源。
- 使用 `xcrun xcstringstool compile` 验证字符串目录，并通过无签名模拟器构建确认英中资源被打包。构建不能替代系统语言切换后的运行时视觉验证。

## 不得擅自改变的接入契约

- 游戏地址由宿主后端下发完整 HTTPS URL，核心 `GameWebView` 直接接收 `URL`。
- 后端 URL 中的 `gameId=1`。
- 后端为全屏、半屏、大半屏 URL 分别提供 `mini=0`、`mini=1`、`mini=2`。
- 后端 URL 不得包含 `safeTop` 或 `paddingBottom`；核心仅在全屏首次加载时追加 `safeTop=1` 和当前窗口底部安全距离，半屏和大半屏不修改 URL。
- 半屏和大半屏的 `widthHeightRatio`（宽 ÷ 高）来自宿主后端配置；宿主把原始值直接传给 `GameWebView`，由核心校验并转换成高度 multiplier，底部对齐安全区。不要让宿主构造核心比例类型，也不要在 `GameDisplayMode` 或核心源码中写死比例。
- `GameWebView` 使用可失败初始化：非 HTTPS、缺少主机名、预先包含 `safeTop` 或 `paddingBottom`、嵌入模式缺少或传入无效比例、全屏传入比例时均返回 `nil`。失败后的提示或重试方式仍由宿主决定。
- H5 消息名称固定为 `recharge`、`clickRecharge`、`newTppClose`、`OpenGameSucc`。
- 核心不认识 AppKey、Token、`gameId`、`mini` 或 `isNativeDemo`；当前 Demo 在 `DemoGameDataSource` 中用源码内模拟 JSON 展示三条完整 URL，再通过 `JSONDecoder` 解码，每条 URL 固定包含对应的 `mini` 和 `isNativeDemo=1`，业务后端默认不传该标记。
- `newTppClose` 到达后，宿主根据模板选择移除游戏视图或 Pop；不要擅自关闭直播间、语聊房等业务控制器。
- 宿主主动退出时调用 `stop()`。
- 收到充值事件后由宿主展示充值 UI；充值成功后调用 `notifyGameBalanceDidChange()`。
- Demo AppKey 和 Token 允许公开，不要仅因其出现在源码或日志中而移除。

## AI 接入步骤

1. 自动扫描并确认目标工程、Scheme、App Target、宿主控制器、后端完整游戏 URL 和宽高比来源；用 `INTEGRATION_REQUEST.yaml` 中的非空值覆盖自动发现结果。
2. 复制 `JoyPlayIntegration` 目录，保持两个文件在同一个 Target 中。
3. 将后端完整游戏 URL、模式和嵌入模式的原始比例直接传给 `GameWebView`，初始化成功后调用 `attach(to:)` 加入业务容器；初始化返回 `nil` 时沿用工程中已明确的处理方式，无法唯一确定时向用户确认，不要让宿主重复校验、重复实现布局，或引入 Demo 页面控制器、背景资源。
4. 实现全部 `GameEvent` 分支，即使某个事件当前只记录日志。
5. 按工程中唯一明确的行为或模板非空覆盖实现关闭与充值；有歧义时先确认。
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
- 游戏 URL、宽高比、无效 URL/比例处理、关闭和充值行为是自动发现、模板覆盖还是用户确认。
- 执行了哪些测试或 `xcodebuild` 命令及其结果。
- 哪些真实 H5 或视觉验证仍待人工完成。
