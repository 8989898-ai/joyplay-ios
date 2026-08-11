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
    "GameViewController.swift",
    "GameModeTabBarController.swift",
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
    "GameAspectRatio",
    "heightMultiplier",
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
    !readme.contains("appKey: businessAppKey"),
    !readme.contains("token: businessToken")
else {
    fail("business integration examples should pass the complete backend game URL")
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
    demoHost.contains("GameAspectRatio(widthHeightRatio:")
else {
    fail("the Demo host should convert backend ratios before creating the game screen")
}

let embeddedHost = source(at: "joyplay-ios/GameModeTabBarController.swift")
let gameWebViewSource = source(at: "joyplay-ios/JoyPlayIntegration/GameWebView.swift")
guard
    embeddedHost.contains("aspectRatio: aspectRatio"),
    gameWebViewSource.contains("aspectRatio.heightMultiplier")
else {
    fail("the embedded host should inject the backend ratio used to size the WKWebView")
}

for demoPath in [
    "joyplay-ios/GameViewController.swift",
    "joyplay-ios/GameModeTabBarController.swift"
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
