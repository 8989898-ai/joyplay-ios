# Native Demo URL 参数设计

## 目标

当前 JoyPlay Demo 打开的三种游戏链接增加 `isNativeDemo=1`，但业务工程复制 `JoyPlayIntegration` 后默认生成的链接不携带该参数。

## 已确认方案

- `GameURLBuilder` 和 `GameWebView` 增加默认值为 `false` 的 `isNativeDemo` 参数。
- 仅当 `isNativeDemo` 为 `true` 时，URL 查询参数中追加 `isNativeDemo=1`。
- Demo 的全屏和嵌入式创建路径显式传入 `isNativeDemo: true`。
- 保持 AppKey、Token、`gameId=1`、`mini=0/1/2` 以及所有页面和回调行为不变。

## 验证

- 配置测试验证默认链接不包含 `isNativeDemo`。
- 配置测试验证显式启用时三种模式都包含 `isNativeDemo=1`。
- 无签名模拟器构建验证两个 Demo 创建路径与核心接口匹配。
- 真实 H5 请求仍需在模拟器或真机运行 Demo 后人工确认。
