# Game WebView Bottom Alignment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Align non-full-screen game WebViews to the safe-area bottom without changing their height or full-screen behavior.

**Architecture:** Keep the existing proportional height and horizontal constraints in `GameViewController`. Replace the safe-area top constraint with a safe-area bottom constraint so every display mode uses one unambiguous layout.

**Tech Stack:** Swift, UIKit, WebKit, Auto Layout

---

### Task 1: Align the WebView to the safe-area bottom

**Files:**
- Modify: `joyplay-ios/GameViewController.swift:35`

**Step 1: Confirm the current behavior source**

Verify that `configureWebView()` constrains `webView.topAnchor` to `view.safeAreaLayoutGuide.topAnchor` while setting a proportional height.

**Step 2: Implement the minimal layout change**

Replace the top constraint with:

```swift
webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
```

Keep the leading, trailing, and proportional height constraints unchanged.

**Step 3: Check the surgical diff**

Run:

```bash
git diff --check
git diff -- joyplay-ios/GameViewController.swift
```

Expected: no whitespace errors and exactly one functional constraint-line change.

**Step 4: Build the app**

Run:

```bash
xcodebuild -project joyplay-ios.xcodeproj -scheme joyplay-ios -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`.

**Step 5: Runtime acceptance check**

In a simulator or device, enter the game in half-screen, large-half-screen, and full-screen modes. Confirm that half-screen and large-half-screen touch the safe-area bottom and full-screen still fills the safe area.
