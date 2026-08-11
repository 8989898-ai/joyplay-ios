import Foundation

struct DemoGameData {
    let gameURL: URL
    let widthHeightRatio: CGFloat?
    let displayMode: GameDisplayMode
}

enum DemoGameDataSource {
    static let gameData: [DemoGameData] = [
        DemoGameData(
            gameURL: URL(string: "https://joyplay.cn/release/index.html?appKey=ste5a6lxxrtu10bmnc6g&token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE3ODU0OTExNzEsImFjY291bnRJZCI6IjIwODMxMjcwNzQxNzU0NTUyMzIifQ.gdzel2RMXHKwyEG6AaQg-sObDx6H_O9Tmo2XGzfcOJU&gameId=1&mini=0&isNativeDemo=1")!,
            widthHeightRatio: nil,
            displayMode: .full
        ),
        DemoGameData(
            gameURL: URL(string: "https://joyplay.cn/release/index.html?appKey=ste5a6lxxrtu10bmnc6g&token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE3ODU0OTExNzEsImFjY291bnRJZCI6IjIwODMxMjcwNzQxNzU0NTUyMzIifQ.gdzel2RMXHKwyEG6AaQg-sObDx6H_O9Tmo2XGzfcOJU&gameId=1&mini=1&isNativeDemo=1")!,
            widthHeightRatio: 1.0,
            displayMode: .half
        ),
        DemoGameData(
            gameURL: URL(string: "https://joyplay.cn/release/index.html?appKey=ste5a6lxxrtu10bmnc6g&token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE3ODU0OTExNzEsImFjY291bnRJZCI6IjIwODMxMjcwNzQxNzU0NTUyMzIifQ.gdzel2RMXHKwyEG6AaQg-sObDx6H_O9Tmo2XGzfcOJU&gameId=1&mini=2&isNativeDemo=1")!,
            widthHeightRatio: 2.0 / 3.0,
            displayMode: .largeHalf
        )
    ]
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
