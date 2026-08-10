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
expect(
    GameDisplayMode.allCases.map(\.title) == ["Full Screen", "Half Screen", "Large Half Screen"],
    "不加载本地化资源时，底部 Tab 应回退英文"
)
expect(GameDisplayMode.full.tabIconFillRatio == 1.0, "全屏 Tab 图标应填满屏幕轮廓")
expect(GameDisplayMode.half.tabIconFillRatio == 0.5, "半屏 Tab 图标应填充一半屏幕轮廓")
expect(GameDisplayMode.sevenTenths.tabIconFillRatio == 0.7, "大半屏 Tab 图标应填充七成屏幕轮廓")
expect(GameDisplayMode.full.miniValue == 0, "全屏应映射为 mini=0")
expect(GameDisplayMode.half.miniValue == 1, "半屏应映射为 mini=1")
expect(GameDisplayMode.sevenTenths.miniValue == 2, "大半屏应映射为 mini=2")
expect(GameDisplayMode.full.launchPresentation == .pushed, "全屏游戏应通过导航 push 展示")
expect(GameDisplayMode.half.launchPresentation == .embedded, "半屏游戏应在当前 Tab 展示")
expect(GameDisplayMode.sevenTenths.launchPresentation == .embedded, "大半屏游戏应在当前 Tab 展示")
expect(!GameDisplayMode.full.usesGameBackground, "全屏入口不需要游戏背景")
expect(GameDisplayMode.half.usesGameBackground, "半屏入口应使用游戏背景")
expect(GameDisplayMode.sevenTenths.usesGameBackground, "大半屏入口应使用游戏背景")
expect(GameDisplayMode.half.backgroundImageName == "live-room-bg", "半屏应使用直播间背景")
expect(GameDisplayMode.sevenTenths.backgroundImageName == "voice-room-bg", "大半屏应使用语聊房背景")
expect(GameDisplayMode.full.hidesNavigationBar, "全屏游戏应隐藏导航栏")
expect(!GameDisplayMode.half.hidesNavigationBar, "半屏游戏应显示导航栏")
expect(!GameDisplayMode.sevenTenths.hidesNavigationBar, "大半屏游戏应显示导航栏")
expect(!GameDisplayMode.full.hidesModeTabBar, "全屏入口应保留模式 Tab Bar")
expect(GameDisplayMode.half.hidesModeTabBar, "进入半屏场景后应隐藏模式 Tab Bar")
expect(GameDisplayMode.sevenTenths.hidesModeTabBar, "进入大半屏场景后应隐藏模式 Tab Bar")
expect(GameDisplayMode.full.backDestination == .previousScreen, "全屏返回应保留原导航行为")
expect(GameDisplayMode.half.backDestination == .fullModeTab, "半屏返回应切换到全屏 Tab")
expect(GameDisplayMode.sevenTenths.backDestination == .fullModeTab, "大半屏返回应切换到全屏 Tab")

expect(GameLaunchCredentials.appKey == "ste5a6lxxrtu10bmnc6g", "AppKey 应使用固定配置")
expect(!GameLaunchCredentials.token.isEmpty, "Token 应使用固定配置")

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
expect(GameEvent.insufficientBalance.showsRechargePrompt, "余额不足事件应支持充值提示")
expect(GameEvent.recharge.showsRechargePrompt, "主动充值事件应支持充值提示")
expect(!GameEvent.close.showsRechargePrompt, "关闭事件不应展示充值弹窗")
expect(!GameEvent.openGameSuccess.showsRechargePrompt, "加载成功事件不应展示充值弹窗")
expect(
    GameRechargePrompt.message == "请展示APP的充值界面，当玩家充值成功之后，原生调用 JS方法，通知游戏刷新玩家余额",
    "充值弹窗提示文案应正确"
)
expect(GameRechargePrompt.notRechargedTitle == "未充值", "取消按钮应显示未充值")
expect(GameRechargePrompt.notifyGameTitle == "通知游戏", "确认按钮应显示通知游戏")
expect(
    GameBridgeScript.balanceRefresh == "HttpTool.NativeToJs('recharge')",
    "通知游戏时应调用文档定义的余额刷新 JS"
)

for (displayMode, expectedMini) in zip(GameDisplayMode.allCases, ["0", "1", "2"]) {
    let integrationURL = GameURLBuilder.makeURL(
        appKey: GameLaunchCredentials.appKey,
        token: GameLaunchCredentials.token,
        displayMode: displayMode
    )
    if let integrationURL,
       let components = URLComponents(url: integrationURL, resolvingAgainstBaseURL: false) {
        let queryItemNames = Set((components.queryItems ?? []).map(\.name))
        expect(!queryItemNames.contains("isNativeDemo"), "业务接入链接默认不应标记为 Demo")
    }

    let url = GameURLBuilder.makeURL(
        appKey: GameLaunchCredentials.appKey,
        token: GameLaunchCredentials.token,
        displayMode: displayMode,
        isNativeDemo: true
    )
    expect(url != nil, "Demo 固定参数应生成游戏链接")

    if let url,
       let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )
        expect(components.scheme == "https", "游戏链接应使用 HTTPS")
        expect(components.host == "joyplay.cn", "游戏链接域名应正确")
        expect(components.path == "/release/index.html", "游戏链接路径应正确")
        expect(queryItems["appKey"] == GameLaunchCredentials.appKey, "AppKey 应使用固定配置")
        expect(queryItems["token"] == GameLaunchCredentials.token, "Token 应使用固定配置")
        expect(queryItems["gameId"] == "1", "gameId 应固定为 1")
        expect(queryItems["mini"] == expectedMini, "mini 应来自展示模式")
        expect(queryItems["isNativeDemo"] == "1", "Demo 游戏链接应携带 isNativeDemo=1")
    }
}

print("GameConfiguration tests passed")
