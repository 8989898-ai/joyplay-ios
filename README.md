English | [简体中文](README.zh-CN.md)

# JoyPlay iOS H5 Game Integration Demo

This project demonstrates how to integrate JoyPlay H5 games into a Swift and UIKit app. It covers full-screen, half-screen, and large-half-screen presentation, JavaScript callbacks, and balance refresh after recharge.

The Demo UI follows the iOS system language and supports English, the default fallback language, and Simplified Chinese. The distributable `JoyPlayIntegration` core does not present business UI; integrating apps own and localize their recharge and error UI.

## Requirements

- Xcode 16 or later
- Swift 5
- UIKit
- iOS 15.6 or later
- System frameworks: Foundation, UIKit, and WebKit
- No CocoaPods or other third-party dependencies

## Run the Demo First

1. Open `joyplay-ios.xcodeproj` in Xcode.
2. Select the `joyplay-ios` Scheme and any iPhone simulator or device.
3. Run the project. The three standard mode buttons at the bottom select full screen by default. The center circular button opens the full-screen game; the half-screen and large-half-screen buttons first open their corresponding scene pages.

The Demo AppKey and Token may be public. The current Demo represents the three game records returned together by the home-page request as in-source mock JSON and decodes them with `JSONDecoder`. When integrating into a business app, the host uses the complete game URL, mode, and aspect ratio provided by the backend. The client does not construct AppKey, Token, or game parameters.

## Minimal Integration into a Business App

> Copy only the `joyplay-ios/JoyPlayIntegration/` directory into a business app. Do not copy Demo view controllers, navigation, recharge prompts, or assets.

### Core Files to Copy

| File | Purpose |
| --- | --- |
| `joyplay-ios/JoyPlayIntegration/GameConfiguration.swift` | Game mode, URL and ratio validation, full-screen runtime parameters, event names, and balance-refresh JavaScript |
| `joyplay-ios/JoyPlayIntegration/GameWebView.swift` | The single host entry point, responsible for WKWebView, backend URL loading, layout, JavaScript callback registration, and cleanup |

Copying the entire directory avoids missing dependencies. In Xcode's File Inspector, confirm that both Swift files belong to the business App Target.

### Direct Integration with AI

This project also provides:

- `AGENTS.md`: instructs AI to copy only the core source, preserve the game contracts, and run a build verification.
- `INTEGRATION_REQUEST.yaml`: an optional set of business overrides and an integration record, not a form that must be completed before integration.

AI should first scan the target project to locate the project container, Scheme, App Target, candidate host controller, backend game URL, aspect ratio, and recharge entry point. It should use information that can be uniquely determined and ask only about business decisions such as the host controller, close behavior, or recharge entry point when they cannot be uniquely determined.

`INTEGRATION_REQUEST.yaml` is optional. A `null` value delegates discovery to AI; a non-null value overrides the discovery result. Integrators do not need to edit the file. After scanning or clarification, AI may record the final choices in it for review and later maintenance.

Ask AI to run:

> Read `AGENTS.md` and `README.md`, then integrate `joyplay-ios/JoyPlayIntegration/` into the current UIKit project. Automatically locate the integration points and honor existing non-null overrides in `INTEGRATION_REQUEST.yaml`. Ask me only when a business behavior cannot be uniquely determined. Do not copy Demo view controllers, background assets, or navigation. When finished, run an unsigned simulator build for the target Scheme and report real-H5 verification separately.

### Game URL Parameters

For business integration, the backend provides a complete HTTPS game URL that can be opened directly. The host converts it to `URL` and passes it to `GameWebView`. The backend owns these parameters:

| Parameter | Current rule |
| --- | --- |
| `appKey` | Included in the complete URL by the backend |
| `token` | Included in the complete URL by the backend |
| `gameId` | Fixed as `gameId=1` |
| `mini` | Full screen `mini=0`, half screen `mini=1`, large half screen `mini=2` |
| `safeTop` | Omitted by the backend; on its first full-screen layout, `GameWebView` appends `safeTop=1` |
| `paddingBottom` | Omitted by the backend; on its first full-screen layout, `GameWebView` appends the current window bottom safe-area inset in UIKit points |
| `isNativeDemo` | Only the Demo's three fixed URLs contain `isNativeDemo=1`; the business backend omits it by default |

The backend URL must not already contain `safeTop` or `paddingBottom`. If the URL is signed, server-side signature validation must allow the client to append these two parameters or exclude them from the signed fields. On its first full-screen layout, `GameWebView` appends `safeTop=1` and the current bottom safe-area inset. Half screen and large half screen load the backend URL unchanged.

