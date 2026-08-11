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
    "GameLaunchCredentials",
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
    coreSource.contains("appendingPaddingBottom"),
    coreSource.contains("gameURL: URL")
else {
    fail("the distributable core should accept a backend URL and only add runtime paddingBottom")
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
    demoConfiguration.contains("DemoGameURLBuilder"),
    demoConfiguration.contains("URLQueryItem(name: \"isNativeDemo\", value: \"1\")")
else {
    fail("the Demo configuration should own the native Demo URL marker")
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
    "JoyPlayIntegration",
    "DemoGameConfiguration.swift",
    "GameModeSelectionViewController.swift",
    "PartialGameViewController.swift",
    "DemoRechargePromptPresenter",
    "不要复制",
    "docs/plans",
    "历史",
    "newTppClose",
    "widthHeightRatio",
    "notifyGameBalanceDidChange()",
    "核心源码不展示充值 UI",
    "xcodebuild",
    "真实 H5"
]
for rule in requiredAgentRules where !agentInstructions.contains(rule) {
    fail("AGENTS.md should document \(rule)")
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
    "width_height_ratio_source:",
    "invalid_ratio_behavior:",
    "ui_owner: host",
    "recharge_handler:",
    "notify_game_after_success: true"
]
for field in requiredRequestFields where !requestTemplate.contains(field) {
    fail("INTEGRATION_REQUEST.yaml should contain \(field)")
}

if requestTemplate.contains("automatically_shows_demo_prompt") {
    fail("INTEGRATION_REQUEST.yaml should not expose the removed core Demo prompt switch")
}

print("AI integration kit tests passed")
