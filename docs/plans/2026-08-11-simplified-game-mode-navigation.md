# Simplified Game Mode Navigation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the Demo `UITabBarController` mode flow with a normal button-based entry page, keep full-screen games in `GameViewController`, and move half/large-half games into one reusable partial-mode controller.

**Architecture:** `GameModeSelectionViewController` becomes the navigation root and owns the default full-screen launch button plus three ordinary mode buttons. Full-screen launch pushes a full-only `GameViewController` that loads immediately; half and large-half buttons push `PartialGameViewController`, which shows the existing scene and launch button before mounting `GameWebView`. The distributable `JoyPlayIntegration` files remain unchanged.

**Tech Stack:** Swift 5, UIKit, WebKit through the existing `GameWebView`, Auto Layout, Foundation-based source contract tests, Xcode 16+.

---

### Task 1: Extract the shared circular launch button

**Files:**
- Create: `joyplay-ios/DemoGameLaunchButton.swift`
- Modify: `Tests/ThemeAndGameButtonLayoutTests.swift:26-80`

**Step 1: Write the failing test**

Change `ThemeAndGameButtonLayoutTests.swift` to load `joyplay-ios/DemoGameLaunchButton.swift` and assert that the shared component owns the existing visual and animation contract:

```swift
let launchButtonSource = source(at: "joyplay-ios/DemoGameLaunchButton.swift")

for requiredSource in [
    "configuration.baseBackgroundColor = UIColor(named: \"AccentColor\")",
    "configuration.cornerStyle = .capsule",
    "configuration.titleAlignment = .center",
    "titleLabel?.numberOfLines = 0",
    "CGAffineTransform(scaleX: 0.96, y: 0.96)",
    "CGAffineTransform(scaleX: 1.04, y: 1.04)",
    "withDuration: 0.6",
    "UIAccessibility.isReduceMotionEnabled"
] where !launchButtonSource.contains(requiredSource) {
    fail("DemoGameLaunchButton should preserve \(requiredSource)")
}
```

Keep the existing AccentColor JSON assertion. Remove controller-specific layout assertions from this test; controller placement will be covered by the navigation test.

**Step 2: Run the test to verify it fails**

Run:

```sh
swiftc -module-cache-path /tmp/joyplay-navigation-theme-cache \
  Tests/ThemeAndGameButtonLayoutTests.swift \
  -o /tmp/joyplay-navigation-theme-tests && \
  /tmp/joyplay-navigation-theme-tests
```

Expected: FAIL because `joyplay-ios/DemoGameLaunchButton.swift` does not exist.

**Step 3: Write the minimal implementation**

Create a single reusable `UIButton` subclass. Preserve the existing configuration and make animation lifecycle explicit:

```swift
import UIKit

final class DemoGameLaunchButton: UIButton {
    init(title: String) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = UIColor(named: "AccentColor")
        configuration.cornerStyle = .capsule
        configuration.titleAlignment = .center
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 14,
            leading: 28,
            bottom: 14,
            trailing: 28
        )
        super.init(frame: .zero)
        self.configuration = configuration
        titleLabel?.numberOfLines = 0
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startBreathing() {
        guard !isHidden, !UIAccessibility.isReduceMotionEnabled else {
            stopBreathing()
            return
        }
        layer.removeAllAnimations()
        transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            options: [.curveEaseInOut, .autoreverse, .repeat, .allowUserInteraction]
        ) { [weak self] in
            self?.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
        }
    }

    func stopBreathing() {
        layer.removeAllAnimations()
        transform = .identity
    }
}
```

Do not add delegate protocols, closures, or styling configuration that only has one current value.

**Step 4: Run focused verification**

Run the command from Step 2.

Expected: `Theme and game-button layout tests passed`.

Run:

```sh
xcodebuild -project joyplay-ios.xcodeproj \
  -scheme joyplay-ios \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/joyplay-navigation-button-derived-data \
  build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`.

**Step 5: Commit**

```sh
git add joyplay-ios/DemoGameLaunchButton.swift Tests/ThemeAndGameButtonLayoutTests.swift
git commit -m "refactor: extract demo game launch button"
```

### Task 2: Add the reusable partial-mode controller

**Files:**
- Create: `joyplay-ios/PartialGameViewController.swift`
- Create: `Tests/GameModeNavigationTests.swift`
- Modify: `joyplay-ios/DemoGameConfiguration.swift:55-100`
- Modify: `Tests/DemoConfigurationTests.swift:6-24`

**Step 1: Write the failing navigation/lifecycle test**

