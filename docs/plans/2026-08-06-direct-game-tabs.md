# Direct Game Tabs Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the AppKey/Token form, launch directly into the existing three game-mode tabs, and use the supplied fixed JoyPlay URL configuration.

**Architecture:** Keep the existing Storyboard navigation controller. Replace the home controller UI with an immediate non-animated navigation-stack replacement using fixed credentials stored in the Foundation-only configuration file, and update the existing URL builder host and path while preserving `gameId=2` and mode-specific `mini` values.

**Tech Stack:** Swift, UIKit, Foundation, XCTest-free focused Swift assertions, Xcode

---

### Task 1: Specify the fixed launch configuration and new URL

**Files:**
- Modify: `Tests/main.swift`
- Modify: `joyplay-ios/GameConfiguration.swift`

**Step 1: Write the failing test**

- Replace input-validator assertions with assertions for the fixed AppKey and non-empty fixed Token.
- Update URL assertions to require host `joyplay.cn` and path `/release/index.html`.
- Build URLs for all three modes and assert only their `mini` query value differs.

**Step 2: Run test to verify it fails**

Run:

```bash
swiftc -module-cache-path /tmp/joyplay-direct-tabs-module-cache joyplay-ios/GameConfiguration.swift Tests/main.swift -o /tmp/joyplay-direct-tabs-tests && /tmp/joyplay-direct-tabs-tests
```

Expected: compilation or assertion failure because fixed credentials and the new endpoint are not implemented.

**Step 3: Write minimal implementation**

- Add one fixed credential configuration in `GameConfiguration.swift`.
- Change only the URL builder host and path.
- Remove `GameEntryValidator`, which becomes unused when the form is removed.

**Step 4: Run test to verify it passes**

Run the focused command again and expect `GameConfiguration tests passed`.

### Task 2: Launch directly into the three tabs

**Files:**
- Modify: `joyplay-ios/ViewController.swift`

**Step 1: Add a failing source-level check**

Run a source check that rejects `UITextField`, `enterGameButton`, and `GameEntryValidator` in `ViewController.swift`, and requires `setViewControllers` plus `GameModeTabBarController`.

Expected: FAIL because the form still exists.

**Step 2: Write minimal implementation**

Replace the form controller with a small `viewDidLoad` implementation that creates `GameModeTabBarController` using the fixed credentials and replaces the navigation stack without animation.

**Step 3: Verify the source-level behavior**

Run the same source check and expect success.

### Task 3: Verify the complete change

**Files:**
- Verify: `joyplay-ios/ViewController.swift`
- Verify: `joyplay-ios/GameConfiguration.swift`
- Verify: `Tests/main.swift`

**Step 1: Run focused tests**

Run the focused Swift test command and expect `GameConfiguration tests passed`.

**Step 2: Check patch whitespace**

Run `git diff --check` and expect no output.

**Step 3: Build the app**

Run:

```bash
xcodebuild -quiet -project joyplay-ios.xcodeproj -scheme joyplay-ios -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/joyplay-direct-tabs-derived build CODE_SIGNING_ALLOWED=NO
```

Expected: exit code 0.

**Step 4: Inspect the final diff**

Confirm every changed production line maps to direct Tab launch, fixed credentials, or the supplied JoyPlay endpoint, and confirm the pre-existing Xcode user-state modification remains untouched.

