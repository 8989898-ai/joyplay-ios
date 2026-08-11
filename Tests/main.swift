import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("Test failed: \(message)\n", stderr)
        exit(1)
    }
}

let squareAspectRatio = GameAspectRatio(widthHeightRatio: 1.0)
expect(squareAspectRatio?.heightMultiplier == 1.0, "1:1 后端宽高比应生成 1 倍高度")

let largeHalfAspectRatio = GameAspectRatio(widthHeightRatio: 2.0 / 3.0)
expect(
    abs((largeHalfAspectRatio?.heightMultiplier ?? 0) - 1.5) < 0.000_001,
    "2:3 后端宽高比应生成 1.5 倍高度"
)
expect(GameAspectRatio(widthHeightRatio: 0) == nil, "零宽高比应被拒绝")
expect(GameAspectRatio(widthHeightRatio: -1) == nil, "负宽高比应被拒绝")
expect(GameAspectRatio(widthHeightRatio: .infinity) == nil, "无限宽高比应被拒绝")
expect(GameAspectRatio(widthHeightRatio: .nan) == nil, "非数字宽高比应被拒绝")
expect(GameDisplayMode.full.miniValue == 0, "全屏应映射为 mini=0")
expect(GameDisplayMode.half.miniValue == 1, "半屏应映射为 mini=1")
expect(GameDisplayMode.largeHalf.miniValue == 2, "大半屏应映射为 mini=2")

let eventNames = Set(GameEvent.allCases.map(\.rawValue))
expect(
    eventNames == ["recharge", "clickRecharge", "newTppClose", "OpenGameSucc"],
    "宿主事件应覆盖文档定义的全部 JS 回调"
)
expect(
    GameEvent(rawValue: "newTppClose") == .close,
    "关闭回调应映射到关闭游戏事件"
)
expect(
    GameEvent(rawValue: "unknown") == nil,
    "未知 JS 消息不应被识别"
)
expect(
    GameBridgeScript.balanceRefresh == "HttpTool.NativeToJs('recharge')",
    "通知游戏时应调用文档定义的余额刷新 JS"
)

var observedGameIDs = Set<String>()

for (displayMode, expectedMini) in zip(GameDisplayMode.allCases, ["0", "1", "2"]) {
    let integrationURL = GameURLBuilder.makeURL(
        appKey: "integration-app-key",
        token: "integration-token",
        displayMode: displayMode,
        paddingBottom: 34
    )
    if let integrationURL,
       let components = URLComponents(url: integrationURL, resolvingAgainstBaseURL: false) {
        let queryItemNames = Set((components.queryItems ?? []).map(\.name))
        expect(!queryItemNames.contains("isNativeDemo"), "业务接入链接默认不应标记为 Demo")
    }

    let url = GameURLBuilder.makeURL(
        appKey: "demo-app-key",
        token: "demo-token",
        displayMode: displayMode,
        paddingBottom: 34,
        additionalURLQueryItems: [
            URLQueryItem(name: "isNativeDemo", value: "1"),
            URLQueryItem(name: "gameId", value: "999"),
            URLQueryItem(name: "mini", value: "99"),
            URLQueryItem(name: "safeTop", value: "999"),
            URLQueryItem(name: "paddingBottom", value: "999")
        ]
    )
    expect(url != nil, "Demo 固定参数应生成游戏链接")

    if let url,
       let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
        let allQueryItems = components.queryItems ?? []
        let queryItems = Dictionary(
            uniqueKeysWithValues: allQueryItems.map { ($0.name, $0.value ?? "") }
        )
        expect(components.scheme == "https", "游戏链接应使用 HTTPS")
        expect(components.host == "joyplay.cn", "游戏链接域名应正确")
        expect(components.path == "/release/index.html", "游戏链接路径应正确")
        expect(queryItems["appKey"] == "demo-app-key", "URL 应使用调用方传入的 AppKey")
        expect(queryItems["token"] == "demo-token", "URL 应使用调用方传入的 Token")
        if displayMode == .full {
            expect(queryItems["safeTop"] == "1", "全屏游戏链接应携带 safeTop=1")
            expect(queryItems["paddingBottom"] == "34.0", "全屏游戏链接应携带系统底部安全距离")
        } else {
            expect(queryItems["safeTop"] == nil, "非全屏游戏链接不应携带 safeTop")
            expect(queryItems["paddingBottom"] == nil, "非全屏游戏链接不应携带 paddingBottom")
        }
        observedGameIDs.insert(queryItems["gameId"] ?? "")
        expect(queryItems["mini"] == expectedMini, "mini 应来自展示模式")
        expect(queryItems["isNativeDemo"] == "1", "Demo 游戏链接应携带 isNativeDemo=1")
        expect(allQueryItems.filter { $0.name == "gameId" }.count == 1, "附加参数不应覆盖固定 gameId")
        expect(allQueryItems.filter { $0.name == "mini" }.count == 1, "附加参数不应覆盖模式 mini")
    }
}

expect(observedGameIDs == ["1"], "gameId 应固定为 1")

print("GameConfiguration tests passed")