Create a Foundation source contract test that verifies:

```swift
let partialSource = source(at: "joyplay-ios/PartialGameViewController.swift")

for requiredSource in [
    "final class PartialGameViewController: UIViewController",
    "private let displayMode: GameDisplayMode",
    "private let widthHeightRatio: CGFloat",
    "DemoGameLaunchButton(",
    "DemoGameURLBuilder.makeURL(",
    "guard let gameWebView = GameWebView(",
    "widthHeightRatio: widthHeightRatio",
    "gameWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)",
    "case .insufficientBalance, .recharge:",
    "case .close:",
    "removeGameView()",
    "gameWebView.stop()",
    "gameButton.isHidden = false"
] where !partialSource.contains(requiredSource) {
    fail("PartialGameViewController should preserve \(requiredSource)")
}

guard !partialSource.contains("popViewController(animated:") else {
    fail("newTppClose should not pop the partial-mode controller")
}
```

Also isolate the `openGame()` function and assert that `GameWebView` creation appears before `gameButton.stopBreathing()`. This preserves the current invalid-configuration behavior: a failed initializer leaves the launch button active.

**Step 2: Run the test to verify it fails**

Run:

```sh
swiftc -module-cache-path /tmp/joyplay-navigation-flow-cache \
  Tests/GameModeNavigationTests.swift \
  -o /tmp/joyplay-navigation-flow-tests && \
  /tmp/joyplay-navigation-flow-tests
```

Expected: FAIL because `PartialGameViewController.swift` does not exist.

**Step 3: Implement `PartialGameViewController`**

Implement one controller for `.half` and `.largeHalf` only:

```swift
final class PartialGameViewController: UIViewController {
    private let displayMode: GameDisplayMode
    private let appKey: String
    private let token: String
    private let widthHeightRatio: CGFloat
    private var gameWebView: GameWebView?

    private lazy var backgroundImageView = UIImageView(
        image: UIImage(named: displayMode.backgroundImageName)
    )
    private lazy var gameButton = DemoGameLaunchButton(title: displayMode.openGameTitle)
}
```

Required behavior:

1. Add `GameDisplayMode.openGameTitle` to `DemoGameConfiguration.swift` by moving the current three localized launch-button titles out of the old controller; add English-fallback assertions to `DemoConfigurationTests`.
2. In `viewDidLoad`, use the existing localized `game.title` title, add the scene image edge-to-edge, and center the `160 x 160` launch button.
3. Start/stop breathing in `viewDidAppear`/`viewWillDisappear`.
4. In `openGame()`, build the URL and initialize `GameWebView` before hiding/stopping the button.
5. Mount the valid WebView with leading, trailing, and physical-bottom constraints only.
6. Handle recharge exactly like the current embedded host.
7. On `.close`, call `stop()`, remove the WebView, clear the reference, show the button, and restart breathing.
8. When `isMovingFromParent`, call `stop()` on any mounted WebView. Do not Pop from the H5 close callback.

Do not copy or change layout calculations owned by `GameWebView`.

**Step 4: Run focused verification**

Run the test from Step 2.

Expected: `Game mode navigation tests passed`.

Run:

```sh
swiftc -module-cache-path /tmp/joyplay-navigation-demo-cache \
  joyplay-ios/JoyPlayIntegration/GameConfiguration.swift \
  joyplay-ios/DemoGameConfiguration.swift \
  Tests/DemoConfigurationTests.swift \
  -o /tmp/joyplay-navigation-demo-tests && \
  /tmp/joyplay-navigation-demo-tests
```

Expected: `Demo configuration tests passed`.

Run the unsigned simulator build with a fresh `-derivedDataPath /tmp/joyplay-navigation-partial-derived-data`.

Expected: `BUILD SUCCEEDED`.

**Step 5: Commit**

```sh
git add joyplay-ios/PartialGameViewController.swift joyplay-ios/DemoGameConfiguration.swift \
  Tests/DemoConfigurationTests.swift Tests/GameModeNavigationTests.swift
git commit -m "feat: add partial game controller"
```

### Task 3: Add the ordinary-button mode selection controller

**Files:**
- Create: `joyplay-ios/GameModeSelectionViewController.swift`
- Modify: `Tests/GameModeNavigationTests.swift`

**Step 1: Extend the failing navigation test**

Add assertions that the selection controller:

