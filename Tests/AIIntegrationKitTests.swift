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

let fileManager = FileManager.default
let corePaths = [
    "joyplay-ios/JoyPlayIntegration/GameConfiguration.swift",
    "joyplay-ios/JoyPlayIntegration/GameWebView.swift"
]
for path in corePaths where !fileManager.fileExists(atPath: path) {
    fail("the distributable core source should contain \(path)")
}

let obsoletePaths = [
    "joyplay-ios/GameConfiguration.swift",
    "joyplay-ios/GameWebView.swift"
]
for path in obsoletePaths where fileManager.fileExists(atPath: path) {
    fail("the core source should have one canonical location; remove \(path)")
}

let demoConfigurationPath = "joyplay-ios/DemoGameConfiguration.swift"
guard fileManager.fileExists(atPath: demoConfigurationPath) else {
    fail("Demo-only game configuration should exist at \(demoConfigurationPath)")
}

let demoRechargePromptPath = "joyplay-ios/DemoRechargePromptPresenter.swift"
guard fileManager.fileExists(atPath: demoRechargePromptPath) else {
    fail("Demo-only recharge UI should exist at \(demoRechargePromptPath)")
}

let coreConfiguration = source(at: corePaths[0])
let coreSource = corePaths.map(source).joined(separator: "\n")
let demoOnlySymbols = [
    "var title: String",
    "var openGameTitle: String",
    "var modeIconFillRatio: CGFloat",
    "var backgroundImageName: String"
]
for symbol in demoOnlySymbols where coreConfiguration.contains(symbol) {
    fail("the distributable core should not contain Demo-only symbol \(symbol)")
}

let forbiddenCoreSymbols = [
    "isNativeDemo",
    "enum GameURLBuilder",
    "var miniValue",
    "additionalURLQueryItems",
    "GameRechargePrompt",
    "automaticallyShowsRechargePrompt",
    "UIAlertController",
    "hostingViewController",
    "showsRechargePrompt"
]
for symbol in forbiddenCoreSymbols where coreSource.contains(symbol) {
    fail("the distributable core should not contain Demo or host UI symbol \(symbol)")
}

guard
    coreSource.contains("enum GameURLRuntimeAdapter"),
    coreSource.contains("appendingFullScreenParameters"),
    coreSource.contains("gameURL: URL")
else {
    fail("the distributable core should accept a backend URL and only add full-screen runtime parameters")
}

let demoConfiguration = source(at: demoConfigurationPath)
for symbol in demoOnlySymbols where !demoConfiguration.contains(symbol) {
    fail("the Demo configuration should contain \(symbol)")
}
for obsoleteSymbol in [
    "GameLaunchPresentation",
    "GameBackDestination",
    "tabIconFillRatio",
    "launchPresentation",
    "usesGameBackground",
    "hidesNavigationBar",
    "hidesModeTabBar",
    "backDestination"
] where demoConfiguration.contains(obsoleteSymbol) {
    fail("the Demo configuration should remove obsolete Tab Bar symbol \(obsoleteSymbol)")
}
guard
    demoConfiguration.contains("struct DemoGameData: Decodable"),
    demoConfiguration.contains("DemoGameDataSource"),
    demoConfiguration.contains("static let mockBackendResponseJSON = \"\"\""),
    demoConfiguration.contains("static let gameData = try! JSONDecoder().decode("),
    !demoConfiguration.contains("GameLaunchCredentials"),
    !demoConfiguration.contains("URLComponents"),
    !demoConfiguration.contains("makeURL"),
    !demoConfiguration.contains("demoMiniValue")
else {
    fail("the Demo configuration should decode three complete game dictionaries from its mock JSON")
}

let demoRechargePrompt = source(at: demoRechargePromptPath)
guard
    demoRechargePrompt.contains("UIAlertController"),
    demoRechargePrompt.contains("game.recharge_prompt.message"),
    demoRechargePrompt.contains("onNotifyGame")
else {
    fail("the Demo recharge presenter should own the localized alert and notify action")
}

let agentInstructions = source(at: "AGENTS.md")
let requiredAgentRules = [
    "INTEGRATION_REQUEST.yaml",
    "optional",
    "automatically scan",
    "cannot be uniquely determined",
    "JoyPlayIntegration",
    "attach(to:)",
    "DemoGameConfiguration.swift",
    "FullScreenGameViewController.swift",
    "GameModeSelectionViewController.swift",
    "PartialGameViewController.swift",
    "DemoRechargePromptPresenter",
    "Do not copy",
    "docs/plans",
    "historical",
    "newTppClose",
    "widthHeightRatio",
    "notifyGameBalanceDidChange()",
    "core source does not present recharge UI",
    "in-source mock JSON containing three complete URLs",
    "backend URL must not contain `safeTop` or `paddingBottom`",
    "appends `safeTop=1`",
    "xcodebuild",
    "real H5"
]
for rule in requiredAgentRules where !agentInstructions.contains(rule) {
    fail("AGENTS.md should document \(rule)")
}


let chineseAgentInstructions = source(at: "AGENTS.zh-CN.md")
guard
    chineseAgentInstructions.contains("[English](AGENTS.md)"),
    chineseAgentInstructions.contains("JoyPlay iOS AI 接入规则"),
    agentInstructions.contains("[简体中文](AGENTS.zh-CN.md)"),
    agentInstructions.contains("AGENTS.md is authoritative")
else {
    fail("AGENTS.md should be authoritative English instructions with a linked Chinese translation")
}

if agentInstructions.contains("- `ViewController.swift`") {
    fail("AGENTS.md should not list the removed redundant Demo root controller")
}

let requestTemplate = source(at: "INTEGRATION_REQUEST.yaml")
let requiredRequestFields = [
    "project_path:",
    "scheme:",
    "ui_framework: UIKit",
    "minimum_ios: '15.6'",
    "full:",
    "half:",
    "large_half:",
    "host_controller:",
    "close_behavior:",
    "game_url_source:",
    "invalid_url_behavior:",
    "backend_must_omit_safe_top: true",
    "client_appends_safe_top_for_full_screen: true",
    "width_height_ratio_source:",
    "invalid_ratio_behavior:",
    "ui_owner: host",
    "recharge_handler:",
    "notify_game_after_success: true"
]
for field in requiredRequestFields where !requestTemplate.contains(field) {
    fail("INTEGRATION_REQUEST.yaml should contain \(field)")
}

guard
    requestTemplate.contains("optional"),
    requestTemplate.contains("AI automatically scans"),
    requestTemplate.contains("null"),
    !requestTemplate.contains("<请填写>")
else {
    fail("INTEGRATION_REQUEST.yaml should be an optional AI-generated override and record without required placeholders")
}


for chineseComment in ["本文件", "自动扫描", "无法唯一确定"] where requestTemplate.contains(chineseComment) {
    fail("INTEGRATION_REQUEST.yaml comments should be readable by international integrators")
}

for chineseLog in [
    "原生通知JS",
    "游戏链接追加全屏参数失败",
    "开始加载游戏",
    "游戏回调"
] where coreSource.contains(chineseLog) {
    fail("the distributable core should use English diagnostic logs: \(chineseLog)")
}

if requestTemplate.contains("automatically_shows_demo_prompt") {
    fail("INTEGRATION_REQUEST.yaml should not expose the removed core Demo prompt switch")
}

print("AI integration kit tests passed")
