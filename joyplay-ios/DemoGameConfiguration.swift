import Foundation

/// Demo-only decoded data used to exercise the three supported presentation modes.
struct DemoGameData: Decodable {
    let gameURL: URL
    let widthHeightRatio: CGFloat?
    let displayMode: GameDisplayMode

    private enum CodingKeys: String, CodingKey {
        case gameURL
        case widthHeightRatio
        case displayMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gameURL = try container.decode(URL.self, forKey: .gameURL)
        widthHeightRatio = try container.decodeIfPresent(CGFloat.self, forKey: .widthHeightRatio)

        let displayModeValue = try container.decode(String.self, forKey: .displayMode)
        switch displayModeValue {
        case "full":
            displayMode = .full
        case "half":
            displayMode = .half
        case "largeHalf":
            displayMode = .largeHalf
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .displayMode,
                in: container,
                debugDescription: "Unsupported display mode: \(displayModeValue)"
            )
        }
    }
}

enum DemoGameDataSource {
    /// Demo-only mock records, not a specification of the business backend response shape.
    ///
    /// Each URL is already complete. Business integrations should use the URL and ratio
    /// supplied by their own backend instead of copying these values.
    static let mockBackendResponseJSON = """
    [
      {
        "gameURL": "https://joyplay.cn/release/index.html?appKey=ste5a6lxxrtu10bmnc6g&token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE3ODU0OTExNzEsImFjY291bnRJZCI6IjIwODMxMjcwNzQxNzU0NTUyMzIifQ.gdzel2RMXHKwyEG6AaQg-sObDx6H_O9Tmo2XGzfcOJU&gameId=1&mini=0&isNativeDemo=1",
        "widthHeightRatio": null,
        "displayMode": "full"
      },
      {
        "gameURL": "https://joyplay.cn/release/index.html?appKey=ste5a6lxxrtu10bmnc6g&token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE3ODU0OTExNzEsImFjY291bnRJZCI6IjIwODMxMjcwNzQxNzU0NTUyMzIifQ.gdzel2RMXHKwyEG6AaQg-sObDx6H_O9Tmo2XGzfcOJU&gameId=1&mini=1&isNativeDemo=1",
        "widthHeightRatio": 1.0,
        "displayMode": "half"
      },
      {
        "gameURL": "https://joyplay.cn/release/index.html?appKey=ste5a6lxxrtu10bmnc6g&token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE3ODU0OTExNzEsImFjY291bnRJZCI6IjIwODMxMjcwNzQxNzU0NTUyMzIifQ.gdzel2RMXHKwyEG6AaQg-sObDx6H_O9Tmo2XGzfcOJU&gameId=1&mini=2&isNativeDemo=1",
        "widthHeightRatio": 0.6666666666666666,
        "displayMode": "largeHalf"
      }
    ]
    """

    static let gameData = try! JSONDecoder().decode(
        [DemoGameData].self,
        from: Data(mockBackendResponseJSON.utf8)
    )
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
