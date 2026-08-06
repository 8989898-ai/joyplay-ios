# Home Keyboard Dismiss Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Dismiss the home screen keyboard when the user taps empty space or the enter-game button.

**Architecture:** Add a non-cancelling tap recognizer to `ViewController` and filter out taps originating from controls. End editing explicitly at the beginning of the enter-game action.

**Tech Stack:** Swift, UIKit, Xcode

---

### Task 1: Add keyboard dismissal

**Files:**
- Modify: `joyplay-ios/ViewController.swift`

**Step 1: Configure the background gesture**

Add a `UITapGestureRecognizer` during action configuration, keep `cancelsTouchesInView` disabled, and use the view controller as its delegate.

**Step 2: Filter control taps**

Implement `gestureRecognizer(_:shouldReceive:)` so the background gesture ignores `UIControl` instances.

**Step 3: Dismiss from supported actions**

Add a background-tap handler that calls `view.endEditing(true)`, and call the same API at the beginning of `enterGame()`.

**Step 4: Verify**

Run: `git diff --check`

Expected: exit code 0.

Run: `xcodebuild -project joyplay-ios.xcodeproj -scheme joyplay-ios -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/joyplay-ios-derived-data build CODE_SIGNING_ALLOWED=NO`

Expected: `BUILD SUCCEEDED`.

Automated UIKit interaction tests are intentionally omitted because the project has no XCTest/UI Test target; the approved scope uses build verification plus a simulator interaction check.
