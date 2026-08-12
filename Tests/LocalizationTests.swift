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
    "game.mode.full": [
        "en": "Full Screen",
        "zh-Hans": "全屏"
    ],
    "game.mode.half": [
        "en": "Half Screen",
        "zh-Hans": "半屏"
    ],
    "game.mode.large_half": [
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
    "game.open.large_half": [
        "en": "Open Large Half-Screen Game",
        "zh-Hans": "打开大半屏游戏"
    ],
    "game.recharge_prompt.message": [
        "en": "Please show the app's recharge screen. After the player recharges successfully, call the JS method from native code to notify the game to refresh the player's balance.",
        "zh-Hans": "请展示APP的充值界面，当玩家充值成功之后，原生调用 JS方法，通知游戏刷新玩家余额"
    ],
    "game.recharge_prompt.not_recharged": [
        "en": "Not Recharged",
        "zh-Hans": "未充值"
    ],
    "game.recharge_prompt.notify_game": [
        "en": "Notify Game",
        "zh-Hans": "通知游戏"
    ],
    "game.title": [
        "en": "Game",
        "zh-Hans": "游戏"
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
