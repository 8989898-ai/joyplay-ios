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
    "safeTop",
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
    readme.contains("DemoGameDataSource.mockBackendResponseJSON"),
    readme.contains("再由 `JSONDecoder` 解码成 `[DemoGameData]`"),
    readme.contains("后端 URL 不能预先包含 `safeTop` 或 `paddingBottom`"),
    readme.contains("全屏 `GameWebView` 首次布局时追加 `safeTop=1`"),
    readme.contains("gameWebView.attach(to: view)"),
    readme.contains("不要复制 `PartialGameViewController`"),
    readme.contains("private func removeEmbeddedGame()"),
    !readme.contains("view.addSubview(gameWebView)"),
    !readme.contains("gameWebView.topAnchor.constraint"),
    !readme.contains("gameWebView.bottomAnchor.constraint"),
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

let demoHost = source(at: "joyplay-ios/GameModeSelectionViewController.swift")
guard
    demoHost.contains("private let gameData = DemoGameDataSource.gameData"),
    !demoHost.contains("GameAspectRatio")
else {
    fail("the Demo host should receive three game dictionaries without constructing a core aspect-ratio type")
}

let embeddedHost = source(at: "joyplay-ios/PartialGameViewController.swift")
let gameWebViewSource = source(at: "joyplay-ios/JoyPlayIntegration/GameWebView.swift")
guard
    embeddedHost.contains("gameURL: gameData.gameURL"),
    embeddedHost.contains("displayMode: gameData.displayMode"),
    embeddedHost.contains("widthHeightRatio: gameData.widthHeightRatio"),
    !embeddedHost.contains("GameAspectRatio"),
    gameWebViewSource.contains("aspectRatio.heightMultiplier")
else {
    fail("the embedded host should pass the backend ratio directly to GameWebView")
}

for demoPath in [
    "joyplay-ios/FullScreenGameViewController.swift",
    "joyplay-ios/PartialGameViewController.swift"
] where !source(at: demoPath).contains("gameURL: gameData.gameURL") {
    fail("\(demoPath) should pass a complete Demo-owned URL into the core API")
}

let selectionHost = source(at: "joyplay-ios/GameModeSelectionViewController.swift")
guard
    selectionHost.contains("private let gameData = DemoGameDataSource.gameData"),
    selectionHost.contains("gameData: selectedGameData")
else {
    fail("the selection page should pass the selected game dictionary to its game host")
}

let demoRechargePrompt = source(at: "joyplay-ios/DemoRechargePromptPresenter.swift")
guard
    demoRechargePrompt.contains("UIAlertController"),
    demoRechargePrompt.contains("onNotifyGame")
else {
    fail("the Demo should own its recharge alert and notify action")
}

print("Integration guide tests passed")
