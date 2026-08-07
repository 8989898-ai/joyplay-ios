# Game Button Breathing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为三个游戏模式共用的打开游戏按钮增加轻柔、可点击并尊重“减弱动态效果”的缩放呼吸动画。

**Architecture:** 动画逻辑保留在拥有按钮的 `GameModeLaunchViewController` 中，通过两个私有方法统一启停。控制器生命周期负责页面切换，打开/关闭嵌入游戏的现有路径负责按钮隐藏与恢复。

**Tech Stack:** Swift、UIKit、现有 Swift 源码测试、Xcode 模拟器编译

---

### Task 1: 用测试定义呼吸动画行为

**Files:**
- Modify: `Tests/ThemeAndGameButtonLayoutTests.swift`

**Step 1: Write the failing test**

断言控制器源码包含 `0.96`/`1.04` 缩放、`0.6` 秒半周期、循环往返与允许交互选项、减弱动态效果判断，以及页面和游戏状态变化时的启停调用。

**Step 2: Run test to verify it fails**

Run: `swiftc -module-cache-path /tmp/joyplay-theme-test-cache Tests/ThemeAndGameButtonLayoutTests.swift -o /tmp/joyplay-theme-tests`

Run: `/tmp/joyplay-theme-tests`

Expected: FAIL，提示缺少打开游戏按钮呼吸动画。

### Task 2: 实现最小 UIKit 动画

**Files:**
- Modify: `joyplay-ios/GameModeTabBarController.swift`

**Step 1: Write minimal implementation**

新增 `startGameButtonBreathing()` 和 `stopGameButtonBreathing()`；在 `viewDidAppear`、`viewWillDisappear`、`openGame()` 与 `removeEmbeddedGame()` 的现有边界调用。

**Step 2: Run focused test to verify it passes**

Run: `swiftc -module-cache-path /tmp/joyplay-theme-test-cache Tests/ThemeAndGameButtonLayoutTests.swift -o /tmp/joyplay-theme-tests`

Run: `/tmp/joyplay-theme-tests`

Expected: PASS，输出 `Theme and game-button layout tests passed`。

### Task 3: 回归验证

**Files:**
- Verify: `Tests/*.swift`
- Verify: `joyplay-ios.xcodeproj`

**Step 1: Run all Swift script tests**

逐个运行 `Tests/*.swift`，Expected: 全部退出码为 `0`。

**Step 2: Build the app**

Run: `xcodebuild -quiet -project joyplay-ios.xcodeproj -scheme joyplay-ios -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/joyplay-game-button-breathing build CODE_SIGNING_ALLOWED=NO`

Expected: exit code `0`。

**Step 3: Inspect the final diff**

Run: `git diff --check && git status --short`

Expected: 没有空白错误，且只出现计划内文件和已有的 Xcode 用户状态文件改动。
