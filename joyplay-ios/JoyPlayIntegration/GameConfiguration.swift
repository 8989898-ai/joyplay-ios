import Foundation

enum GameLaunchCredentials {
    static let appKey = "ste5a6lxxrtu10bmnc6g"
    static let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE3ODU0OTExNzEsImFjY291bnRJZCI6IjIwODMxMjcwNzQxNzU0NTUyMzIifQ.gdzel2RMXHKwyEG6AaQg-sObDx6H_O9Tmo2XGzfcOJU"
}

enum GameEvent: String, CaseIterable {
    case insufficientBalance = "recharge"
    case recharge = "clickRecharge"
    case close = "newTppClose"
    case openGameSuccess = "OpenGameSucc"

    var showsRechargePrompt: Bool {
        self == .insufficientBalance || self == .recharge
    }
}

enum GameRechargePrompt {
    static var message: String {
        String(
            localized: "game.recharge_prompt.message",
            defaultValue: "Please show the app's recharge screen. After the player recharges successfully, call the JS method from native code to notify the game to refresh the player's balance."
        )
    }

    static var notRechargedTitle: String {
        String(localized: "game.recharge_prompt.not_recharged", defaultValue: "Not Recharged")
    }

    static var notifyGameTitle: String {
        String(localized: "game.recharge_prompt.notify_game", defaultValue: "Notify Game")
    }
}

enum GameBridgeScript {
    static let balanceRefresh = "HttpTool.NativeToJs('recharge')"
}

enum GameLaunchPresentation {
    case pushed
    case embedded
}

enum GameBackDestination {
    case previousScreen
    case fullModeTab
}

struct GameAspectRatio: Equatable {
    let widthHeightRatio: CGFloat

    init?(widthHeightRatio: CGFloat) {
        guard widthHeightRatio.isFinite, widthHeightRatio > 0 else {
            return nil
        }
        self.widthHeightRatio = widthHeightRatio
    }

    var heightMultiplier: CGFloat {
        1 / widthHeightRatio
    }
}

enum GameDisplayMode: CaseIterable, Equatable {
    case full
    case half
    case largeHalf

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

    var miniValue: Int {
        switch self {
        case .full:
            return 0
        case .half:
            return 1
        case .largeHalf:
            return 2
        }
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

enum GameURLBuilder {
    static func makeURL(
        appKey: String,
        token: String,
        displayMode: GameDisplayMode,
        paddingBottom: CGFloat,
        isNativeDemo: Bool = false
    ) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "joyplay.cn"
        components.path = "/release/index.html"
        var queryItems = [
            URLQueryItem(name: "appKey", value: appKey),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "gameId", value: "1"),
            URLQueryItem(name: "mini", value: String(displayMode.miniValue))
        ]
        if displayMode == .full {
            queryItems.append(URLQueryItem(name: "safeTop", value: "1"))
            queryItems.append(URLQueryItem(
                name: "paddingBottom",
                value: String(Double(paddingBottom))
            ))
        }
        if isNativeDemo {
            queryItems.append(URLQueryItem(name: "isNativeDemo", value: "1"))
        }
        components.queryItems = queryItems
        return components.url
    }
}
