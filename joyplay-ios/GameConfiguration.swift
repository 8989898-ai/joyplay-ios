import Foundation

enum GameLaunchCredentials {
    static let appKey = "ste5a6lxxrtu10bmnc6g"
    static let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE3ODU0OTExNzEsImFjY291bnRJZCI6IjIwODMxMjcwNzQxNzU0NTUyMzIifQ.gdzel2RMXHKwyEG6AaQg-sObDx6H_O9Tmo2XGzfcOJU"
}

enum GameScriptMessage: String, CaseIterable {
    case insufficientBalance = "recharge"
    case recharge = "clickRecharge"
    case close = "newTppClose"
    case openGameSuccess = "OpenGameSucc"
}

enum GameBridgeScript {
    static let experienceLinkCloseForwarder = """
    window.addEventListener('message', function(event) {
        if (
            event.data === 'exit' &&
            window.webkit &&
            window.webkit.messageHandlers &&
            window.webkit.messageHandlers.newTppClose
        ) {
            window.webkit.messageHandlers.newTppClose.postMessage('');
        }
    });
    """
}

enum GameLaunchPresentation {
    case pushed
    case embedded
}

enum GameBackDestination {
    case previousScreen
    case fullModeTab
}

enum GameDisplayMode: CaseIterable, Equatable {
    case full
    case half
    case sevenTenths

    var title: String {
        switch self {
        case .full:
            return String(localized: "game.mode.full", defaultValue: "Full Screen")
        case .half:
            return String(localized: "game.mode.half", defaultValue: "Half Screen")
        case .sevenTenths:
            return String(localized: "game.mode.seven_tenths", defaultValue: "70% Screen")
        }
    }

    var tabIconFillRatio: CGFloat {
        switch self {
        case .full:
            return 1.0
        case .half:
            return 0.5
        case .sevenTenths:
            return 0.7
        }
    }

    var launchPresentation: GameLaunchPresentation {
        self == .full ? .pushed : .embedded
    }

    var usesGameBackground: Bool {
        launchPresentation == .embedded
    }

    var miniValue: Int {
        switch self {
        case .full:
            return 0
        case .half:
            return 1
        case .sevenTenths:
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

    var heightToWidthRatio: CGFloat? {
        switch self {
        case .half:
            return 1.0
        case .sevenTenths:
            return 1.5
        case .full:
            return nil
        }
    }
}

enum GameURLBuilder {
    static func makeURL(appKey: String, token: String, displayMode: GameDisplayMode) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "joyplay.cn"
        components.path = "/release/index.html"
        components.queryItems = [
            URLQueryItem(name: "appKey", value: appKey),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "gameId", value: "1"),
            URLQueryItem(name: "mini", value: String(displayMode.miniValue))
        ]
        return components.url
    }
}
