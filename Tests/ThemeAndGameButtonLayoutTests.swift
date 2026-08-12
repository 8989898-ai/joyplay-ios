import Foundation

private func fail(_ message: String) -> Never {
    fputs("Test failed: \(message)\n", stderr)
    exit(1)
}

private func source(at path: String) -> String {
    guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
        fail("\(path) should exist")
    }
    return source
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

let launchButtonSource = source(at: "joyplay-ios/DemoGameLaunchButton.swift")

for requiredSource in [
    "configuration.baseBackgroundColor = UIColor(named: \"AccentColor\")",
    "configuration.cornerStyle = .capsule",
    "configuration.titleAlignment = .center",
    "titleLabel?.numberOfLines = 0",
    "CGAffineTransform(scaleX: 0.96, y: 0.96)",
    "CGAffineTransform(scaleX: 1.04, y: 1.04)",
    "withDuration: 0.6",
    "UIAccessibility.isReduceMotionEnabled"
] where !launchButtonSource.contains(requiredSource) {
    fail("DemoGameLaunchButton should preserve \(requiredSource)")
}

print("Theme and game-button layout tests passed")
