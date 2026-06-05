# Android -> uni-app 迁移检查清单

状态: Active
更新时间: 2026-05-29

## 迁移范围
- 源项目: google_ai_studio_android
- 目标项目: Spark_Vault_uniapp
- 目标: 在 uni-app 中建立可持续迭代的页面与数据基础架构。

## 页面映射（主链路）
- DashboardScreen -> pages/dashboard/index
- Dashboard metrics -> pages/dashboard/metrics
- LibraryScreen -> pages/library/index
- FragmentDetailsDialog -> pages/library/detail
- Library merge -> pages/library/merge
- CaptureScreen -> pages/capture/index
- Capture OCR -> pages/capture/ocr
- Capture metadata -> pages/capture/metadata
- WorkspaceScreen -> pages/workspace/index
- Workspace result -> pages/workspace/result
- Workspace references -> pages/workspace/references
- SettingsAndHistoryScreen -> pages/archive/index
- Report reader -> pages/archive/report-detail

## 导航设计基线
- tab 路由使用 uni.switchTab。
- 子页面使用 uni.navigateTo。
- 详情和结果页通过 query 传递 id。

## 当前状态快照
- 已完成: 页面壳已创建，基础映射已建立。
- 进行中: services/store/tests 的业务联动。
- 待完成: 后端接口打通与完整回归验证。

## 当前风险
- pages.json 与页面文件可能存在新增后未同步风险。
- tab 列表与实际业务页面存在偏差风险（需每次改动后复核）。
- 页面壳存在但尚未全量接入 store/repository。

## 数据接入待办
- Library 列表/详情 -> notes API
- Capture 保存/OCR -> notes + transcribe API
- Workspace 生成/引用 -> conversations API
- Archive 历史/详情 -> workspace history API

## 组件待办
- FragmentCard 可复用组件
- FilterChips 与来源选择组件
- ReportCard 组件
- EmptyState 组件组

## 验证清单
- [ ] pages.json 与页面文件一一对应
- [ ] tab 页面在 H5 和移动端可打开
- [ ] 子页面可从主页面正常进入
- [ ] 无死链按钮
- [ ] 关键表单空输入有 toast 提示

## 下一步动作
1. 先完成 vaultLogic + vaultRepository + vaultStore。
2. 接入 Library 与 Capture 的最小可用数据流。
3. 打通 Workspace 结果与引用链路。
4. 完成一次端到端手工回归并回写文档状态。
