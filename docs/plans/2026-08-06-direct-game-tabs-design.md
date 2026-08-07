# 直接进入游戏模式 Tab 设计

## 目标

移除首页 AppKey 和 Token 输入界面，App 启动后直接进入现有三个游戏模式 Tab。

## 设计

- 保留 Storyboard 中现有导航控制器和 `ViewController` 入口，`ViewController` 不再创建输入控件，而是在首次加载时直接把 `GameModeTabBarController` 设为导航栈根页面，避免显示或返回到空白首页。
- AppKey 和 Token 作为固定配置放在 `GameConfiguration.swift`，首页入口把固定值传给现有 Tab 控制器；不改动 Tab 内部的展示和返回逻辑。
- 游戏地址改为 `https://joyplay.cn/release/index.html`，固定包含指定 AppKey、Token、`gameId=2`，三个模式仅通过现有映射分别使用 `mini=0`、`mini=1`、`mini=2`。
- 删除因移除输入页而不再使用的输入校验代码及其测试；保留本次无需触碰的本地化资源。

## 验证

- 聚焦测试验证固定配置、新域名、新路径、`gameId=2` 和三个 `mini` 映射。
- 静态检查确认首页不再包含 `UITextField` 或进入按钮，并直接建立 Tab 根页面。
- 运行无签名 iOS 模拟器构建，确认 UIKit 工程可编译。

