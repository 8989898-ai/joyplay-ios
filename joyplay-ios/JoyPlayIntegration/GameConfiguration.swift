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
}

enum GameURLRuntimeAdapter {
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
            where: { $0.name == "paddingBottom" }
        ) != true
    }

    static func appendingPaddingBottom(
        _ paddingBottom: CGFloat,
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

        let paddingBottomItem = "paddingBottom=\(String(Double(paddingBottom)))"
        if let query = components.percentEncodedQuery, !query.isEmpty {
            components.percentEncodedQuery = "\(query)&\(paddingBottomItem)"
        } else {
            components.percentEncodedQuery = paddingBottomItem
        }
        return components.url
    }
}