### Add It to a Business Controller

After initializing `GameWebView`, call `attach(to:)` to add it to the business container. The method owns the outer layout for each mode: full screen fills all four edges, while half screen and large half screen pin to the leading, trailing, and bottom edges. The host does not call `addSubview` or create constraints for the game view.

Add the following code to the integrating app's existing business controller. Do not copy the Demo view controllers.

#### Option 1: Full-Screen Business Page

Create `GameWebView` directly in the business app's full-screen controller. Do not pass a ratio for full screen:

```swift
private var gameWebView: GameWebView?

private func openFullScreenGame(backendGameURL: URL) {
    guard let gameWebView = GameWebView(
        gameURL: backendGameURL,
        displayMode: .full,
        onEvent: { [weak self] event in
            self?.handleGameEvent(event)
        }
    ) else {
        handleInvalidGameConfiguration()
        return
    }
    gameWebView.attach(to: view)
    self.gameWebView = gameWebView
}
```

After receiving `.close`, the host pops, dismisses, or removes the game view according to its own navigation. The core stops the game before sending the callback.

#### Option 2: Embed It in an Existing Business Page

A live room or voice-chat room copies only the two core files and places this minimal code in its existing controller. After the business backend returns `widthHeightRatio` as width divided by height, the host passes the complete URL, mode, and original ratio directly to `GameWebView`:

```swift
private var gameWebView: GameWebView?

private func openEmbeddedGame(
    backendGameURL: URL,
    displayMode: GameDisplayMode,
    widthHeightRatio: CGFloat
) {
    guard let gameWebView = GameWebView(
        gameURL: backendGameURL,
        displayMode: displayMode,
        widthHeightRatio: widthHeightRatio,
        onEvent: { [weak self] event in
            self?.handleGameEvent(event)
        }
    ) else {
        handleInvalidGameConfiguration()
        return
    }
    gameWebView.attach(to: view)
    self.gameWebView = gameWebView
}

private func handleGameEvent(_ event: GameEvent) {
    switch event {
    case .insufficientBalance, .recharge:
        openAppRechargePage()
    case .close:
        removeEmbeddedGame()
    case .openGameSuccess:
        recordGameOpened()
    }
}

private func removeEmbeddedGame() {
    gameWebView?.stop()
    gameWebView?.removeFromSuperview()
    gameWebView = nil
}
```

After a successful business recharge, call `gameWebView?.notifyGameBalanceDidChange()`. Also call `removeEmbeddedGame()` when the host actively exits the live or voice-chat room. If `.close` triggered the removal, the core has already called `stop()`; calling it again is safe.

For example, backend `widthHeightRatio=1.0` produces a `1:1` internal `WKWebView`. A value near `0.6667` makes its height approximately 1.5 times its width. The outer half-screen and large-half-screen `GameWebView` pins to the bottom of the screen and has the `WKWebView` height plus the bottom safe-area inset. The `WKWebView` aligns with the outer view's top, and the safe-area region uses the outer view's black background.

`GameWebView` has a failable initializer. It rejects a non-HTTPS URL, a URL without a host, or a URL already containing `safeTop` or `paddingBottom`. Half-screen and large-half-screen modes also reject a missing, non-positive, infinite, or nonnumeric ratio. Full screen rejects a supplied ratio. The business host decides how to report or retry an initialization failure; the core does not hard-code a fallback URL or ratio.

For direct full-screen embedding, use `.full` without `widthHeightRatio`, allowing `GameWebView` to constrain itself to all four page edges. The ratio controls only the native container height in embedded modes; `mini` is already present in the backend URL.

### Unified Event Callback

`onEvent` forwards every registered JavaScript callback to the host:

| H5 message name | `GameEvent` | Meaning |
| --- | --- | --- |
| `recharge` | `.insufficientBalance` | The player's balance is insufficient when placing a bet |
| `clickRecharge` | `.recharge` | The player explicitly taps recharge |
| `newTppClose` | `.close` | The player closes the game |
| `OpenGameSucc` | `.openGameSuccess` | The game loads successfully |

The minimal integration example above handles all four event types. When `newTppClose` arrives, `GameWebView` stops loading and removes its JavaScript handlers before sending `.close`. The host only decides whether to remove the view, pop the page, or perform its own scene-specific close behavior.

### Recharge Handling

`GameWebView` only reports `.insufficientBalance` and `.recharge`; the core source does not present recharge UI. The host opens its own recharge page for both events.

After a successful recharge in the business app, notify the game to refresh the balance:

```swift
gameWebView?.notifyGameBalanceDidChange()
```

The method evaluates:

