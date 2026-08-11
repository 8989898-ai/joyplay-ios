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

print("Game mode navigation tests passed")
