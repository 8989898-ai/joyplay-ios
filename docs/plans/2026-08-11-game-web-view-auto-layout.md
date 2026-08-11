# GameWebView Auto Layout Ownership Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move the outer `GameWebView` Auto Layout opt-in from Demo hosts into `GameWebView` itself for all display modes.

**Architecture:** `GameWebView` declares `translatesAutoresizingMaskIntoConstraints = false` immediately after its `UIView` initialization. Full-screen and embedded Demo hosts continue to own placement constraints but no longer repeat that view-level configuration.

**Tech Stack:** Swift 5, UIKit, source-surface Swift tests, Xcode simulator build

---

### Task 1: Specify Auto Layout ownership

**Files:**
- Modify: `Tests/IntegrationSurfaceTests.swift`
- Modify: `Tests/IntegrationGuideTests.swift`

1. Add assertions requiring `GameWebView.swift` to contain `translatesAutoresizingMaskIntoConstraints = false`.
2. Add assertions forbidding the same setting in `GameViewController.swift` and `GameModeTabBarController.swift`.
3. Add an assertion forbidding host-side setup in the README integration examples.
4. Run both tests and verify they fail because the ownership has not moved yet.

### Task 2: Move the setting into GameWebView

**Files:**
- Modify: `joyplay-ios/JoyPlayIntegration/GameWebView.swift`
- Modify: `joyplay-ios/GameViewController.swift`
- Modify: `joyplay-ios/GameModeTabBarController.swift`
- Modify: `README.md`

1. Set `translatesAutoresizingMaskIntoConstraints = false` after `super.init(frame: .zero)` in `GameWebView.init`.
2. Remove the duplicate setting from both Demo hosts without changing their constraints.
3. Remove the duplicate setting from both README host examples and document the core-owned behavior.
4. Re-run both focused tests and verify they pass.

### Task 3: Regression verification

**Files:**
- Verify: `Tests/*.swift`
- Verify: `joyplay-ios.xcodeproj`

1. Run the project Swift test commands with a writable module cache.
2. Run `git diff --check`.
3. Run the unsigned `joyplay-ios` simulator build with a fresh DerivedData path.
4. Report that runtime visual and real-H5 verification remain manual.
