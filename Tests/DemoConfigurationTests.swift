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
        expect(GameDisplayMode.full.tabIconFillRatio == 1.0, "full-screen icon should remain filled")
        expect(GameDisplayMode.half.tabIconFillRatio == 0.5, "half-screen icon should remain half filled")
        expect(GameDisplayMode.largeHalf.tabIconFillRatio == 0.7, "large-half icon should remain 70% filled")
        expect(GameDisplayMode.full.launchPresentation == .pushed, "full-screen Demo should remain pushed")
        expect(GameDisplayMode.half.launchPresentation == .embedded, "half-screen Demo should remain embedded")
        expect(GameDisplayMode.largeHalf.launchPresentation == .embedded, "large-half Demo should remain embedded")
        expect(!GameDisplayMode.full.usesGameBackground, "full-screen Demo should not use a scene background")
        expect(GameDisplayMode.half.backgroundImageName == "live-room-bg", "half-screen background should remain unchanged")
        expect(GameDisplayMode.largeHalf.backgroundImageName == "voice-room-bg", "large-half background should remain unchanged")
        expect(GameDisplayMode.full.hidesNavigationBar, "full-screen Demo should still hide the navigation bar")
        expect(GameDisplayMode.half.hidesModeTabBar, "half-screen Demo should still hide the mode tab bar")
        expect(GameDisplayMode.largeHalf.hidesModeTabBar, "large-half Demo should still hide the mode tab bar")
        expect(GameDisplayMode.full.backDestination == .previousScreen, "full-screen back behavior should remain unchanged")
        expect(GameDisplayMode.half.backDestination == .fullModeTab, "half-screen back behavior should remain unchanged")
        expect(GameDisplayMode.largeHalf.backDestination == .fullModeTab, "large-half back behavior should remain unchanged")
        expect(GameLaunchCredentials.appKey == "ste5a6lxxrtu10bmnc6g", "Demo AppKey should remain unchanged")
        expect(!GameLaunchCredentials.token.isEmpty, "Demo Token should remain configured")

        for (displayMode, expectedMini) in zip(GameDisplayMode.allCases, ["0", "1", "2"]) {
            let url = DemoGameURLBuilder.makeURL(
                appKey: "demo-app-key",
                token: "demo-token",
                displayMode: displayMode
            )
            expect(url != nil, "Demo should build a game URL for every display mode")

            guard let url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
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
            expect(
                queryItems["safeTop"] == (displayMode == .full ? "1" : nil),
                "Only the full-screen Demo URL should contain safeTop=1"
            )
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
