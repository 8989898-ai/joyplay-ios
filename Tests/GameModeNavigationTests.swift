import Foundation

private func fail(_ message: String) -> Never {
    fputs("Test failed: \(message)\n", stderr)
    exit(1)
}

private func source(at path: String) -> String {
    guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
        fail("\(path) should exist")
    }
    return source
}

let viewControllerSource = source(at: "joyplay-ios/ViewController.swift")
guard
    viewControllerSource.contains("GameModeSelectionViewController("),
    !viewControllerSource.contains("GameModeTabBarController")
else {
    fail("the Demo root should use the ordinary-button selection controller")
}

guard !FileManager.default.fileExists(atPath: "joyplay-ios/GameModeTabBarController.swift") else {
    fail("the obsolete Tab Bar controller should be removed")
}

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

guard
    let openGameStart = partialSource.range(of: "@objc private func openGame()"),
    let nextFunction = partialSource.range(
        of: "\n    private func",
        range: openGameStart.upperBound..<partialSource.endIndex
    )
else {
    fail("PartialGameViewController should define an isolated openGame function")
}

let openGameSource = partialSource[openGameStart.lowerBound..<nextFunction.lowerBound]
guard
    let gameWebViewCreation = openGameSource.range(of: "guard let gameWebView = GameWebView("),
    let animationStop = openGameSource.range(of: "gameButton.stopBreathing()"),
    gameWebViewCreation.lowerBound < animationStop.lowerBound
else {
    fail("invalid GameWebView configuration should leave the launch button active")
}

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
    "FullScreenGameViewController(",
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

guard
    selectionSource.contains("gameButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)"),
    selectionSource.contains("gameButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)"),
    selectionSource.contains("gameButton.widthAnchor.constraint(equalToConstant: 160)"),
    selectionSource.contains("gameButton.heightAnchor.constraint(equalTo: gameButton.widthAnchor)"),
    selectionSource.contains("modeButtonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)")
else {
    fail("the selection page should center its launch button and pin mode buttons to the safe-area bottom")
}

guard !FileManager.default.fileExists(atPath: "joyplay-ios/GameViewController.swift") else {
    fail("the generic full-screen controller filename should be removed")
}

let fullSource = source(at: "joyplay-ios/FullScreenGameViewController.swift")
guard
    fullSource.contains("final class FullScreenGameViewController: UIViewController"),
    fullSource.contains("init(gameURL: URL)"),
    fullSource.contains("displayMode: .full"),
    fullSource.contains("gameWebView.topAnchor.constraint(equalTo: view.topAnchor)"),
    fullSource.contains("gameWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)"),
    !fullSource.contains("private let displayMode"),
    !fullSource.contains("private let widthHeightRatio"),
    !fullSource.contains("if displayMode != .full")
else {
    fail("FullScreenGameViewController should be a full-screen-only host")
}

print("Game mode navigation tests passed")
