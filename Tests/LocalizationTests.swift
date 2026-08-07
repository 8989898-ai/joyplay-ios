import Foundation

private func fail(_ message: String) -> Never {
    fputs("Test failed: \(message)\n", stderr)
    exit(1)
}

let catalogURL = URL(fileURLWithPath: "joyplay-ios/Localizable.xcstrings")
guard let data = try? Data(contentsOf: catalogURL) else {
    fail("Localizable.xcstrings should exist")
}

guard
    let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
    root["sourceLanguage"] as? String == "en",
    let strings = root["strings"] as? [String: Any]
else {
    fail("the catalog should use English as its source language")
}

let expectedValues: [String: [String: String]] = [
    "common.back": [
        "en": "Back",
        "zh-Hans": "返回"
    ],
    "game.mode.full": [
        "en": "Full Screen",
        "zh-Hans": "全屏"
    ],
    "game.mode.half": [
        "en": "Half Screen",
        "zh-Hans": "半屏"
    ],
    "game.mode.seven_tenths": [
        "en": "Large Half Screen",
        "zh-Hans": "大半屏"
    ],
    "game.open.full": [
        "en": "Open Full-Screen Game",
        "zh-Hans": "打开全屏游戏"
    ],
    "game.open.half": [
        "en": "Open Half-Screen Game",
        "zh-Hans": "打开半屏游戏"
    ],
    "game.open.seven_tenths": [
        "en": "Open Large Half-Screen Game",
        "zh-Hans": "打开大半屏游戏"
    ],
    "game.title": [
        "en": "Game",
        "zh-Hans": "游戏"
    ],
    "home.app_key.placeholder": [
        "en": "Enter AppKey",
        "zh-Hans": "请输入 AppKey"
    ],
    "home.enter_button": [
        "en": "Enter",
        "zh-Hans": "进入"
    ],
    "home.section.integration_info": [
        "en": "Integration Information",
        "zh-Hans": "接入信息"
    ],
    "home.title": [
        "en": "H5 Game Integration Demo",
        "zh-Hans": "H5 游戏接入 Demo"
    ],
    "home.token.placeholder": [
        "en": "Enter Game Token",
        "zh-Hans": "请输入游戏 Token"
    ]
]

guard Set(strings.keys) == Set(expectedValues.keys) else {
    fail("the catalog should contain exactly the expected localization keys")
}

for (key, expectedLocalizations) in expectedValues {
    guard
        let entry = strings[key] as? [String: Any],
        let localizations = entry["localizations"] as? [String: Any]
    else {
        fail("\(key) should contain localizations")
    }

    for (language, expectedValue) in expectedLocalizations {
        guard
            let localization = localizations[language] as? [String: Any],
            let stringUnit = localization["stringUnit"] as? [String: Any],
            stringUnit["value"] as? String == expectedValue
        else {
            fail("\(key) should contain the expected \(language) value")
        }
    }
}

print("Localization catalog tests passed")
