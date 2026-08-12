import Foundation

/// Events forwarded from the fixed JoyPlay H5 message names to the host app.
enum GameEvent: String, CaseIterable {
    /// The game could not continue because the player's balance is insufficient.
    case insufficientBalance = "recharge"
    /// The player explicitly selected the game's recharge entry point.
    case recharge = "clickRecharge"
    /// The player asked to close the game. The host still owns navigation or removal.
    case close = "newTppClose"
    /// The H5 game reported that it opened successfully.
    case openGameSuccess = "OpenGameSucc"
}

enum GameBridgeScript {
    static let balanceRefresh = "HttpTool.NativeToJs('recharge')"
}

struct GameAspectRatio: Equatable {
    /// The backend-provided width divided by height. Pass the original value unchanged.
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
}

enum GameURLRuntimeAdapter {
    /// Validates the complete backend URL before the WebView owns it.
    ///
    /// `safeTop` and `paddingBottom` are rejected because full-screen runtime adaptation
    /// appends them after the view reaches a window.
    static func isValidBackendGameURL(_ gameURL: URL) -> Bool {
        guard gameURL.scheme?.lowercased() == "https",
              gameURL.host?.isEmpty == false,
              let components = URLComponents(
                  url: gameURL,
                  resolvingAgainstBaseURL: false
              ) else {
            return false
        }

        return components.queryItems?.contains(
            where: { $0.name == "safeTop" || $0.name == "paddingBottom" }
        ) != true
    }

    /// Appends the device-dependent parameters used only by full-screen games.
    static func appendingFullScreenParameters(
        paddingBottom: CGFloat,
        to gameURL: URL
    ) -> URL? {
        guard isValidBackendGameURL(gameURL),
              paddingBottom.isFinite,
              paddingBottom >= 0,
              var components = URLComponents(
                  url: gameURL,
                  resolvingAgainstBaseURL: false
              ) else {
            return nil
        }

        let runtimeParameters = "safeTop=1&paddingBottom=\(String(Double(paddingBottom)))"
        if let query = components.percentEncodedQuery, !query.isEmpty {
            components.percentEncodedQuery = "\(query)&\(runtimeParameters)"
        } else {
            components.percentEncodedQuery = runtimeParameters
        }
        return components.url
    }
}
