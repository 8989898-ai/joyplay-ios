# JoyPlay Integration Guide and Events Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development to implement this plan task-by-task.

**Goal:** Make the Demo self-explanatory to a Swift/UIKit integrator and expose every documented game callback through one host-facing event API.

**Architecture:** Keep `GameWebView` as the single owner of WebKit and JavaScript bridge registration. Rename the bridge-facing message model to the host-facing `GameEvent`, deliver every event through one closure, and retain the Demo recharge prompt behind a default-enabled option so real host apps can replace it. Add a root README that separates required integration files from optional Demo UI.

**Tech Stack:** Swift 5, UIKit, WebKit, Foundation, standalone Swift contract tests, Xcode simulator build.

---

### Task 1: Specify the host-facing event API

**Files:**
- Modify: `Tests/main.swift`
- Create: `Tests/IntegrationSurfaceTests.swift`
- Modify: `joyplay-ios/GameConfiguration.swift`
- Modify: `joyplay-ios/GameWebView.swift`
- Modify: `joyplay-ios/GameViewController.swift`
- Modify: `joyplay-ios/GameModeTabBarController.swift`

1. Change the focused contract test to require `GameEvent` with the four documented raw callback names.
2. Add a source-surface test requiring `GameWebView` to accept and invoke one `onEvent` closure and to expose balance-refresh notification.
3. Run both tests and confirm failure because the new API does not exist.
4. Rename `GameScriptMessage` to `GameEvent`, replace `onClose` with `onEvent`, and invoke the closure for all four events.
5. Add a default-enabled automatic recharge-prompt option and a `notifyGameBalanceDidChange()` method for custom host recharge flows.
6. Update the full-screen and embedded Demo hosts to close only when they receive `.close`.
7. Re-run focused tests and confirm success.

### Task 2: Add the third-party integration guide

**Files:**
- Create: `README.md`
- Create: `Tests/IntegrationGuideTests.swift`

1. Add a failing documentation test requiring prerequisites, required/optional file lists, URL parameters, full/embedded examples, all event mappings, custom recharge instructions, and cleanup guidance.
2. Run it and confirm failure because `README.md` does not exist.
3. Write the smallest complete Chinese README satisfying those requirements and explicitly state that the Demo AppKey and Token are intentionally public.
4. Re-run the documentation test and confirm success.

### Task 3: Verify the delivery

**Files:**
- Verify: `README.md`
- Verify: `joyplay-ios/*.swift`
- Verify: `Tests/*.swift`

1. Run all standalone focused tests with writable module-cache paths.
2. Run `git diff --check`.
3. Build the `joyplay-ios` scheme for a generic iOS Simulator with signing disabled and a fresh DerivedData path.
4. Inspect the final diff to confirm no unrelated source, visual, credential, URL, game ID, or layout changes.
5. Record that real H5 callback and visual runtime validation remain separate from compilation.
