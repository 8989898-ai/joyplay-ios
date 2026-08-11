import Foundation

@main
private enum DemoConfigurationTests {
    static func main() {
        expect(
            GameDisplayMode.allCases.map(\.title) == ["Full Screen", "Half Screen", "Large Half Screen"],
            "Demo mode titles should keep their English fallbacks"
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
        expect(
            DemoGameURLConfiguration.additionalQueryItems.count == 1,
            "Demo URL configuration should contain only its native marker"
        )
        expect(
            DemoGameURLConfiguration.additionalQueryItems.first?.name == "isNativeDemo",
            "Demo URL configuration should own the native Demo marker name"
        )
        expect(
            DemoGameURLConfiguration.additionalQueryItems.first?.value == "1",
            "Demo URL configuration should keep isNativeDemo=1"
        )

        print("Demo configuration tests passed")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fputs("Test failed: \(message)\n", stderr)
            exit(1)
        }
    }
}
