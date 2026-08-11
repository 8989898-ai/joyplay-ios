import Foundation

@main
private enum DemoConfigurationTests {
    static func main() {
        expect(
            GameDisplayMode.allCases.map(\.title) == ["Full Screen", "Half Screen", "Large Half Screen"],
            "Demo mode titles should keep their English fallbacks"
        )
        expect(
            GameDisplayMode.allCases.map(\.openGameTitle) == [
                "Open Full-Screen Game",
                "Open Half-Screen Game",
                "Open Large Half-Screen Game"
            ],
            "Demo launch-button titles should keep their English fallbacks"
        )
        expect(GameDisplayMode.full.modeIconFillRatio == 1.0, "full-screen icon should remain filled")
        expect(GameDisplayMode.half.modeIconFillRatio == 0.5, "half-screen icon should remain half filled")
        expect(GameDisplayMode.largeHalf.modeIconFillRatio == 0.7, "large-half icon should remain 70% filled")
        expect(GameDisplayMode.half.backgroundImageName == "live-room-bg", "half-screen background should remain unchanged")
        expect(GameDisplayMode.largeHalf.backgroundImageName == "voice-room-bg", "large-half background should remain unchanged")
        expect(GameLaunchCredentials.appKey == "ste5a6lxxrtu10bmnc6g", "Demo AppKey should remain unchanged")
        expect(!GameLaunchCredentials.token.isEmpty, "Demo Token should remain configured")

        let gameData = DemoGameDataSource.makeGameData(
            appKey: "demo-app-key",
            token: "demo-token",
            widthHeightRatios: [
                .half: 1.0,
                .largeHalf: 2.0 / 3.0
            ]
        )
        expect(gameData?.count == 3, "Demo home should receive one game dictionary per display mode")

        for (displayMode, expectedMini) in zip(GameDisplayMode.allCases, ["0", "1", "2"]) {
            guard let data = gameData?.first(where: { $0.displayMode == displayMode }),
                  let components = URLComponents(
                      url: data.gameURL,
                      resolvingAgainstBaseURL: false
                  ) else {
                expect(false, "Demo should provide game data for every display mode")
                continue
            }
            let queryItems = Dictionary(
                uniqueKeysWithValues: (components.queryItems ?? []).map {
                    ($0.name, $0.value ?? "")
                }
            )
            expect(components.scheme == "https", "Demo game URL should use HTTPS")
            expect(components.host == "joyplay.cn", "Demo game URL host should remain unchanged")
            expect(components.path == "/release/index.html", "Demo game URL path should remain unchanged")
            expect(queryItems["appKey"] == "demo-app-key", "Demo URL should include its AppKey")
            expect(queryItems["token"] == "demo-token", "Demo URL should include its Token")
            expect(queryItems["gameId"] == "1", "Demo gameId should remain fixed at 1")
            expect(queryItems["mini"] == expectedMini, "Demo mini should match its display mode")
            expect(queryItems["isNativeDemo"] == "1", "Demo URL should keep isNativeDemo=1")
            expect(queryItems["paddingBottom"] == nil, "Demo URL builder should leave paddingBottom to GameWebView")
            expect(queryItems["safeTop"] == nil, "Every backend Demo URL should leave safeTop to GameWebView")

            switch displayMode {
            case .full:
                expect(data.widthHeightRatio == nil, "Full-screen game data should omit widthHeightRatio")
            case .half:
                expect(data.widthHeightRatio == 1.0, "Half-screen game data should include its backend ratio")
            case .largeHalf:
                expect(
                    data.widthHeightRatio == 2.0 / 3.0,
                    "Large-half game data should include its backend ratio"
                )
            }
        }

        print("Demo configuration tests passed")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fputs("Test failed: \(message)\n", stderr)
            exit(1)
        }
    }
}
