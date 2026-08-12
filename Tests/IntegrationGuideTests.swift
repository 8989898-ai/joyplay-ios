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

let readme = source(at: "README.md")
let chineseReadme = source(at: "README.zh-CN.md")

guard
    readme.contains("[简体中文](README.zh-CN.md)"),
    chineseReadme.contains("[English](README.md)"),
    readme.contains("# JoyPlay iOS H5 Game Integration Demo"),
    chineseReadme.contains("# JoyPlay iOS H5 游戏接入 Demo"),
    readme.contains("follows the iOS system language"),
    readme.contains("English, the default fallback language, and Simplified Chinese"),
    chineseReadme.contains("跟随 iOS 系统语言，支持英文（默认回退语言）和简体中文")
else {
    fail("README files should provide linked translations and state the Demo language support")
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
    "provided by the backend",
    "notifyGameBalanceDidChange()",
    "recharge",
    "clickRecharge",
    "newTppClose",
    "OpenGameSucc",
    "stop()",
    "The Demo AppKey and Token may be public"
]

for content in requiredContent where !readme.contains(content) {
    fail("README should document \(content)")
}

guard
    readme.contains("`INTEGRATION_REQUEST.yaml` is optional"),
    readme.contains("AI should first scan the target project"),
    readme.contains("cannot be uniquely determined"),
    !readme.contains("replace every `<required>` value")
else {
    fail("README should make automatic discovery the default and only ask about ambiguous business decisions")
}

guard
    let minimumIntegrationRange = readme.range(of: "## Minimal Integration into a Business App"),
    let demoReferenceRange = readme.range(of: "## Demo Implementation Reference"),
    minimumIntegrationRange.lowerBound < demoReferenceRange.lowerBound
else {
    fail("README should present business minimum integration before Demo implementation details")
}

let minimumIntegrationSection = String(
    readme[minimumIntegrationRange.upperBound..<demoReferenceRange.lowerBound]
)
for demoOnlySymbol in [
    "DemoGameData",
    "DemoGameDataSource",
    "DemoRechargePromptPresenter",
    "FullScreenGameViewController",
    "PartialGameViewController"
] where minimumIntegrationSection.contains(demoOnlySymbol) {
    fail("the business minimum integration section should not depend on Demo symbol \(demoOnlySymbol)")
}

let demoReferenceSection = String(readme[demoReferenceRange.lowerBound...])
guard
    readme.contains("Copy only the `joyplay-ios/JoyPlayIntegration/` directory into a business app"),
    readme.contains("Do not copy Demo view controllers, navigation, recharge prompts, or assets"),
    demoReferenceSection.contains("The following files only make this repository's Demo runnable and are not business integration code"),
    demoReferenceSection.contains("`joyplay-ios/FullScreenGameViewController.swift`"),
    demoReferenceSection.contains("`joyplay-ios/DemoRechargePromptPresenter.swift`")
else {
    fail("README should clearly distinguish copyable business code from Demo-only implementation")
}

guard
    readme.contains("gameURL: backendGameURL"),
    readme.contains("DemoGameDataSource.mockBackendResponseJSON"),
    readme.contains("decoded by `JSONDecoder` into `[DemoGameData]`"),
    readme.contains("The backend URL must not already contain `safeTop` or `paddingBottom`"),
    readme.contains("On its first full-screen layout, `GameWebView` appends `safeTop=1`"),
    readme.contains("gameWebView.attach(to: view)"),
    readme.contains("Do not copy the Demo view controllers"),
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


for requiredChineseContent in [
    "## 业务工程最小接入",
    "## Demo 实现参考",
    "后端下发",
    "Demo AppKey 和 Token 允许公开"
] where !chineseReadme.contains(requiredChineseContent) {
    fail("README.zh-CN.md should retain the complete Chinese guide: \(requiredChineseContent)")
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
