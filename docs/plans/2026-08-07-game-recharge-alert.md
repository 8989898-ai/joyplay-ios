# Game Recharge Alert Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Show one native recharge prompt for both recharge JS callbacks and notify the game to refresh its balance only when the player chooses “通知游戏”.

**Architecture:** Keep `GameWebView` as the single JS-message owner for all display modes. Put the prompt copy and documented refresh script in the existing Foundation-only configuration file so focused tests can specify the contract before UIKit wiring is added; present `UIAlertController` from the view's nearest host controller.

**Tech Stack:** Swift, UIKit, WebKit, command-line Swift tests, Xcode.

---

### Task 1: Specify the recharge bridge contract

**Files:**
- Modify: `Tests/main.swift`
- Modify: `joyplay-ios/GameConfiguration.swift`

1. Add assertions that the two recharge message cases are marked as recharge prompts, the alert message and two button titles exactly match the requested copy, and the refresh script equals `HttpTool.NativeToJs('recharge')`.
2. Run:

   ```bash
   swiftc -module-cache-path /tmp/joyplay-recharge-module-cache joyplay-ios/GameConfiguration.swift Tests/main.swift -o /tmp/joyplay-recharge-tests && /tmp/joyplay-recharge-tests
   ```

   Expected: compilation fails because the recharge-prompt contract does not exist.
3. Add the minimal configuration:
   - `GameScriptMessage.showsRechargePrompt` is `true` only for `recharge` and `clickRecharge`.
   - `GameRechargePrompt` contains the exact message, “未充值”, and “通知游戏”.
   - `GameBridgeScript.balanceRefresh` is `HttpTool.NativeToJs('recharge')`.
4. Run the focused test command again and expect `GameConfiguration tests passed`.

### Task 2: Present the alert and notify the game

**Files:**
- Modify: `joyplay-ios/GameWebView.swift`

1. Route both cases whose `showsRechargePrompt` is true to one `showRechargePrompt()` method while preserving their existing logs.
2. Build `UIAlertController` without a title and with the configured message.
3. Add “未充值” as a cancel action with no handler.
4. Add “通知游戏” as a default action whose handler evaluates `GameBridgeScript.balanceRefresh` on the owned `WKWebView`.
5. Find the nearest `UIViewController` through the responder chain and present the alert from it so the same code works for full, half, and seven-tenths modes.
6. Run the focused tests again and expect `GameConfiguration tests passed`.

### Task 3: Verify the completed behavior

**Files:**
- Verify: `joyplay-ios/GameConfiguration.swift`
- Verify: `joyplay-ios/GameWebView.swift`
- Verify: `Tests/main.swift`

1. Run the focused Swift tests and confirm `GameConfiguration tests passed`.
2. Run `git diff --check` for the three task files.
3. Inspect the task diff to confirm `newTppClose`, `OpenGameSucc`, layout, and existing background work are unchanged.
4. Run:

   ```bash
   xcodebuild -quiet -project joyplay-ios.xcodeproj -scheme joyplay-ios -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/joyplay-recharge-derived-data build CODE_SIGNING_ALLOWED=NO
   ```

   Expected: exit code `0`.
5. Record that live H5 validation remains necessary for the two incoming events and JavaScript execution.
