# Native Demo URL Parameter Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make every JoyPlay Demo game URL include `isNativeDemo=1` while keeping copied core integration URLs unchanged by default.

**Architecture:** Add an explicit Boolean flag with a default of `false` through `GameWebView` into `GameURLBuilder`. Append the query item only when the Demo call sites pass `true`, avoiding a generic query-item abstraction or a fixed marker in distributable core behavior.

**Tech Stack:** Swift 5, Foundation `URLComponents`, UIKit/WebKit, focused Swift configuration tests, Xcode simulator build.

---

### Task 1: Add the Demo-only URL marker

**Files:**
- Modify: `Tests/main.swift:80-104`
- Modify: `joyplay-ios/JoyPlayIntegration/GameConfiguration.swift:126-140`
- Modify: `joyplay-ios/JoyPlayIntegration/GameWebView.swift:11-24,67-77`
- Modify: `joyplay-ios/GameViewController.swift:7-17`
- Modify: `joyplay-ios/GameModeTabBarController.swift:242-252`
- Modify: `README.md:44-55`

**Step 1: Write the failing test**

Extend the URL tests so a default `GameURLBuilder.makeURL(...)` result has no `isNativeDemo` query item, while `makeURL(..., isNativeDemo: true)` produces `isNativeDemo=1` for full, half, and large-half modes.

**Step 2: Run the test to verify it fails**

Run:

```sh
swiftc -module-cache-path /tmp/joyplay-module-cache \
  joyplay-ios/JoyPlayIntegration/GameConfiguration.swift Tests/main.swift \
  -o /tmp/joyplay-tests && /tmp/joyplay-tests
```

Expected: compilation fails because `makeURL` does not yet accept `isNativeDemo`.

**Step 3: Write the minimal implementation**

- Add `isNativeDemo: Bool = false` to `GameURLBuilder.makeURL`.
- Append `URLQueryItem(name: "isNativeDemo", value: "1")` only when the flag is true.
- Thread the same defaulted flag through `GameWebView`.
- Pass `isNativeDemo: true` at both Demo `GameWebView` creation sites.
- Document that the parameter identifies the Demo and is absent by default for copied integrations.

**Step 4: Run focused verification**

Run the focused test command again. Expected output: `GameConfiguration tests passed`.

Run `git diff --check`. Expected: no output and exit status 0.

**Step 5: Run the unsigned simulator build**

First run `xcodebuild -list -project joyplay-ios.xcodeproj`, then:

```sh
xcodebuild -project joyplay-ios.xcodeproj \
  -scheme joyplay-ios \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/joyplay-native-demo-derived-data \
  build CODE_SIGNING_ALLOWED=NO
```

Expected: `** BUILD SUCCEEDED **`.

**Step 6: Report remaining runtime verification**

Report that a real simulator/device launch is still needed to inspect the actual H5 request and confirm the server recognizes `isNativeDemo=1`.
