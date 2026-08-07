# 移除游戏内容页背景设计

## 目标

只移除实际游戏内容页 `GameViewController` 使用的 `voice-chat-bg2` 图片背景。

## 设计

- 删除 `GameViewController` 内的背景图片视图及其布局约束。
- 保留根视图的系统背景色和现有 WebView 布局。
- 保留 `GameModeLaunchViewController` 的背景图片，使半屏和大半屏进入游戏前的外层页面不变。
- 保留图片资源，因为外层页面仍然使用它。

## 验证

- 确认 `GameViewController` 不再引用背景图片。
- 确认 `GameModeLaunchViewController` 仍引用背景图片。
- 执行聚焦测试、差异检查和无签名模拟器构建。
