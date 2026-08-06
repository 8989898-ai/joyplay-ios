# Game Mode Tabs Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move game display-mode selection from the home page to a three-tab mode page, launch full-screen games by push, launch partial-screen games inline, and use `gameId=2`.

**Architecture:** Keep the home controller responsible only for AppKey/Token entry. Add a UIKit `UITabBarController` with one launch controller per mode, while reusing `GameViewController` either as a pushed controller or an embedded child; keep mode-specific presentation rules in `GameConfiguration.swift` so the behavior is testable without UIKit.

**Tech Stack:** Swift, UIKit, WebKit, Auto Layout, command-line Swift tests, Xcode.

---

### Task 1: Specify mode-page behavior and URL defaults

**Files:**
- Modify: `Tests/main.swift`
- Modify: `joyplay-ios/GameConfiguration.swift`

1. Add failing assertions for tab order/titles, pushed-versus-embedded presentation, background usage, and `gameId=2`.
2. Run the focused command-line tests and confirm the new assertions fail for the expected old values or missing API.
3. Add the smallest model properties needed by the mode page and update the fixed game ID.
4. Run the focused tests and confirm all assertions pass.

### Task 2: Remove mode selection from the home page

**Files:**
- Modify: `joyplay-ios/ViewController.swift`

1. Remove the mode state, mode controls, and their update actions.
2. Change the button title from `进入游戏` to `进入`.
3. Push the new mode page with the validated, trimmed AppKey and Token.

### Task 3: Add the three-tab mode page

**Files:**
- Create: `joyplay-ios/GameModeViewController.swift`
- Modify: `joyplay-ios/GameViewController.swift`

1. Add a bottom tab bar with `全屏`, `半屏`, and `7分屏` in model order.
2. Show a centered launch button for full screen; push the existing game controller and hide the bottom tab bar when tapped.
3. For half screen and 7-part screen, show the existing game background and a bottom-trailing launch button; embed the existing game controller in the current page when tapped.
4. When an embedded game's close callback fires, remove it and restore the button in the current tab.

### Task 4: Verify

**Files:**
- Verify: `joyplay-ios/*.swift`
- Verify: `Tests/main.swift`

1. Run the focused command-line tests.
2. Run `git diff --check` and inspect only the task files.
3. Run an unsigned iOS Simulator build and confirm `BUILD SUCCEEDED`.
4. Record that actual button placement and WebView rendering still need simulator/device interaction if a full runtime walkthrough is not available.
