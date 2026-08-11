# 简化游戏模式导航设计

## 目标

移除 Demo 的 `UITabBarController` 模式容器，把底部三个模式入口改成普通按钮，并按全屏与嵌入模式拆分清晰的控制器职责。核心 `JoyPlayIntegration` 接口、URL 契约、比例、安全区、充值和 H5 事件规则保持不变。

`docs/plans/` 中已有文档是历史实施记录，不随本次设计回写。

## 页面结构

```text
NavigationController
└── GameModeSelectionViewController
    ├── 中央圆形“打开全屏游戏”按钮
    └── 底部三个普通模式按钮
        ├── 全屏：默认选中，停留在当前页面
        ├── 半屏：Push PartialGameViewController(.half)
        └── 大半屏：Push PartialGameViewController(.largeHalf)
```

### GameModeSelectionViewController

- 替代 `GameModeTabBarController`，作为导航栈根页面。
- 默认显示全屏选中态。
- 点击已选中的全屏模式按钮不跳转。
- 点击中央圆形按钮时创建全屏 Demo URL，Push `GameViewController`。
- 点击半屏或大半屏模式按钮时，只 Push 对应的 `PartialGameViewController`，不创建 URL，也不加载游戏。
- 继续使用现有模式名称、图标、按钮颜色、尺寸、居中布局和呼吸动画。

### GameViewController

- 只负责全屏游戏。
- 进入后立即创建并加载全屏 `GameWebView`。
- `newTppClose` 到达后 Pop 当前控制器。
- 宿主通过顶部导航主动退出时调用 `stop()`。
- 保持全屏边到边布局、导航栏隐藏、安全区参数、充值和余额刷新行为不变。

### PartialGameViewController

- 半屏和大半屏共用一个类，通过 `displayMode` 和原始 `widthHeightRatio` 区分。
- 半屏继续使用直播间背景，大半屏继续使用语聊房背景。
- 初始只显示场景背景和对应的圆形“打开游戏”按钮，不创建 `GameWebView`。
- 点击圆形按钮时创建当前模式的 Demo URL，再初始化并添加 `GameWebView`。
- `GameWebView` 左右贴宿主视图，底部贴物理屏幕底部；高度继续由核心根据原始宽高比和底部安全区确定。
- `newTppClose` 到达后调用 `stop()`、移除 `GameWebView`、恢复圆形按钮和呼吸动画，控制器保持显示，允许再次打开。
- 顶部导航返回时，如果游戏已打开，先调用 `stop()`，再由导航控制器正常 Pop。

## 配置与数据流

`ViewController` 继续持有 Demo AppKey、Token，以及半屏和大半屏的后端原始 `widthHeightRatio`，并把这些值传给 `GameModeSelectionViewController`。

- 全屏：中央按钮创建 `.full` URL，Push `GameViewController`，不传比例。
- 半屏：模式按钮 Push `PartialGameViewController(.half)`；圆形按钮随后创建 `mini=1` URL并传入半屏比例。
- 大半屏：模式按钮 Push `PartialGameViewController(.largeHalf)`；圆形按钮随后创建 `mini=2` URL并传入大半屏比例。

以下契约保持不变：

- `gameId=1`。
- 全屏、半屏、大半屏分别使用 `mini=0/1/2`。
- 仅全屏 URL 包含 `safeTop=1`。
- 后端 URL 不包含 `paddingBottom`；核心仅在全屏首次加载时追加窗口底部安全距离。
- Demo URL 继续包含 `isNativeDemo=1`。
- 半屏和大半屏把原始 `widthHeightRatio` 直接传给 `GameWebView`。

## 事件与生命周期

- `.insufficientBalance`、`.recharge`：继续展示 `DemoRechargePromptPresenter`；确认后调用 `notifyGameBalanceDidChange()`。
- `.close`：全屏 Pop；半屏和大半屏只停止并移除当前 `GameWebView`。
- `.openGameSuccess`：保持现有空处理。
- 宿主主动退出任何已加载游戏的页面时调用 `stop()`。

删除仅服务于旧 Tab Bar 架构的 Demo 策略和状态，包括 `GameLaunchPresentation`、`GameBackDestination`、`hidesModeTabBar`、嵌入/Push 分流以及返回全屏 Tab 的逻辑。核心 `JoyPlayIntegration/GameConfiguration.swift` 和 `JoyPlayIntegration/GameWebView.swift` 不修改。

## 失败处理

- Demo URL 创建失败时停留在当前页面，不 Push 无效页面。
- Partial 模式的 `GameWebView` 初始化失败时保留圆形按钮及其可交互状态，允许再次尝试。
- 不新增兜底 URL、比例、错误弹窗、Coordinator 或包装控制器。

## 文案与文档

- 复用现有英文与简体中文模式名称和“打开游戏”文案，不新增用户可见字符串。
- 保留 `Localizable.xcstrings` 当前键值并继续执行本地化验证。
- 更新 `README.md`、`AGENTS.md` 和当前测试中的 Demo 文件名及页面结构引用；不改写已有 `docs/plans/` 历史文档。

## 验证

自动验证包括：

- 核心配置契约测试。
- Demo URL、模式标题、图标和背景配置测试。
- 控制器源码边界、事件、布局、释放与无效配置行为测试。
- 圆形按钮主题、布局、呼吸动画和“减少动态效果”测试。
- 本地化目录测试和 `xcrun xcstringstool compile`。
- `xcodebuild -list` 与无签名模拟器构建。

人工运行时验证包括：

- 默认全屏选中态和三个普通模式按钮的视觉效果。
- 全屏中央按钮 Push 后立即加载游戏。
- 半屏和大半屏按钮只进入场景页，圆形按钮点击后才加载游戏。
- Partial 模式 `newTppClose` 只移除 WebView、恢复按钮并允许重新打开。
- 顶部返回正确停止游戏并返回入口页。
- 场景背景、宽高比、底部安全区、四个真实 H5 回调和充值刷新行为。

静态测试和构建成功不能替代真实 H5 与视觉验证。
