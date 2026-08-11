import Foundation

enum GameLaunchCredentials {
    static let appKey = "ste5a6lxxrtu10bmnc6g"
    static let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE3ODU0OTExNzEsImFjY291bnRJZCI6IjIwODMxMjcwNzQxNzU0NTUyMzIifQ.gdzel2RMXHKwyEG6AaQg-sObDx6H_O9Tmo2XGzfcOJU"
}

struct DemoGameData {
    let gameURL: URL
    let widthHeightRatio: CGFloat?
    let displayMode: GameDisplayMode
}

enum DemoGameDataSource {
    static func makeGameData(
        appKey: String,
        token: String,
        widthHeightRatios: [GameDisplayMode: CGFloat]
    ) -> [DemoGameData]? {
        var gameData: [DemoGameData] = []
        for displayMode in GameDisplayMode.allCases {
            guard let gameURL = makeURL(
                appKey: appKey,
                token: token,
                displayMode: displayMode
            ) else {
                return nil
            }
            gameData.append(
                DemoGameData(
                    gameURL: gameURL,
                    widthHeightRatio: widthHeightRatios[displayMode],
                    displayMode: displayMode
                )
            )
        }
        return gameData
    }

    private static func makeURL(
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

    var modeIconFillRatio: CGFloat {
        switch self {
        case .full:
            return 1.0
        case .half:
            return 0.5
        case .largeHalf:
            return 0.7
        }
    }

    var backgroundImageName: String {
        self == .largeHalf ? "voice-room-bg" : "live-room-bg"
    }
}
