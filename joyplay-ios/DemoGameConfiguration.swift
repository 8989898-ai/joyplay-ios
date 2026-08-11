import Foundation

enum GameLaunchCredentials {
    static let appKey = "ste5a6lxxrtu10bmnc6g"
    static let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE3ODU0OTExNzEsImFjY291bnRJZCI6IjIwODMxMjcwNzQxNzU0NTUyMzIifQ.gdzel2RMXHKwyEG6AaQg-sObDx6H_O9Tmo2XGzfcOJU"
}

enum DemoGameURLConfiguration {
    static let additionalQueryItems = [
        URLQueryItem(name: "isNativeDemo", value: "1")
    ]
}

enum GameLaunchPresentation {
    case pushed
    case embedded
}

enum GameBackDestination {
    case previousScreen
    case fullModeTab
}

extension GameDisplayMode {
    var title: String {
        switch self {
        case .full:
            return String(localized: "game.mode.full", defaultValue: "Full Screen")
        case .half:
            return String(localized: "game.mode.half", defaultValue: "Half Screen")
        case .largeHalf:
            return String(localized: "game.mode.large_half", defaultValue: "Large Half Screen")
        }
    }

    var tabIconFillRatio: CGFloat {
        switch self {
        case .full:
            return 1.0
        case .half:
            return 0.5
        case .largeHalf:
            return 0.7
        }
    }

    var launchPresentation: GameLaunchPresentation {
        self == .full ? .pushed : .embedded
    }

    var usesGameBackground: Bool {
        launchPresentation == .embedded
    }

    var backgroundImageName: String {
        self == .largeHalf ? "voice-room-bg" : "live-room-bg"
    }

    var hidesNavigationBar: Bool {
        self == .full
    }

    var hidesModeTabBar: Bool {
        self != .full
    }

    var backDestination: GameBackDestination {
        self == .full ? .previousScreen : .fullModeTab
    }
}
