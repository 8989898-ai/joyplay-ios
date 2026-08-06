# Game Entry URL Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the placeholder game page with the real game URL generated from the entered AppKey, Token, fixed game ID, and selected display mode.

**Architecture:** Keep URL construction as a small Foundation-only function in `GameConfiguration.swift` so it can be tested without UIKit or WebKit. `GameViewController` will request that URL once, print its absolute string, and load the same URL in its existing `WKWebView`.

**Tech Stack:** Swift, Foundation `URLComponents`, UIKit, WebKit, command-line Swift tests, Xcode.

---

### Task 1: Specify display-mode and URL behavior

**Files:**
- Modify: `Tests/main.swift`
- Test: `Tests/main.swift`

**Step 1: Write the failing tests**

Add assertions that require:

```swift
expect(GameDisplayMode.full.miniValue == 0, "全屏应映射为 mini=0")
expect(GameDisplayMode.half.miniValue == 1, "半屏应映射为 mini=1")
expect(GameDisplayMode.sevenTenths.miniValue == 2, "大半屏应映射为 mini=2")
expect(GameDisplayMode.sevenTenths.title == "大半屏", "大半屏模式标题应正确")

let url = GameURLBuilder.makeURL(
    appKey: "app key",
    token: "token+value",
    displayMode: .sevenTenths
)
expect(url != nil, "有效参数应生成游戏链接")

if let url,
   let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
    let queryItems = Dictionary(
        uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
    )
    expect(components.scheme == "https", "游戏链接应使用 HTTPS")
    expect(components.host == "game.abv.cn", "游戏链接域名应正确")
    expect(components.path == "/frontend/00lobby00/index.html", "游戏链接路径应正确")
    expect(queryItems["appKey"] == "app key", "AppKey 应来自输入值")
    expect(queryItems["token"] == "token+value", "Token 应来自输入值")
    expect(queryItems["gameId"] == "1", "gameId 应固定为 1")
    expect(queryItems["mini"] == "2", "mini 应来自展示模式")
}
```

**Step 2: Run the test to verify it fails**

Run:

```bash
xcrun swiftc joyplay-ios/GameConfiguration.swift Tests/main.swift -o /tmp/joyplay-game-configuration-tests
/tmp/joyplay-game-configuration-tests
```

Expected: compilation fails because `miniValue` and `GameURLBuilder` do not exist yet.

### Task 2: Implement the minimal URL builder

**Files:**
- Modify: `joyplay-ios/GameConfiguration.swift`
- Test: `Tests/main.swift`

**Step 1: Add the display-mode mapping**

Add a `miniValue: Int` computed property to `GameDisplayMode` and change the `.sevenTenths` title to `大半屏`.

**Step 2: Add URL construction**

Add a Foundation-only builder:

```swift
enum GameURLBuilder {
    static func makeURL(appKey: String, token: String, displayMode: GameDisplayMode) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "game.abv.cn"
        components.path = "/frontend/00lobby00/index.html"
        components.queryItems = [
            URLQueryItem(name: "appKey", value: appKey),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "gameId", value: "1"),
            URLQueryItem(name: "mini", value: String(displayMode.miniValue))
        ]
        return components.url
    }
}
```

**Step 3: Run the focused tests**

Run:

```bash
xcrun swiftc joyplay-ios/GameConfiguration.swift Tests/main.swift -o /tmp/joyplay-game-configuration-tests
/tmp/joyplay-game-configuration-tests
```

Expected: `GameConfiguration tests passed` with exit code 0.

### Task 3: Load and log the actual URL

**Files:**
- Modify: `joyplay-ios/GameViewController.swift`

**Step 1: Replace the placeholder loader**

Rename `loadPlaceholderGame()` to `loadGame()` and replace its body with:

```swift
guard let url = GameURLBuilder.makeURL(
    appKey: appKey,
    token: token,
    displayMode: displayMode
) else {
    return
}
print("打开游戏链接：\(url.absoluteString)")
webView.load(URLRequest(url: url))
```

Update `viewDidLoad()` to call `loadGame()`.

**Step 2: Inspect the surgical diff**

Run:

```bash
git diff --check
git diff -- joyplay-ios/GameConfiguration.swift joyplay-ios/GameViewController.swift Tests/main.swift
```

Expected: no whitespace errors; every changed production line maps directly to URL construction, mode naming/mapping, logging, or loading.

### Task 4: Verify the app target

**Files:**
- Verify: `joyplay-ios.xcodeproj`

**Step 1: Build without signing**

Run:

```bash
xcodebuild -project joyplay-ios.xcodeproj -scheme joyplay-ios -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/joyplay-ios-derived-data build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`.

**Step 2: Record the runtime boundary**

The build and unit tests statically verify the generated request. A simulator/device launch is still required to confirm the console prints the actual URL immediately before the WebView opens it.
