# 执行看板

> 关联路线图：[roadmap.md](roadmap.md)  
> 原始文件：[docs/execution_board.md](../execution_board.md)  
> 更新方式：每次 session 完成任务后手动移动卡片

---

## 📋 Todo

### 任务 4（续）：验证

- [x] **T4-1** 运行 `npm run verify`（logic 测试 + JS 语法检查），全绿 ✅
- [x] **T4-2** H5 模式启动：`npm run dev:h5`，http://localhost:5174/ ✅
- [ ] **T4-3** 逐页检查：无缺失导入、无空处理器、tabBar 路由使用 `switchTab`

### 任务 5（P1 M4）：AI 接入

- [ ] **T5-1** Capture 页：`AI Auto-Assist` 接入真实 DashScope（替换 fallbackTags/fallbackSummary）
- [ ] **T5-2** AI Tab：验证 `aiService.organize()` 调用链路（输入 → DashScope → 保存）
- [ ] **T5-3** Workspace：`generateWorkspaceReport` 接入真实 AI（替换本地 heuristics）
- [ ] **T5-4** Capture：语音录制 → STT（语音转文字）

### 任务 6（P1 M5）：稳定性与体验

- [ ] **T6-1** 修复 Capture 页"Source Type Type"文案 typo
- [ ] **T6-2** Archive "Nuke Vault" 加二次确认弹窗
- [ ] **T6-3** 保存后跳转策略：Capture 保存后是否跳 Library？（待产品决策）
- [ ] **T6-4** Library/merge 页考虑过滤联动
- [ ] **T6-5** AI Tab 保存统一走 vaultStore.saveFragment（替换 createVaultRepository 直调）

---

## 🔄 In Progress

_当前无进行中任务_

---

## ✅ Done

### 环境与基础设施

- [x] **E1** DashScope API key 写入 `.env`（后端 + 安卓端）
- [x] **E2** 安卓端全链路切换：Gemini → DashScope 兼容模式
- [x] **E3** 安卓端 UI 文案全量替换（Gemini → DashScope/Qwen）
- [x] **E4** 安卓端文件重命名（GeminiXxx → DashScopeXxx）
- [x] **E5** uni-app `src/pages.json` 13 条路由，`src/pages/` 文件全部存在
- [x] **E6** MVP 实施计划翻译为中文

### 任务 1：纯 Vault 逻辑 ✅

- [x] **T1-1** `src/services/vaultLogic.js` 实现完整（createFragment、parseTags、fallbackTags、filterFragments、mergeFragments、generateLocalWorkspaceReport、generateWeeklyDigest）
- [x] **T1-2** `tests/test_vault_logic.mjs` 测试全通过（`npm run test:logic`）

### 任务 2：仓储与状态 ✅

- [x] **T2-1** `src/services/vaultRepository.js` 实现完整（save/update/delete/getById，uni 存储优先 + 内存回退）
- [x] **T2-2** `src/store/vaultStore.js` 实现完整（saveFragment、generateWorkspaceReport、空输入返回 error 对象）
- [x] **T2-3** `src/services/aiService.js` 实现（DashScope 兼容接口）
- [x] **T2-4** 仓储 + store 集成测试全通过
- [x] **T2-5** `npm run verify` 全绿（logic 测试 + JS 语法检查）

### 任务 3：页面集成 ✅

- [x] **T3-0** [✅ 决策] 保留 4 个 tab：Home / Library / Capture / AI；Workspace、Archive 为子页面
- [x] **T3-1** 在 `src/pages.json` 注册 `pages/workspace/index`（普通路由，非 tabBar）
- [x] **T3-2** AI tab 页加入"进入 Workspace"入口卡片（`navigateTo`）
- [x] **T3-3** Home tab 页加入 Workspace + Archive 按钮（`navigateTo`）
- [x] **T3-4** `src/pages/index/index.vue`（Home）— `onShow→syncState()` 刷新 metrics/weeklyDigest ✅
- [x] **T3-5** `src/pages/library/index.vue` — 过滤/收藏完整联通 vaultStore ✅
- [x] **T3-6** `src/pages/library/detail.vue` — `onLoad` 用 `vaultStore.getFragmentById(id)` ✅
- [x] **T3-7** `src/pages/library/merge.vue` — `vaultStore.mergeSelected()` + navigateBack ✅
- [x] **T3-8** `src/pages/capture/index.vue` — `vaultStore.saveFragment()`，`:disabled` 防空提交 ✅
- [x] **T3-9** `src/pages/workspace/index.vue` — `vaultStore.generateWorkspaceReport()` ✅
- [x] **T3-10** `src/pages/workspace/result.vue` — 修复：`backToWorkspace` 改为 `navigateBack()` ✅
- [x] **T3-11** `src/pages/workspace/references.vue` — query ids → `vaultStore.getFragmentById` ✅
- [x] **T3-12** `src/pages/archive/index.vue` — `onShow` 刷新 reports + metrics，`deleteReport` ✅
- [x] **T3-13** `src/pages/archive/report-detail.vue` — `vaultStore.getReportById(id)` + `deleteReport` ✅

### 文档体系

- [x] **D1** `docs/README.md` — 文档入口与阅读顺序
- [x] **D2-D10** `docs/fundamentals/`、`docs/decisions/`、`docs/route_audit.md` 等
- [x] **D11** `docs/prd/` — 产品设计文档（5 个产品文档 + 6 个页面规格）
- [x] **D12** `docs/plans/` — 计划文档（roadmap + execution-board + todo-history）
