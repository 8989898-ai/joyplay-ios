# Game WebView Aspect Ratio Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Size the phone WebView at width-to-height ratios of 1:1 for half mode and 1:1.5 for large-half mode while preserving full-screen safe-area sizing.

**Architecture:** Replace the old safe-area height percentage with an optional height-to-width ratio on `GameDisplayMode`. `GameViewController` will use a width-based height constraint when the ratio exists and its existing full safe-area height constraint otherwise.

**Tech Stack:** Swift, Foundation/CoreGraphics, UIKit Auto Layout, command-line Swift tests, Xcode.

---

### Task 1: Specify display sizing

**Files:**
- Modify: `Tests/main.swift`
- Test: `Tests/main.swift`

**Step 1: Replace the old height-percentage assertions**

```swift
expect(GameDisplayMode.half.heightToWidthRatio == 1.0, "半屏宽高比应为 1:1")
expect(GameDisplayMode.sevenTenths.heightToWidthRatio == 1.5, "大半屏宽高比应为 1:1.5")
expect(GameDisplayMode.full.heightToWidthRatio == nil, "全屏应使用安全区完整高度")
```

**Step 2: Run the test and verify RED**

```bash
xcrun swiftc -module-cache-path /tmp/joyplay-swift-module-cache joyplay-ios/GameConfiguration.swift Tests/main.swift -o /tmp/joyplay-game-configuration-tests
/tmp/joyplay-game-configuration-tests
```

Expected: compilation fails because `heightToWidthRatio` does not exist.

### Task 2: Add the model sizing property

**Files:**
- Modify: `joyplay-ios/GameConfiguration.swift`
- Test: `Tests/main.swift`

**Step 1: Replace `heightRatio`**

```swift
var heightToWidthRatio: CGFloat? {
    switch self {
    case .half:
        return 1.0
    case .sevenTenths:
        return 1.5
    case .full:
        return nil
    }
}
```

**Step 2: Run the focused test and verify GREEN**

Run the same compile-and-run commands from Task 1.

Expected: `GameConfiguration tests passed`.

### Task 3: Apply the width-based Auto Layout constraint

**Files:**
- Modify: `joyplay-ios/GameViewController.swift`

**Step 1: Select the height constraint**

Before `NSLayoutConstraint.activate`, create:

```swift
let webViewHeightConstraint: NSLayoutConstraint
if let ratio = displayMode.heightToWidthRatio {
    webViewHeightConstraint = webView.heightAnchor.constraint(
        equalTo: webView.widthAnchor,
        multiplier: ratio
    )
} else {
    webViewHeightConstraint = webView.heightAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.heightAnchor
    )
}
```

**Step 2: Replace the old percentage constraint**

Add `webViewHeightConstraint` to the activated constraints and remove the old safe-area multiplier constraint. Preserve all background, bottom, leading, and trailing constraints.

### Task 4: Verify the app

**Files:**
- Verify: `joyplay-ios.xcodeproj`

**Step 1: Run focused tests and diff checks**

Expected: tests pass, no old `heightRatio` references remain, and no unrelated source changes appear.

**Step 2: Build without signing**

```bash
xcodebuild -project joyplay-ios.xcodeproj -scheme joyplay-ios -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/joyplay-ios-derived-data build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`.

**Step 3: Record runtime boundary**

The build verifies the constraints compile. Actual phone rendering still requires a simulator or device check.