```swift
let selectionSource = source(at: "joyplay-ios/GameModeSelectionViewController.swift")

for requiredSource in [
    "final class GameModeSelectionViewController: UIViewController",
    "DemoGameLaunchButton(",
    "UIStackView(",
    "axis = .horizontal",
    "distribution = .fillEqually",
    "fullModeButton.isSelected = true",
    "DemoGameURLBuilder.makeURL(",
    "displayMode: .full",
    "GameViewController(",
    "PartialGameViewController(",
    "displayMode: displayMode",
    "widthHeightRatio: widthHeightRatio"
] where !selectionSource.contains(requiredSource) {
    fail("GameModeSelectionViewController should preserve \(requiredSource)")
}

guard
    !selectionSource.contains("UITabBarController"),
    !selectionSource.contains("GameWebView(")
else {
    fail("the selection page should use ordinary buttons and should not mount a game WebView")
}
```

Assert the selection page centers its `160 x 160` full-screen launch button and constrains the ordinary-button stack to the bottom safe area.

**Step 2: Run the test to verify it fails**

Run the Task 2 test command.

Expected: FAIL because `GameModeSelectionViewController.swift` does not exist.

**Step 3: Implement the selection controller**

Create a normal `UIViewController` that receives the current AppKey, Token, and backend ratio dictionary. Reuse the current mode icon drawing code under the non-Tab-Bar name `GameModeIcon`.

Build three ordinary `UIButton`s using `UIButton.Configuration.plain()`:

```swift
private func makeModeButton(for mode: GameDisplayMode) -> UIButton {
    var configuration = UIButton.Configuration.plain()
    configuration.title = mode.title
    configuration.image = GameModeIcon.make(fillRatio: mode.modeIconFillRatio)
    configuration.imagePlacement = .top
    configuration.imagePadding = 4

    let button = UIButton(configuration: configuration)
    button.tag = GameDisplayMode.allCases.firstIndex(of: mode) ?? 0
    button.addTarget(self, action: #selector(selectMode(_:)), for: .touchUpInside)
    return button
}
```

Give the selected button a visible state without introducing a new theme type:

```swift
button.configurationUpdateHandler = { button in
    var configuration = button.configuration
    configuration?.baseForegroundColor = button.isSelected
        ? UIColor(named: "AccentColor")
        : .secondaryLabel
    button.configuration = configuration
}
```

Keep the full button selected whenever this controller is visible. The full button itself is a no-op; the centered circular button builds the full URL and temporarily calls the current initializer as `GameViewController(gameURL: gameURL, displayMode: .full)`. A half/large-half button validates that its backend ratio exists, then pushes `PartialGameViewController` without building a URL or creating a WebView. Task 4 removes the temporary mode argument when `GameViewController` becomes full-only.

Do not add a custom container-controller protocol or coordinator.

**Step 4: Run focused verification**

Run the navigation test and the unsigned simulator build with `-derivedDataPath /tmp/joyplay-navigation-selection-derived-data`.

Expected: test passes and `BUILD SUCCEEDED`.

**Step 5: Commit**

```sh
git add joyplay-ios/GameModeSelectionViewController.swift Tests/GameModeNavigationTests.swift
git commit -m "feat: add game mode selection page"
```

### Task 4: Make `GameViewController` full-screen only

**Files:**
- Modify: `joyplay-ios/GameViewController.swift:3-87`
- Modify: `joyplay-ios/GameModeSelectionViewController.swift`
- Modify: `Tests/GameModeNavigationTests.swift`
- Modify: `Tests/IntegrationSurfaceTests.swift:92-116`

**Step 1: Write the failing full-screen-only assertions**

Require `GameViewController` to:

```swift
guard
    fullSource.contains("init(gameURL: URL)"),
    fullSource.contains("displayMode: .full"),
    fullSource.contains("gameWebView.topAnchor.constraint(equalTo: view.topAnchor)"),
    fullSource.contains("gameWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)"),
    !fullSource.contains("private let displayMode"),
    !fullSource.contains("private let widthHeightRatio"),
    !fullSource.contains("if displayMode != .full")
else {
    fail("GameViewController should be a full-screen-only host")
}
```

Update `IntegrationSurfaceTests` so it no longer expects a ratio argument in the full-screen host.

**Step 2: Run tests to verify they fail**

Run:

```sh
swiftc -module-cache-path /tmp/joyplay-navigation-surface-cache \
  Tests/IntegrationSurfaceTests.swift \
  -o /tmp/joyplay-navigation-surface-tests && \
  /tmp/joyplay-navigation-surface-tests
```

Then run the Task 2 navigation test command.

Expected: both fail against the current generic `GameViewController`.

**Step 3: Simplify `GameViewController`**

