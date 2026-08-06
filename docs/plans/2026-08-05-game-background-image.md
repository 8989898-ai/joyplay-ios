# Game Background Image Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Display the supplied image as an aspect-filled, non-distorted background across the game page without changing WebView layout.

**Architecture:** Store the JPEG in the existing asset catalog and add one full-bounds `UIImageView` behind the current `WKWebView`. UIKit's `scaleAspectFill` preserves the source aspect ratio while clipping only the overflow required to cover the page.

**Tech Stack:** Swift, UIKit, WebKit, Auto Layout, Xcode asset catalogs

---

### Task 1: Add the background image asset

**Files:**
- Create: `joyplay-ios/Assets.xcassets/voice-chat-bg2.imageset/Contents.json`
- Create: `joyplay-ios/Assets.xcassets/voice-chat-bg2.imageset/voice-chat-bg2.jpg`

**Step 1: Add the image set**

Copy the supplied JPEG into a universal image set named `voice-chat-bg2` and add the matching asset-catalog metadata.

**Step 2: Validate the asset**

Confirm the JPEG is 750 × 1624 and `Contents.json` references the exact filename.

### Task 2: Add the game-page background layer

**Files:**
- Modify: `joyplay-ios/GameViewController.swift`

**Step 1: Add the minimal image view configuration**

Create a private `UIImageView` loaded from `voice-chat-bg2`, set `contentMode` to `.scaleAspectFill`, and enable clipping.

**Step 2: Place it behind the WebView**

Add the image view before the WebView and constrain it to all four edges of the root view. Leave every existing WebView constraint unchanged.

**Step 3: Check the surgical diff**

Run:

```bash
git diff --check
git diff -- joyplay-ios/GameViewController.swift joyplay-ios/Assets.xcassets/voice-chat-bg2.imageset
```

Expected: no whitespace errors; only the background asset and background-view setup are added.

**Step 4: Build the app**

Run:

```bash
xcodebuild -project joyplay-ios.xcodeproj -scheme joyplay-ios -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/joyplay-ios-background-derived-data build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`.

**Step 5: Runtime acceptance check**

Open half-screen and large-half-screen modes. Confirm the image fills the entire game page, keeps its aspect ratio, and is visible above the WebView; confirm the WebView remains bottom-aligned at its prior height.
