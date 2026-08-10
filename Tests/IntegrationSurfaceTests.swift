import Foundation

private func fail(_ message: String) -> Never {
    fputs("Test failed: \(message)\n", stderr)
    exit(1)
}

private func source(at path: String) -> String {
    guard let value = try? String(contentsOfFile: path, encoding: .utf8) else {
        fail("\(path) should exist")
    }
    return value
}

let configurationSource = source(at: "joyplay-ios/JoyPlayIntegration/GameConfiguration.swift")
guard configurationSource.contains("enum GameEvent: String, CaseIterable") else {
    fail("GameConfiguration should expose the documented callbacks as GameEvent")
}

guard configurationSource.contains("if displayMode == .full") else {
    fail("safeTop and paddingBottom should only be added for full-screen games")
}

let gameWebViewSource = source(at: "joyplay-ios/JoyPlayIntegration/GameWebView.swift")
guard
    gameWebViewSource.contains("private let onEvent: (GameEvent) -> Void"),
    gameWebViewSource.contains("onEvent: @escaping (GameEvent) -> Void"),
    gameWebViewSource.contains("private let automaticallyShowsRechargePrompt: Bool"),
    gameWebViewSource.contains("func notifyGameBalanceDidChange()"),
    gameWebViewSource.contains("onEvent(event)"),
    !gameWebViewSource.contains("onClose")
else {
    fail("GameWebView should expose one complete host-facing event surface")
}

guard gameWebViewSource.contains("webView.scrollView.contentInsetAdjustmentBehavior = .never") else {
    fail("GameWebView should not automatically inset content for the safe area")
}

guard
    gameWebViewSource.contains("aspectRatio: GameAspectRatio? = nil"),
    gameWebViewSource.contains("backgroundColor = .black"),
    gameWebViewSource.contains("webView.topAnchor.constraint(equalTo: topAnchor)"),
    gameWebViewSource.contains("webView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)"),
    gameWebViewSource.contains("multiplier: aspectRatio.heightMultiplier")
else {
    fail("embedded GameWebView should add the bottom safe area below its ratio-sized WKWebView")
}

guard
    gameWebViewSource.contains("override func layoutSubviews()"),
    gameWebViewSource.contains("window.safeAreaInsets.bottom"),
    gameWebViewSource.contains("paddingBottom: paddingBottom")
else {
    fail("GameWebView should load with the window's bottom safe-area height")
}

let fullScreenHostSource = source(at: "joyplay-ios/GameViewController.swift")
guard
    fullScreenHostSource.contains("onEvent:"),
    fullScreenHostSource.contains("event == .close"),
    fullScreenHostSource.contains("if isMovingFromParent"),
    fullScreenHostSource.contains("gameWebView.stop()")
else {
    fail("the full-screen host should close only for the close event and stop on host exit")
}

guard
    fullScreenHostSource.contains("if displayMode != .full, aspectRatio != nil"),
    fullScreenHostSource.contains("gameWebView.topAnchor.constraint(equalTo: view.topAnchor)"),
    fullScreenHostSource.contains("gameWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)"),
    !fullScreenHostSource.contains("equalTo: view.safeAreaLayoutGuide.heightAnchor")
else {
    fail("the full-screen game should extend to every physical screen edge")
}

let embeddedHostSource = source(at: "joyplay-ios/GameModeTabBarController.swift")
guard
    embeddedHostSource.contains("onEvent:"),
    embeddedHostSource.contains("event == .close"),
    embeddedHostSource.contains("gameWebView.stop()"),
    embeddedHostSource.contains("aspectRatio: aspectRatio"),
    embeddedHostSource.contains("gameWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)"),
    !embeddedHostSource.contains("gameWebView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)"),
    !embeddedHostSource.contains("equalTo: gameWebView.widthAnchor")
else {
    fail("the embedded host should pass its ratio and pin the outer GameWebView to the screen bottom")
}

print("Integration surface tests passed")