- Keep only `gameURL` state.
- Initialize `GameWebView` with `.full` and no ratio.
- Set the existing full-screen title.
- Always hide the navigation bar in `viewWillAppear` and restore it in `viewWillDisappear`.
- Keep all four event branches and current recharge behavior.
- Replace the vertical branch with direct top/bottom constraints.
- Update the selection controller call site to `GameViewController(gameURL: gameURL)`.

Do not change `GameWebView` or full-screen URL generation.

**Step 4: Run focused verification**

Run both tests from Step 2 and an unsigned build using `-derivedDataPath /tmp/joyplay-navigation-full-derived-data`.

Expected: tests pass and `BUILD SUCCEEDED`.

**Step 5: Commit**

```sh
git add joyplay-ios/GameViewController.swift joyplay-ios/GameModeSelectionViewController.swift \
  Tests/GameModeNavigationTests.swift Tests/IntegrationSurfaceTests.swift
git commit -m "refactor: make game controller full screen only"
```

### Task 5: Switch the root flow and remove Tab Bar-only code

**Files:**
- Modify: `joyplay-ios/ViewController.swift:9-18`
- Modify: `joyplay-ios/DemoGameConfiguration.swift:45-100`
- Delete: `joyplay-ios/GameModeTabBarController.swift`
- Modify: `Tests/DemoConfigurationTests.swift:6-24`
- Modify: `Tests/GameModeNavigationTests.swift`
- Modify: `Tests/AIIntegrationKitTests.swift:44-56,104-123`
- Modify: `Tests/IntegrationGuideTests.swift:19-26,81-103`
- Modify: `Tests/IntegrationSurfaceTests.swift:118-154`
- Modify: `README.md:7-34`
- Modify: `AGENTS.md:20-29`

**Step 1: Write failing removal/root assertions**

Update tests to require:

```swift
guard
    viewControllerSource.contains("GameModeSelectionViewController("),
    !viewControllerSource.contains("GameModeTabBarController")
else {
    fail("the Demo root should use the ordinary-button selection controller")
}

guard !fileManager.fileExists(atPath: "joyplay-ios/GameModeTabBarController.swift") else {
    fail("the obsolete Tab Bar controller should be removed")
}
```

In `DemoConfigurationTests`, rename `tabIconFillRatio` assertions to `modeIconFillRatio`, retain titles/backgrounds/credentials/URL assertions, and remove assertions for:

- `GameLaunchPresentation`
- `GameBackDestination`
- `usesGameBackground`
- `hidesModeTabBar`
- `backDestination`

Replace current-contract test references to `GameModeTabBarController.swift` with `GameModeSelectionViewController.swift` and `PartialGameViewController.swift`. Require the partial host to pass the raw ratio, mount to the physical bottom, own every event branch, and remove only its WebView on close.

**Step 2: Run tests to verify they fail**

Run:

```sh
swiftc -module-cache-path /tmp/joyplay-navigation-demo-cache \
  joyplay-ios/JoyPlayIntegration/GameConfiguration.swift \
  joyplay-ios/DemoGameConfiguration.swift \
  Tests/DemoConfigurationTests.swift \
  -o /tmp/joyplay-navigation-demo-tests && \
  /tmp/joyplay-navigation-demo-tests
```

Then run the Task 2 navigation test command.

Run the current-contract tests:

```sh
for test_file in \
  Tests/AIIntegrationKitTests.swift \
  Tests/IntegrationGuideTests.swift \
  Tests/IntegrationSurfaceTests.swift; do
  test_name="$(basename "$test_file" .swift)"
  swiftc -module-cache-path "/tmp/joyplay-navigation-${test_name}-cache" \
    "$test_file" -o "/tmp/joyplay-navigation-${test_name}" && \
    "/tmp/joyplay-navigation-${test_name}"
done
```

Expected: FAIL because the root, old source file, configuration, and current documentation still describe the Tab Bar flow.

**Step 3: Perform the minimal flow switch**

- Change `ViewController` to replace the navigation stack with `GameModeSelectionViewController`.
- Remove `GameModeTabBarController.swift`.
- Rename `tabIconFillRatio` to `modeIconFillRatio`.
- Remove only the Demo properties/enums made unused by this redesign.
- Keep `title`, `backgroundImageName`, URL builder, credentials, and mode-to-`mini` mapping.
- Update README Demo instructions and the file table to describe the ordinary-button selection page and partial-mode controller.
- Update the Demo-only exclusion list in AGENTS.md to name both new controllers.
- Update the source contract tests to follow the new file boundaries and lifecycle.

