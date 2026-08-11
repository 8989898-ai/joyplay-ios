import Foundation

enum GameEvent: String, CaseIterable {
    case insufficientBalance = "recharge"
    case recharge = "clickRecharge"
    case close = "newTppClose"
    case openGameSuccess = "OpenGameSucc"
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
        additionalURLQueryItems: [URLQueryItem] = []
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
        let reservedQueryNames = Set([
            "appKey", "token", "gameId", "mini", "safeTop", "paddingBottom"
        ])
        queryItems.append(contentsOf: additionalURLQueryItems.filter {
            !reservedQueryNames.contains($0.name)
        })
        components.queryItems = queryItems
        return components.url
    }
}
