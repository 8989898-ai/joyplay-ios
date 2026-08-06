# 嵌入式游戏 WebView 设计

## 目标

半屏用于直播间场景，7 分屏用于语聊房场景。两种模式都直接在当前场景控制器中添加游戏视图，不 push 新页面，也不添加游戏子控制器。

## 控制器与视图职责

- `GameModeTabBarController` 继续承载全屏、半屏和 7 分屏三个入口。
- 点击半屏或 7 分屏 Tab 后立即隐藏底部 Tab Bar；进入场景后不再通过底部 Tab 切换模式。
- `GameWebView` 是可复用的 `UIView`，内部持有 `WKWebView`，统一负责游戏 URL 加载、JS 消息注册与释放。
- `GameViewController` 仅作为全屏游戏的页面容器，内部添加同一个 `GameWebView`。
- 半屏和 7 分屏的场景控制器直接添加 `GameWebView`，不添加 `GameViewController` 子控制器。

## 展示规则

- 全屏：点击游戏按钮后 push `GameViewController`，隐藏顶部导航栏和底部 Tab Bar。
- 半屏：点击 Tab 后进入直播间场景并隐藏底部 Tab Bar；游戏视图按宽高比 `1:1` 底部对齐。
- 7 分屏：点击 Tab 后进入语聊房场景并隐藏底部 Tab Bar；游戏视图按宽高比 `1:1.5` 底部对齐。
- 半屏和 7 分屏保留顶部导航栏，用户通过顶部返回退出整个场景。

## 关闭行为

- 全屏收到 `newTppClose`：由全屏容器执行导航返回。
- 半屏或 7 分屏收到 `newTppClose`：只移除当前 `GameWebView` 并恢复游戏按钮，不 pop 或销毁场景控制器。
- 移除半屏或 7 分屏游戏视图后，底部 Tab Bar 继续隐藏，直到用户点击顶部导航栏返回。
- `GameWebView` 被移除或释放时注销所有 JS 消息处理器，避免 `WKUserContentController` 持有消息处理对象。

## 验证

- 聚焦测试覆盖模式对应的底栏显隐规则和现有 URL/尺寸规则。
- 静态检查确认半屏和 7 分屏不再创建或添加 `GameViewController`。
- 无签名模拟器构建必须成功。
- 运行时需要验证：点击半屏/7 分屏 Tab 后底栏立即隐藏，`newTppClose` 只移除 WebView，顶部返回退出场景。
