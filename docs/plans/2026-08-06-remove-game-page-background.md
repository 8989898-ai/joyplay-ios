# Remove Game Page Background Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the image background from the actual game content page while preserving the partial-mode launch-page background.

**Architecture:** Delete only the `GameViewController` background image view and its constraints. Keep the root system background, WebView layout, outer launch-page image view, and shared image asset unchanged.

**Tech Stack:** Swift, UIKit, WebKit, Auto Layout, Xcode

---

### Task 1: Remove the game content background layer

**Files:**
- Modify: `joyplay-ios/GameViewController.swift`
- Verify: `joyplay-ios/GameModeTabBarController.swift`

**Step 1: Run the failing source check**

Run a check that requires `GameViewController.swift` not to contain `backgroundImageView`. It must fail before implementation because the background currently exists.

**Step 2: Write the minimal implementation**

Delete the private `backgroundImageView`, its Auto Layout setup, its insertion into the root view, and its four edge constraints. Do not change the WebView constraints.

**Step 3: Run the focused checks**

Confirm `GameViewController.swift` has no background image view and `GameModeTabBarController.swift` still has one. Run the existing configuration tests and `git diff --check`.

**Step 4: Build the app**

Run:

```bash
xcodebuild -project joyplay-ios.xcodeproj -scheme joyplay-ios -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/joyplay-ios-remove-game-background-derived-data build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`.

**Step 5: Runtime acceptance check**

Open an actual game in all three modes. Confirm the game content page no longer shows `voice-chat-bg2`, while the half-screen and 7-part launch pages retain it.
