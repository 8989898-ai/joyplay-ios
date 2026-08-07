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

let fullScreenHostSource = source(at: "joyplay-ios/GameViewController.swift")
guard
    fullScreenHostSource.contains("onEvent:"),
    fullScreenHostSource.contains("event == .close"),
    fullScreenHostSource.contains("if isMovingFromParent"),
    fullScreenHostSource.contains("gameWebView.stop()")
else {
    fail("the full-screen host should close only for the close event and stop on host exit")
}

let embeddedHostSource = source(at: "joyplay-ios/GameModeTabBarController.swift")
guard
    embeddedHostSource.contains("onEvent:"),
    embeddedHostSource.contains("event == .close"),
    embeddedHostSource.contains("gameWebView.stop()")
else {
    fail("the embedded host should close only for the close event and stop before removal")
}

print("Integration surface tests passed")
