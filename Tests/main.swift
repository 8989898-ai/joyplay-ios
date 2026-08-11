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

let backendURL = URL(
    string: "https://joyplay.cn/release/index.html?token=a%2Bb%2Fc&mini=0#game"
)!
expect(
    GameURLRuntimeAdapter.isValidBackendGameURL(backendURL),
    "核心应接受不含 paddingBottom 的完整 HTTPS 游戏链接"
)
expect(
    !GameURLRuntimeAdapter.isValidBackendGameURL(
        URL(string: "http://joyplay.cn/release/index.html?mini=0")!
    ),
    "核心应拒绝非 HTTPS 游戏链接"
)
expect(
    !GameURLRuntimeAdapter.isValidBackendGameURL(
        URL(string: "https://joyplay.cn/release/index.html?paddingBottom=20")!
    ),
    "核心应拒绝后端预先携带 paddingBottom 的链接"
)
expect(
    !GameURLRuntimeAdapter.isValidBackendGameURL(
        URL(string: "https:/release/index.html?mini=0")!
    ),
    "核心应拒绝没有主机名的 HTTPS 链接"
)
let fullScreenURL = GameURLRuntimeAdapter.appendingPaddingBottom(34, to: backendURL)
expect(
    fullScreenURL?.absoluteString
        == "https://joyplay.cn/release/index.html?token=a%2Bb%2Fc&mini=0&paddingBottom=34.0#game",
    "全屏应保留后端完整链接并只追加 paddingBottom"
)
expect(
    GameURLRuntimeAdapter.appendingPaddingBottom(0, to: backendURL) != nil,
    "没有底部安全距离时也应追加 paddingBottom=0"
)
expect(
    GameURLRuntimeAdapter.appendingPaddingBottom(-1, to: backendURL) == nil,
    "负 paddingBottom 应被拒绝"
)
expect(
    GameURLRuntimeAdapter.appendingPaddingBottom(.infinity, to: backendURL) == nil,
    "无限 paddingBottom 应被拒绝"
)
expect(
    GameURLRuntimeAdapter.appendingPaddingBottom(
        34,
        to: URL(string: "https://joyplay.cn/release/index.html?paddingBottom=20")!
    ) == nil,
    "后端链接不应预先携带 paddingBottom"
)

print("GameConfiguration tests passed")
