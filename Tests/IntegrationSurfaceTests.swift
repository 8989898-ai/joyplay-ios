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

guard
    configurationSource.contains("enum GameURLRuntimeAdapter"),
    configurationSource.contains("isValidBackendGameURL"),
    configurationSource.contains("appendingPaddingBottom"),
    !configurationSource.contains("enum GameURLBuilder"),
    !configurationSource.contains("var miniValue")
else {
    fail("the core should only adapt the backend URL with runtime paddingBottom")
}

let gameWebViewSource = source(at: "joyplay-ios/JoyPlayIntegration/GameWebView.swift")
guard
    gameWebViewSource.contains("private let onEvent: (GameEvent) -> Void"),
    gameWebViewSource.contains("onEvent: @escaping (GameEvent) -> Void"),
    gameWebViewSource.contains("private let gameURL: URL"),
    gameWebViewSource.contains("gameURL: URL"),
    gameWebViewSource.contains("init?("),
    gameWebViewSource.contains("widthHeightRatio: CGFloat? = nil"),
    gameWebViewSource.contains("GameURLRuntimeAdapter.isValidBackendGameURL(gameURL)"),
    gameWebViewSource.contains("let validatedAspectRatio = GameAspectRatio("),
    gameWebViewSource.contains("widthHeightRatio: widthHeightRatio"),
    gameWebViewSource.contains("guard widthHeightRatio == nil"),
    gameWebViewSource.contains("case .half, .largeHalf:"),
    gameWebViewSource.contains("func notifyGameBalanceDidChange()"),
    gameWebViewSource.contains("onEvent(event)"),
    !gameWebViewSource.contains("private let appKey"),
    !gameWebViewSource.contains("private let token"),
    !gameWebViewSource.contains("additionalURLQueryItems"),
    !gameWebViewSource.contains("onClose"),
    !gameWebViewSource.contains("UIAlertController"),
    !gameWebViewSource.contains("automaticallyShowsRechargePrompt")
else {
    fail("GameWebView should expose events and URL extension without owning host UI")
}

guard gameWebViewSource.contains("webView.scrollView.contentInsetAdjustmentBehavior = .never") else {
    fail("GameWebView should not automatically inset content for the safe area")
}

guard gameWebViewSource.contains("self.translatesAutoresizingMaskIntoConstraints = false") else {
    fail("GameWebView should declare its own Auto Layout participation")
}

guard
    gameWebViewSource.contains("private var isStopped = false"),
    gameWebViewSource.contains("guard !isStopped else"),
    gameWebViewSource.contains("deinit"),
    gameWebViewSource.contains("stop()")
else {
    fail("GameWebView should own idempotent final lifecycle cleanup")
}

guard
    !gameWebViewSource.contains("aspectRatio: GameAspectRatio? = nil"),
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
    gameWebViewSource.contains("if displayMode == .full"),
    gameWebViewSource.contains("GameURLRuntimeAdapter.appendingPaddingBottom"),
    gameWebViewSource.contains("to: gameURL")
else {
    fail("GameWebView should append the window's bottom safe-area height only for full screen")
}

let fullScreenHostSource = source(at: "joyplay-ios/GameViewController.swift")
guard
    fullScreenHostSource.contains("onEvent:"),
    fullScreenHostSource.contains("handleGameEvent"),
    fullScreenHostSource.contains("case .insufficientBalance, .recharge:"),
    fullScreenHostSource.contains("DemoRechargePromptPresenter.present"),
    fullScreenHostSource.contains("gameWebView?.notifyGameBalanceDidChange()"),
    fullScreenHostSource.contains("case .close:"),
    fullScreenHostSource.contains("case .openGameSuccess:"),
    fullScreenHostSource.contains("if isMovingFromParent"),
    fullScreenHostSource.contains("gameWebView?.stop()")
else {
    fail("the full-screen Demo host should explicitly own recharge, close, and success behavior")
}

guard
    fullScreenHostSource.contains("init(gameURL: URL)"),
    fullScreenHostSource.contains("displayMode: .full"),
    !fullScreenHostSource.contains("widthHeightRatio:"),
    !fullScreenHostSource.contains("GameAspectRatio"),
    !fullScreenHostSource.contains("gameWebView.translatesAutoresizingMaskIntoConstraints = false"),
    fullScreenHostSource.contains("gameWebView.topAnchor.constraint(equalTo: view.topAnchor)"),
    fullScreenHostSource.contains("gameWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)"),
    !fullScreenHostSource.contains("equalTo: view.safeAreaLayoutGuide.heightAnchor")
else {
    fail("the full-screen game should extend to every physical screen edge")
}

let embeddedHostSource = source(at: "joyplay-ios/GameModeTabBarController.swift")
guard
    let embedStart = embeddedHostSource.range(of: "private func embedGame(gameURL: URL)"),
    let embedEnd = embeddedHostSource.range(
        of: "private func handleEmbeddedGameEvent",
        range: embedStart.upperBound..<embeddedHostSource.endIndex
    )
else {
    fail("the embedded Demo host should keep its game mounting function")
}
let embedFunctionSource = embeddedHostSource[embedStart.lowerBound..<embedEnd.lowerBound]
guard
    let gameViewCreation = embedFunctionSource.range(of: "guard let gameWebView = GameWebView("),
    let stopButtonAnimation = embedFunctionSource.range(of: "stopGameButtonBreathing()"),
    gameViewCreation.lowerBound < stopButtonAnimation.lowerBound
else {
    fail("an invalid embedded configuration should leave the Demo launch button active")
}

guard
    embeddedHostSource.contains("onEvent:"),
    embeddedHostSource.contains("handleEmbeddedGameEvent"),
    embeddedHostSource.contains("case .insufficientBalance, .recharge:"),
    embeddedHostSource.contains("DemoRechargePromptPresenter.present"),
    embeddedHostSource.contains("embeddedGameView?.notifyGameBalanceDidChange()"),
    embeddedHostSource.contains("case .close:"),
    embeddedHostSource.contains("case .openGameSuccess:"),
    embeddedHostSource.contains("gameWebView.stop()"),
    embeddedHostSource.contains("widthHeightRatio: widthHeightRatio"),
    !embeddedHostSource.contains("GameAspectRatio"),
    !embeddedHostSource.contains("gameWebView.translatesAutoresizingMaskIntoConstraints = false"),
    embeddedHostSource.contains("gameWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)"),
    !embeddedHostSource.contains("gameWebView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)"),
    !embeddedHostSource.contains("equalTo: gameWebView.widthAnchor")
else {
    fail("the embedded Demo host should own all events and preserve its layout and release behavior")
}

print("Integration surface tests passed")
