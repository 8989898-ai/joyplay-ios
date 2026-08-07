# 游戏入口链接设计

## 目标

使用首页输入的 AppKey、Token 和所选展示模式生成实际游戏链接，替换当前百度占位链接，并在加载前将实际链接打印到控制台。

## 方案

- 使用 `URLComponents` 生成 `https://game.abv.cn/frontend/00lobby00/index.html` 链接，避免输入值中的特殊字符破坏查询参数。
- 查询参数固定包含 `appKey`、`token`、`gameId=1` 和 `mini`。
- 展示模式映射为：全屏 `mini=0`、半屏 `mini=1`、大半屏 `mini=2`。
- 将该模式文案统一为“大半屏”；具体尺寸按 WebView 宽高比设计处理。
- `GameViewController` 在 `WKWebView` 加载前打印并加载同一个 URL。
- 不在源码中保存示例 Token。

## 验证

- 单元测试验证三种模式标题、高度和 `mini` 映射。
- 单元测试通过解析查询项验证输入值、固定 `gameId` 和所选 `mini`。
- 运行无签名 iOS 模拟器构建，确认项目能够编译。
- 运行时仍需在模拟器或设备上确认控制台输出与 WebView 实际请求一致。
