# GameWebView Auto Layout 职责设计

## 目标

由 `GameWebView` 统一声明自己通过 Auto Layout 挂载，避免全屏与嵌入式 Demo 宿主重复设置 `translatesAutoresizingMaskIntoConstraints`。

## 设计

- `GameWebView.init` 在 `super.init(frame:)` 后统一设置 `translatesAutoresizingMaskIntoConstraints = false`。
- 不按展示模式分支：全屏、半屏和大半屏的外层 `GameWebView` 都由宿主约束定位。
- 删除 `GameViewController` 和 `GameModeTabBarController` 中的重复设置。
- 保持三种模式现有约束、URL、比例、事件及释放行为不变。

## 验证

- 源码测试确认设置只保留在 `GameWebView`，两个 Demo 宿主不再重复设置。
- 运行现有 Swift 测试和无签名模拟器构建。

