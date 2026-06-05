# 系统架构基线

状态: Active
更新时间: 2026-05-29

## 分层设计
- 页面层（pages）: 负责渲染与交互，不承载复杂业务规则。
- 状态层（store）: 承载页面共享状态与动作编排。
- 领域逻辑层（services/vaultLogic）: 纯函数规则，便于测试。
- 数据访问层（services/vaultRepository）: 屏蔽 uni 存储与内存回退差异。
- 后端接口层（services/api）: 统一封装 HTTP 请求与错误处理。

## 关键原则
- 薄页面，厚逻辑。
- 先本地可用，再逐步接后端。
- 错误可见（toast）且可恢复。
- 每个能力都要有最小验证路径。

## 运行时策略
- uni-app 运行时: 优先使用 uni.getStorageSync/uni.setStorageSync。
- 测试运行时: 使用内存存储实现，保证测试稳定。

## 导航策略
- tab 页跳转统一使用 uni.switchTab。
- 非 tab 子页统一使用 uni.navigateTo。
- 详情页参数通过 query string 传递 id。

## 已知风险
- pages.json 与实际页面文件存在偏差风险（例如新增页面未注册或已注册页面缺失文件）。
- 页面骨架已完成，但业务联动仍需 store/repository 支撑。
