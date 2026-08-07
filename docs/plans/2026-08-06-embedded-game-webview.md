# Embedded Game WebView Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Hide the mode Tab Bar as soon as half or large-half mode is selected, and embed a reusable game WebView directly in those scene controllers without adding a game child controller.

**Architecture:** Extract WebKit loading and JS-bridge behavior from `GameViewController` into a reusable `GameWebView`. Full screen keeps `GameViewController` as a navigation container, while half and large-half scene controllers add and remove `GameWebView` directly. `GameModeTabBarController` remains the sole owner of its Tab Bar visibility.

**Tech Stack:** Swift, UIKit, WebKit, Auto Layout, command-line Swift tests, Xcode.

---

### Task 1: Specify mode Tab Bar visibility

**Files:**
- Modify: `Tests/main.swift`
- Modify: `joyplay-ios/GameConfiguration.swift`

1. Add failing assertions that full screen keeps the mode Tab Bar visible while half and large-half hide it.
2. Run:

   ```bash
   swiftc -module-cache-path /tmp/joyplay-swift-module-cache joyplay-ios/GameConfiguration.swift Tests/main.swift -o /tmp/joyplay-game-configuration-tests && /tmp/joyplay-game-configuration-tests
   ```

   Expected: compilation fails because `hidesModeTabBar` does not exist.
3. Add the minimal model rule:

   ```swift
   var hidesModeTabBar: Bool {
       self != .full
   }
   ```

4. Run the same focused test command and expect `GameConfiguration tests passed`.

### Task 2: Extract the reusable game view

**Files:**
- Create: `joyplay-ios/GameWebView.swift`
- Modify: `joyplay-ios/GameViewController.swift`

1. Add `GameWebView`, a `UIView` that owns a `WKWebView`, loads `GameURLBuilder` output, registers all `GameScriptMessage` names, and exposes an `onClose` closure.
2. Use a weak `WKScriptMessageHandler` proxy so the WebKit message controller does not retain `GameWebView` through a cycle.
3. Keep `recharge`, `clickRecharge`, and `OpenGameSucc` logging behavior unchanged; map only `newTppClose` to `onClose`.
4. Make the internal `WKWebView` fill `GameWebView` bounds. Keep mode-specific sizing in the host controller.
5. Replace WebKit ownership in `GameViewController` with a `GameWebView` that fills the existing full-screen safe-area layout. Its close closure must pop the full-screen page.
6. Keep the existing navigation-bar lifecycle unchanged: only full screen hides the top navigation bar, and leaving restores it.
7. Run an unsigned simulator build and expect `BUILD SUCCEEDED`.

### Task 3: Embed the game view and hide the mode Tab Bar

**Files:**
- Modify: `joyplay-ios/GameModeTabBarController.swift`

1. Make `GameModeTabBarController` its own `UITabBarControllerDelegate`.
2. When a tab is selected, derive the selected `GameDisplayMode` from `selectedIndex` and set `tabBar.isHidden` from `hidesModeTabBar`.
3. Replace `embeddedGameViewController` with `embeddedGameView`.
4. For half and large-half, instantiate `GameWebView`, add it directly with `addSubview`, pin it to the scene's safe-area bottom and horizontal edges, and use the mode's existing width-to-height ratio.
5. On `newTppClose`, remove only `GameWebView`, clear its stored reference, and show the game button again. Do not pop the navigation stack and do not change Tab Bar visibility.
6. Keep the full-screen push path and `hidesBottomBarWhenPushed` unchanged.
7. Run the focused configuration tests and unsigned simulator build.

### Task 4: Verify the completed behavior

**Files:**
- Verify: `joyplay-ios/GameConfiguration.swift`
- Verify: `joyplay-ios/GameWebView.swift`
- Verify: `joyplay-ios/GameViewController.swift`
- Verify: `joyplay-ios/GameModeTabBarController.swift`
- Verify: `Tests/main.swift`

1. Run the focused Swift tests and confirm `GameConfiguration tests passed`.
2. Run `git diff --check` for the task files.
3. Confirm source inspection shows no `addChild(GameViewController)` path for half or large-half.
4. Run the unsigned simulator build and confirm `BUILD SUCCEEDED`.
5. Record the remaining runtime checks: Tab Bar hides immediately on half/large-half selection; `newTppClose` removes only the WebView; the Tab Bar remains hidden; the top back button exits the scene.
