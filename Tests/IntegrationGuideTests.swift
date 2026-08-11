import Foundation

private func fail(_ message: String) -> Never {
    fputs("Test failed: \(message)\n", stderr)
    exit(1)
}

guard let readme = try? String(contentsOfFile: "README.md", encoding: .utf8) else {
    fail("README.md should exist")
}

private func source(at path: String) -> String {
    guard let value = try? String(contentsOfFile: path, encoding: .utf8) else {
        fail("\(path) should exist")
    }
    return value
}

let requiredContent = [
    "iOS 15.6",
    "joyplay-ios/JoyPlayIntegration/GameConfiguration.swift",
    "joyplay-ios/JoyPlayIntegration/GameWebView.swift",
    "DemoGameConfiguration.swift",
    "FullScreenGameViewController.swift",
    "GameModeSelectionViewController.swift",
    "PartialGameViewController.swift",
    "DemoRechargePromptPresenter.swift",
    "AGENTS.md",
    "INTEGRATION_REQUEST.yaml",
    "gameId=1",
    "mini=0",
    "mini=1",
    "mini=2",
    "paddingBottom",
    "isNativeDemo=1",
    "widthHeightRatio",
    "GameWebView(",
    "gameURL:",
    "onEvent:",
    "后端下发",
    "notifyGameBalanceDidChange()",
    "recharge",
    "clickRecharge",
    "newTppClose",
    "OpenGameSucc",
    "stop()",
    "Demo AppKey 和 Token 允许公开"
]

for content in requiredContent where !readme.contains(content) {
    fail("README should document \(content)")
}

guard
    readme.contains("gameURL: backendGameURL"),
    !readme.contains("gameWebView.translatesAutoresizingMaskIntoConstraints = false"),
    !readme.contains("appKey: businessAppKey"),
    !readme.contains("token: businessToken")
else {
    fail("business integration examples should pass the complete backend game URL")
}

if readme.contains("同时复制 `FullScreenGameViewController.swift`") {
    fail("the shortest integration path should use GameWebView directly instead of copying a Demo controller")
}

let gameWebView = source(at: "joyplay-ios/JoyPlayIntegration/GameWebView.swift")
for forbiddenSymbol in [
    "isNativeDemo",
    "UIAlertController",
    "automaticallyShowsRechargePrompt",
    "GameRechargePrompt"
] where gameWebView.contains(forbiddenSymbol) {
    fail("the distributable GameWebView should not know Demo or host UI symbol \(forbiddenSymbol)")
}

let configuration = source(at: "joyplay-ios/JoyPlayIntegration/GameConfiguration.swift")
if configuration.contains("var heightToWidthRatio") {
    fail("display modes should not define host layout ratios")
}

let demoHost = source(at: "joyplay-ios/ViewController.swift")
guard
    demoHost.contains("backendWidthHeightRatios"),
    !demoHost.contains("GameAspectRatio")
else {
    fail("the Demo host should pass backend ratios without constructing a core aspect-ratio type")
}

let embeddedHost = source(at: "joyplay-ios/PartialGameViewController.swift")
let gameWebViewSource = source(at: "joyplay-ios/JoyPlayIntegration/GameWebView.swift")
guard
    embeddedHost.contains("widthHeightRatio: widthHeightRatio"),
    !embeddedHost.contains("GameAspectRatio"),
    gameWebViewSource.contains("aspectRatio.heightMultiplier")
else {
    fail("the embedded host should pass the backend ratio directly to GameWebView")
}

for demoPath in [
    "joyplay-ios/FullScreenGameViewController.swift",
    "joyplay-ios/GameModeSelectionViewController.swift",
    "joyplay-ios/PartialGameViewController.swift"
] where !source(at: demoPath).contains("gameURL:") {
    fail("\(demoPath) should pass a complete Demo-owned URL into the core API")
}

let demoRechargePrompt = source(at: "joyplay-ios/DemoRechargePromptPresenter.swift")
guard
    demoRechargePrompt.contains("UIAlertController"),
    demoRechargePrompt.contains("onNotifyGame")
else {
    fail("the Demo should own its recharge alert and notify action")
}

print("Integration guide tests passed")
