import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("Test failed: \(message)\n", stderr)
        exit(1)
    }
}

expect(GameDisplayMode.half.heightToWidthRatio == 1.0, "半屏宽高比应为 1:1")
expect(GameDisplayMode.sevenTenths.heightToWidthRatio == 1.5, "7分屏宽高比应为 1:1.5")
expect(GameDisplayMode.full.heightToWidthRatio == nil, "全屏应使用安全区完整高度")
expect(
    GameDisplayMode.allCases.map(\.title) == ["Full Screen", "Half Screen", "70% Screen"],
    "不加载本地化资源时，底部 Tab 应回退英文"
)
expect(GameDisplayMode.full.tabIconFillRatio == 1.0, "全屏 Tab 图标应填满屏幕轮廓")
expect(GameDisplayMode.half.tabIconFillRatio == 0.5, "半屏 Tab 图标应填充一半屏幕轮廓")
expect(GameDisplayMode.sevenTenths.tabIconFillRatio == 0.7, "7分屏 Tab 图标应填充七成屏幕轮廓")
expect(GameDisplayMode.full.miniValue == 0, "全屏应映射为 mini=0")
expect(GameDisplayMode.half.miniValue == 1, "半屏应映射为 mini=1")
expect(GameDisplayMode.sevenTenths.miniValue == 2, "7分屏应映射为 mini=2")
expect(GameDisplayMode.full.launchPresentation == .pushed, "全屏游戏应通过导航 push 展示")
expect(GameDisplayMode.half.launchPresentation == .embedded, "半屏游戏应在当前 Tab 展示")
expect(GameDisplayMode.sevenTenths.launchPresentation == .embedded, "7分屏游戏应在当前 Tab 展示")
expect(!GameDisplayMode.full.usesGameBackground, "全屏入口不需要游戏背景")
expect(GameDisplayMode.half.usesGameBackground, "半屏入口应使用游戏背景")
expect(GameDisplayMode.sevenTenths.usesGameBackground, "7分屏入口应使用游戏背景")
expect(GameDisplayMode.full.hidesNavigationBar, "全屏游戏应隐藏导航栏")
expect(!GameDisplayMode.half.hidesNavigationBar, "半屏游戏应显示导航栏")
expect(!GameDisplayMode.sevenTenths.hidesNavigationBar, "7分屏游戏应显示导航栏")
expect(!GameDisplayMode.full.hidesModeTabBar, "全屏入口应保留模式 Tab Bar")
expect(GameDisplayMode.half.hidesModeTabBar, "进入半屏场景后应隐藏模式 Tab Bar")
expect(GameDisplayMode.sevenTenths.hidesModeTabBar, "进入7分屏场景后应隐藏模式 Tab Bar")
expect(GameDisplayMode.full.backDestination == .previousScreen, "全屏返回应保留原导航行为")
expect(GameDisplayMode.half.backDestination == .fullModeTab, "半屏返回应切换到全屏 Tab")
expect(GameDisplayMode.sevenTenths.backDestination == .fullModeTab, "7分屏返回应切换到全屏 Tab")

expect(GameEntryValidator.isValid(appKey: "app-key", token: "token"), "两个输入都有值时应通过校验")
expect(!GameEntryValidator.isValid(appKey: "", token: "token"), "AppKey 为空时不应通过校验")
expect(!GameEntryValidator.isValid(appKey: "app-key", token: ""), "Token 为空时不应通过校验")
expect(!GameEntryValidator.isValid(appKey: "   ", token: "\n"), "纯空白输入不应通过校验")

let scriptMessageNames = Set(GameScriptMessage.allCases.map(\.rawValue))
expect(
    scriptMessageNames == ["recharge", "clickRecharge", "newTppClose", "OpenGameSucc"],
    "应注册文档定义的全部 JS 回调"
)
expect(
    GameScriptMessage(rawValue: "newTppClose") == .close,
    "关闭回调应映射到关闭游戏事件"
)
expect(
    GameScriptMessage(rawValue: "unknown") == nil,
    "未知 JS 消息不应被识别"
)

let url = GameURLBuilder.makeURL(
    appKey: "app key",
    token: "token+value",
    displayMode: .sevenTenths
)
expect(url != nil, "有效参数应生成游戏链接")

if let url,
   let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
    let queryItems = Dictionary(
        uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
    )
    expect(components.scheme == "https", "游戏链接应使用 HTTPS")
    expect(components.host == "game.abv.cn", "游戏链接域名应正确")
    expect(components.path == "/frontend/00lobby00/index.html", "游戏链接路径应正确")
    expect(queryItems["appKey"] == "app key", "AppKey 应来自输入值")
    expect(queryItems["token"] == "token+value", "Token 应来自输入值")
    expect(queryItems["gameId"] == "2", "gameId 应固定为 2")
    expect(queryItems["mini"] == "2", "mini 应来自展示模式")
}

print("GameConfiguration tests passed")