Do not touch `JoyPlayIntegration`, `Localizable.xcstrings`, unrelated assets, or existing historical plan files.

**Step 4: Run focused verification**

Run every command from Step 2, then run the localization and theme tests:

```sh
swiftc -module-cache-path /tmp/joyplay-navigation-localization-cache \
  Tests/LocalizationTests.swift \
  -o /tmp/joyplay-navigation-localization-tests && \
  /tmp/joyplay-navigation-localization-tests

swiftc -module-cache-path /tmp/joyplay-navigation-theme-cache \
  Tests/ThemeAndGameButtonLayoutTests.swift \
  -o /tmp/joyplay-navigation-theme-tests && \
  /tmp/joyplay-navigation-theme-tests
```

Finally, run an unsigned build with `-derivedDataPath /tmp/joyplay-navigation-root-derived-data`.

Expected: all tests pass and `BUILD SUCCEEDED`.

**Step 5: Commit**

```sh
git add joyplay-ios/ViewController.swift joyplay-ios/DemoGameConfiguration.swift \
  joyplay-ios/GameModeSelectionViewController.swift README.md AGENTS.md \
  Tests/AIIntegrationKitTests.swift Tests/DemoConfigurationTests.swift \
  Tests/GameModeNavigationTests.swift Tests/IntegrationGuideTests.swift \
  Tests/IntegrationSurfaceTests.swift
git add -u joyplay-ios/GameModeTabBarController.swift
git commit -m "refactor: replace game mode tab bar flow"
```

### Task 6: Run the complete verification matrix

**Files:**
- Verify only; do not modify source unless a preceding task requirement is unmet.

**Step 1: Run all standalone tests**

```sh
swiftc -module-cache-path /tmp/joyplay-final-core-cache \
  joyplay-ios/JoyPlayIntegration/GameConfiguration.swift Tests/main.swift \
  -o /tmp/joyplay-final-core-tests && /tmp/joyplay-final-core-tests

swiftc -module-cache-path /tmp/joyplay-final-demo-cache \
  joyplay-ios/JoyPlayIntegration/GameConfiguration.swift \
  joyplay-ios/DemoGameConfiguration.swift Tests/DemoConfigurationTests.swift \
  -o /tmp/joyplay-final-demo-tests && /tmp/joyplay-final-demo-tests

for test_file in \
  Tests/AIIntegrationKitTests.swift \
  Tests/GameModeNavigationTests.swift \
  Tests/IntegrationGuideTests.swift \
  Tests/IntegrationSurfaceTests.swift \
  Tests/LocalizationTests.swift \
  Tests/ThemeAndGameButtonLayoutTests.swift; do
  test_name="$(basename "$test_file" .swift)"
  swiftc -module-cache-path "/tmp/joyplay-final-${test_name}-cache" \
    "$test_file" -o "/tmp/joyplay-final-${test_name}" && \
    "/tmp/joyplay-final-${test_name}"
done
```

Expected: every test prints its success message.

**Step 2: Compile the localization catalog**

```sh
mkdir -p /tmp/joyplay-navigation-xcstrings
xcrun xcstringstool compile joyplay-ios/Localizable.xcstrings \
  --output-directory /tmp/joyplay-navigation-xcstrings
```

Expected: command exits `0` and produces compiled English and Simplified Chinese string resources.

**Step 3: Confirm the Xcode container and Scheme**

```sh
xcodebuild -list -project joyplay-ios.xcodeproj
```

Expected: project and Scheme both include `joyplay-ios`.

**Step 4: Run the unsigned simulator build**

```sh
xcodebuild -project joyplay-ios.xcodeproj \
  -scheme joyplay-ios \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/joyplay-navigation-final-derived-data \
  build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`.

**Step 5: Inspect the final diff and worktree**

```sh
git diff --check
git status --short
git diff --stat HEAD~5..HEAD
```

Expected: no whitespace errors; only planned source/test/docs changes plus the user's pre-existing `xcuserdata` modification appear. Do not stage or revert that user-owned file.

**Step 6: Record pending manual validation**

Report as still requiring a simulator/device and real H5:

- default full selection and ordinary-button appearance;
- full-screen immediate load after the circular launch button;
- half/large-half scene entry without automatic game load;
- partial launch, `newTppClose`, button restoration, and reopen;
- navigation back cleanup;
- scene backgrounds, ratio, safe-area appearance, four H5 callbacks, and recharge refresh.

Do not claim static/build success proves these runtime behaviors.
