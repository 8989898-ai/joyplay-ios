# English and Simplified Chinese Localization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Localize every user-visible local string into English and Simplified Chinese, follow the iOS system language, and fall back to English.

**Architecture:** Store all translations in one `Localizable.xcstrings` catalog whose source language is English. Read strings through `String(localized:defaultValue:)`, keeping an English default at each call site while leaving logs and protocol constants unchanged. The existing file-system-synchronized Xcode group will include the catalog automatically.

**Tech Stack:** UIKit, Swift 5, Xcode string catalogs, Foundation, standalone Swift verification.

---

### Task 1: Add failing localization coverage

**Files:**
- Create: `Tests/LocalizationTests.swift`
- Modify: `Tests/main.swift:12-15`

**Step 1: Write the failing resource test**

Create a standalone Swift test that loads `joyplay-ios/Localizable.xcstrings` as JSON and asserts:

- `sourceLanguage` is `en`.
- All 13 semantic keys exist.
- Every key contains the expected `en` and `zh-Hans` value.

**Step 2: Run the resource test to verify it fails**

Run:

```bash
swift -module-cache-path /tmp/joyplay-localization-module-cache Tests/LocalizationTests.swift
```

Expected: failure because `joyplay-ios/Localizable.xcstrings` does not exist yet.

**Step 3: Update the display-mode fallback expectations first**

Change the existing title expectation in `Tests/main.swift` to `Full Screen`, `Half Screen`, and `Large Half Screen`.

**Step 4: Run the focused configuration test to verify it fails**

Run:

```bash
swiftc -module-cache-path /tmp/joyplay-swift-module-cache joyplay-ios/GameConfiguration.swift Tests/main.swift -o /tmp/joyplay-game-configuration-tests && /tmp/joyplay-game-configuration-tests
```

Expected: failure because `GameDisplayMode.title` still returns Chinese literals.

### Task 2: Add the string catalog

**Files:**
- Create: `joyplay-ios/Localizable.xcstrings`
- Modify: `joyplay-ios.xcodeproj/project.pbxproj:104-108`

**Step 1: Add the translation catalog**

Add English and Simplified Chinese values for:

- `home.title`
- `home.section.integration_info`
- `home.app_key.placeholder`
- `home.token.placeholder`
- `home.enter_button`
- `common.back`
- `game.title`
- `game.mode.full`
- `game.mode.half`
- `game.mode.seven_tenths`
- `game.open.full`
- `game.open.half`
- `game.open.seven_tenths`

Use English as the catalog source language and include explicit `en` and `zh-Hans` localizations for every key.

**Step 2: Register Simplified Chinese in project metadata**

Add `zh-Hans` to `knownRegions` while preserving `developmentRegion = en`.

**Step 3: Run the resource test**

Run:

```bash
swift -module-cache-path /tmp/joyplay-localization-module-cache Tests/LocalizationTests.swift
```

Expected: all catalog assertions pass.

### Task 3: Replace user-visible hardcoded strings

**Files:**
- Modify: `joyplay-ios/ViewController.swift:7-45`
- Modify: `joyplay-ios/GameConfiguration.swift:25-34`
- Modify: `joyplay-ios/GameModeTabBarController.swift:6-166`

**Step 1: Localize the home screen**

Replace the five home-screen strings with `String(localized:defaultValue:)` calls using English defaults.

**Step 2: Localize game-mode titles**

Return localized English-default titles from `GameDisplayMode.title`.

**Step 3: Localize game navigation and launch controls**

Replace the back accessibility label, game title, default game button title, and three mode-specific launch button titles with localized calls.

**Step 4: Run both focused tests**

Run the localization resource test and focused configuration test. Expected: both exit successfully.

### Task 4: Audit and build

**Files:**
- Verify only; no planned edits.

**Step 1: Scan remaining Chinese literals**

Run:

```bash
rg -n --glob '*.swift' '"[^"\\n]*[一-龥][^"\\n]*"' joyplay-ios
```

Expected: only the four explicitly excluded console log strings remain.

**Step 2: Validate the catalog and diff**

Run `xcrun xcstringstool compile joyplay-ios/Localizable.xcstrings --output-directory <temporary-directory>` and `git diff --check`. Expected: both succeed.

**Step 3: Build the app**

Run:

```bash
xcodebuild -quiet -project joyplay-ios.xcodeproj -scheme joyplay-ios -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/joyplay-ios-localization-derived build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED` with the string catalog compiled into English and Simplified Chinese resources.
