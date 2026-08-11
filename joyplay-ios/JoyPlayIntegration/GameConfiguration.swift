import Foundation

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