```javascript
HttpTool.NativeToJs('recharge')
```

The recharge page, cancellation behavior, and failure message belong to the host. The core contains no recharge copy, so another business app does not copy the Demo's localization resources.

### Active Close and Cleanup

When the host actively exits a page instead of reacting to `newTppClose`, stop the WebView before removing it:

```swift
gameWebView?.stop()
gameWebView?.removeFromSuperview()
gameWebView = nil
```

`stop()` stops page loading and unregisters all JavaScript message handlers. A full-screen page can call it before popping; an embedded page can call it when leaving the scene or before creating another game.

### Integration Checklist

- Both core Swift files belong to the business App Target.
- The complete game URL provided by the backend is passed directly to `GameWebView`; the host handles initialization failure according to business requirements.
- Half screen and large half screen pass the backend's original `widthHeightRatio` directly to `GameWebView`; full screen passes no ratio.
- The backend supplies the correct `mini=0/1/2` for full, half, and large half screen.
- Full screen appends `safeTop=1` and the current device `paddingBottom`; half screen and large half screen do not modify the URL.
- All four `GameEvent` cases are handled according to business requirements.
- The host presents its own recharge UI and notifies the game after a successful recharge.
- Active scene exits call `stop()`.
- A real H5 environment verifies rendering, close callbacks, and recharge callbacks.

## Demo Implementation Reference

The following files only make this repository's Demo runnable and are not business integration code. Integrators do not copy them or adopt the Demo's navigation and recharge policy.

| File | Purpose in the Demo |
| --- | --- |
| `joyplay-ios/DemoGameConfiguration.swift` | Mock JSON, the three decoded game records, mode copy, icons, and background configuration |
| `joyplay-ios/DemoRechargePromptPresenter.swift` | Demonstration recharge prompt |
| `joyplay-ios/DemoGameLaunchButton.swift` | Shared circular game launch button and breathing animation |
| `joyplay-ios/FullScreenGameViewController.swift` | Full-screen navigation-push example |
| `joyplay-ios/GameModeSelectionViewController.swift` | Three standard mode buttons and the full-screen launch entry |
| `joyplay-ios/PartialGameViewController.swift` | Half-screen and large-half-screen scenes, delayed loading, and reopening after close |
| `joyplay-ios/Localizable.xcstrings` | English and Simplified Chinese Demo UI copy |
| `joyplay-ios/Assets.xcassets` | Demo button colors and scene backgrounds |

### Demo Data Flow

`DemoGameDataSource.mockBackendResponseJSON` is an in-source mock JSON top-level array, not a formal backend protocol. It shows three complete URLs, presentation modes, and ratios, decoded by `JSONDecoder` into `[DemoGameData]`. At launch, `GameModeSelectionViewController` reads the decoded records. The client does not dynamically construct URLs from AppKey, Token, or mode codes. Each record contains:

- A complete game URL provided by the backend.
- A `displayMode`.
- The original backend `widthHeightRatio`; full screen uses `nil`, while half screen and large half screen use valid width-divided-by-height ratios.

The mode-selection page selects the matching record and passes it to the next controller. Full-screen, half-screen, and large-half-screen pages no longer receive AppKey or Token and do not construct URLs. A business app may decode a backend JSON dictionary into equivalent strongly typed data and pass these three fields directly to `GameWebView`.

### Demo Page Behavior

- `FullScreenGameViewController` hides the navigation bar and pops after receiving `.close`.
- `PartialGameViewController` embeds the game in the current scene and removes only the game view after receiving `.close`.
- Both pages use `DemoRechargePromptPresenter` to present the demonstration prompt. Tapping the notify action calls `notifyGameBalanceDidChange()`.

## Verification Commands

Configuration contract tests:

```sh
swiftc -module-cache-path /tmp/joyplay-module-cache \
  joyplay-ios/JoyPlayIntegration/GameConfiguration.swift Tests/main.swift \
  -o /tmp/joyplay-tests && /tmp/joyplay-tests
```

Demo presentation policy tests:

```sh
swiftc -module-cache-path /tmp/joyplay-demo-module-cache \
  joyplay-ios/JoyPlayIntegration/GameConfiguration.swift \
  joyplay-ios/DemoGameConfiguration.swift \
  Tests/DemoConfigurationTests.swift \
  -o /tmp/joyplay-demo-tests && /tmp/joyplay-demo-tests
```

Unsigned simulator build:

```sh
xcodebuild -project joyplay-ios.xcodeproj \
  -scheme joyplay-ios \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/joyplay-derived-data \
  build CODE_SIGNING_ALLOWED=NO
```
