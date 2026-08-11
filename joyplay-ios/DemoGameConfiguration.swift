import Foundation

enum GameLaunchCredentials {
    static let appKey = "ste5a6lxxrtu10bmnc6g"
    static let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE3ODU0OTExNzEsImFjY291bnRJZCI6IjIwODMxMjcwNzQxNzU0NTUyMzIifQ.gdzel2RMXHKwyEG6AaQg-sObDx6H_O9Tmo2XGzfcOJU"
}

enum DemoGameURLBuilder {
    static func makeURL(
        appKey: String,
        token: String,
        displayMode: GameDisplayMode
    ) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "joyplay.cn"
        components.path = "/release/index.html"
        components.queryItems = [
            URLQueryItem(name: "appKey", value: appKey),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "gameId", value: "1"),
            URLQueryItem(name: "mini", value: String(displayMode.demoMiniValue)),
            URLQueryItem(name: "isNativeDemo", value: "1")
        ]
        if displayMode == .full {
            components.queryItems?.append(URLQueryItem(name: "safeTop", value: "1"))
        }
        return components.url
    }
}

private extension GameDisplayMode {
    var demoMiniValue: Int {
        switch self {
        case .full:
            return 0
        case .half:
            return 1
        case .largeHalf:
            return 2
        }
    }
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

    var openGameTitle: String {
        switch self {
        case .full:
            return String(localized: "game.open.full", defaultValue: "Open Full-Screen Game")
        case .half:
            return String(localized: "game.open.half", defaultValue: "Open Half-Screen Game")
        case .largeHalf:
            return String(
                localized: "game.open.large_half",
                defaultValue: "Open Large Half-Screen Game"
            )
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
