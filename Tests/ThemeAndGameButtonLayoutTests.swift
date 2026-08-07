import Foundation

private func fail(_ message: String) -> Never {
    fputs("Test failed: \(message)\n", stderr)
    exit(1)
}

let accentColorURL = URL(
    fileURLWithPath: "joyplay-ios/Assets.xcassets/AccentColor.colorset/Contents.json"
)
guard
    let accentColorData = try? Data(contentsOf: accentColorURL),
    let accentColorRoot = try? JSONSerialization.jsonObject(with: accentColorData) as? [String: Any],
    let colors = accentColorRoot["colors"] as? [[String: Any]],
    let color = colors.first?["color"] as? [String: Any],
    color["color-space"] as? String == "srgb",
    let components = color["components"] as? [String: String],
    components["red"] == "1.000",
    components["green"] == "0.2823529412",
    components["blue"] == "0.1372549020",
    components["alpha"] == "1.000"
else {
    fail("AccentColor should be #FF4823")
}

let controllerURL = URL(fileURLWithPath: "joyplay-ios/GameModeTabBarController.swift")
guard let controllerSource = try? String(contentsOf: controllerURL, encoding: .utf8) else {
    fail("GameModeTabBarController.swift should exist")
}

guard controllerSource.contains("configuration.baseBackgroundColor = UIColor(named: \"AccentColor\")") else {
    fail("open-game buttons should explicitly use AccentColor")
}

guard
    controllerSource.contains("configuration.cornerStyle = .capsule"),
    controllerSource.contains("gameButton.widthAnchor.constraint(equalToConstant: 160)"),
    controllerSource.contains("gameButton.heightAnchor.constraint(equalTo: gameButton.widthAnchor)")
else {
    fail("all open-game buttons should be circular")
}

guard
    controllerSource.contains("configuration.titleAlignment = .center"),
    controllerSource.contains("button.titleLabel?.numberOfLines = 0")
else {
    fail("circular open-game button titles should remain centered and readable")
}

guard
    controllerSource.contains("gameButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)"),
    controllerSource.contains("gameButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)"),
    !controllerSource.contains("gameButton.trailingAnchor.constraint"),
    !controllerSource.contains("gameButton.bottomAnchor.constraint")
else {
    fail("all open-game buttons should be centered")
}

guard
    controllerSource.contains("CGAffineTransform(scaleX: 0.96, y: 0.96)"),
    controllerSource.contains("CGAffineTransform(scaleX: 1.04, y: 1.04)"),
    controllerSource.contains("UIView.animate("),
    controllerSource.contains("withDuration: 0.6"),
    controllerSource.contains(".curveEaseInOut"),
    controllerSource.contains(".autoreverse"),
    controllerSource.contains(".repeat"),
    controllerSource.contains(".allowUserInteraction")
else {
    fail("all open-game buttons should use the gentle breathing animation")
}

guard
    controllerSource.contains("UIAccessibility.isReduceMotionEnabled"),
    controllerSource.contains("override func viewDidAppear(_ animated: Bool)"),
    controllerSource.contains("override func viewWillDisappear(_ animated: Bool)"),
    controllerSource.contains("startGameButtonBreathing()"),
    controllerSource.contains("stopGameButtonBreathing()"),
    controllerSource.contains("gameButton.layer.removeAllAnimations()")
else {
    fail("the breathing animation should respect accessibility and controller lifecycle")
}

print("Theme and game-button layout tests passed")
