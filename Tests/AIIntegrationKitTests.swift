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

let coreConfiguration = source(at: corePaths[0])
let demoOnlySymbols = [
    "GameLaunchCredentials",
    "GameLaunchPresentation",
    "GameBackDestination",
    "var title: String",
    "var tabIconFillRatio: CGFloat",
    "var launchPresentation: GameLaunchPresentation",
    "var usesGameBackground: Bool",
    "var backgroundImageName: String",
    "var hidesNavigationBar: Bool",
    "var hidesModeTabBar: Bool",
    "var backDestination: GameBackDestination"
]
for symbol in demoOnlySymbols where coreConfiguration.contains(symbol) {
    fail("the distributable core should not contain Demo-only symbol \(symbol)")
}

let demoConfiguration = source(at: demoConfigurationPath)
for symbol in demoOnlySymbols where !demoConfiguration.contains(symbol) {
    fail("the Demo configuration should contain \(symbol)")
}

let agentInstructions = source(at: "AGENTS.md")
let requiredAgentRules = [
    "INTEGRATION_REQUEST.yaml",
    "JoyPlayIntegration",
    "DemoGameConfiguration.swift",
    "GameModeTabBarController",
    "不要复制",
    "docs/plans",
    "历史",
    "newTppClose",
    "widthHeightRatio",
    "notifyGameBalanceDidChange()",
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
    "app_key_source:",
    "token_source:",
    "width_height_ratio_source:",
    "invalid_ratio_behavior:",
    "recharge_handler:",
    "notify_game_after_success: true"
]
for field in requiredRequestFields where !requestTemplate.contains(field) {
    fail("INTEGRATION_REQUEST.yaml should contain \(field)")
}

print("AI integration kit tests passed")
