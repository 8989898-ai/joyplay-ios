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

let agentInstructions = source(at: "AGENTS.md")
let requiredAgentRules = [
    "INTEGRATION_REQUEST.yaml",
    "JoyPlayIntegration",
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
    "seven_tenths:",
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
