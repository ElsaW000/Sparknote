# 路由对账报告

> 对账时间：2026-05-29（修订版）  
> **实际工作目录：`src/`**（uni-app Vite 模板，编译入口为 `src/main.js`）  
> 对账基准：`src/pages.json`（13 条注册路由）  
> 实际目录：`src/pages/`（7 个子目录，15 个 .vue 文件）

> ⚠️ 注意：根目录下的 `pages/` 和 `pages.json` 是**孤立存档文件**，
> 不参与编译（`main.js` 不存在于根目录）。后续所有开发针对 `src/`。

---

## 一、路由 × 文件对账清单（`src/` 基准）

| # | src/pages.json 注册路径 | 对应文件 | 状态 |
|---|---|---|---|
| 1 | `pages/index/index`（tabBar Home） | `src/pages/index/index.vue` | ✅ 匹配 |
| 2 | `pages/library/index`（tabBar Library） | `src/pages/library/index.vue` | ✅ 匹配 |
| 3 | `pages/capture/index`（tabBar Capture） | `src/pages/capture/index.vue` | ✅ 匹配 |
| 4 | `pages/ai/index`（tabBar Insight） | `src/pages/ai/index.vue` | ✅ 匹配 |
| 5 | `pages/archive/index` | `src/pages/archive/index.vue` | ✅ 匹配 |
| 6 | `pages/dashboard/metrics` | `src/pages/dashboard/metrics.vue` | ✅ 匹配 |
| 7 | `pages/library/detail` | `src/pages/library/detail.vue` | ✅ 匹配 |
| 8 | `pages/library/merge` | `src/pages/library/merge.vue` | ✅ 匹配 |
| 9 | `pages/capture/ocr` | `src/pages/capture/ocr.vue` | ✅ 匹配 |
| 10 | `pages/capture/metadata` | `src/pages/capture/metadata.vue` | ✅ 匹配 |
| 11 | `pages/workspace/result` | `src/pages/workspace/result.vue` | ✅ 匹配 |
| 12 | `pages/workspace/references` | `src/pages/workspace/references.vue` | ✅ 匹配 |
| 13 | `pages/archive/report-detail` | `src/pages/archive/report-detail.vue` | ✅ 匹配 |

**结论：13/13 路由完全匹配，无缺失文件。**

### 文件存在但未注册的页面

| 文件路径 | 建议操作 |
|---|---|
| `src/pages/workspace/index.vue` | ⚠️ 注册到 `src/pages.json` 并加入 tabBar |
| `src/pages/dashboard/index.vue` | ⚠️ 注册为普通页（或作为 metrics 的父页） |

---

## 二、tabBar 偏差分析

### 当前配置（4 个 Tab，在 `src/pages.json`）

| Tab | 路径 | 现状 |
|---|---|---|
| Home | `pages/index/index` | ✅ 文件存在 |
| Library | `pages/library/index` | ✅ 文件存在 |
| Capture | `pages/capture/index` | ✅ 文件存在 |
| Insight | `pages/ai/index` | ⚠️ 与 PRD 目标不符 |

### PRD 目标（5 个 Tab）

| Tab | 路径 | 现状 |
|---|---|---|
| Dashboard | `pages/index/index` 或 `pages/dashboard/index` | `dashboard/index.vue` 存在但未注册 |
| Library | `pages/library/index` | ✅ 已在 tabBar |
| Capture | `pages/capture/index` | ✅ 已在 tabBar |
| Workspace | `pages/workspace/index` | ⚠️ 文件存在，**未注册路由，未在 tabBar** |
| Archive | `pages/archive/index` | ✅ 已注册，**未在 tabBar** |

### 需要处理的偏差

| 偏差项 | 风险等级 | 建议操作 |
|---|---|---|
| `workspace/index` 未注册路由 | 高 | 加入 `src/pages.json` pages 列表 |
| `workspace/index` 未在 tabBar | 高 | 加入 tabBar（替换 AI tab 或追加） |
| `archive/index` 未在 tabBar | 高 | 加入 tabBar |
| `pages/ai/index` 在 tabBar 但 PRD 无此 tab | 中 | 决策：保留或合并进 Workspace |
| `dashboard/index.vue` 存在但未注册 | 低 | 注册为普通页或合并进 `index/index` |

---

## 三、服务层状态确认

| 文件 | 状态 |
|---|---|
| `src/services/vaultLogic.js` | ✅ 实现完整，测试全通过 |
| `src/services/vaultRepository.js` | ✅ 实现完整，测试全通过 |
| `src/services/aiService.js` | ✅ 已实现（DashScope 兼容接口） |
| `src/store/vaultStore.js` | ✅ 实现完整，测试全通过 |

运行验证：`npm run verify`（`test:logic` + `check:js` 均通过）

---

## 四、子页面导航方式确认

以下页面**不是** tabBar 页面，跳转必须用 `uni.navigateTo`（不能用 `uni.switchTab`）：

- `pages/dashboard/metrics`
- `pages/library/detail`
- `pages/library/merge`
- `pages/capture/ocr`
- `pages/capture/metadata`
- `pages/workspace/result`
- `pages/workspace/references`
- `pages/archive/report-detail`

> ⚠️ 常见错误：对非 tabBar 页面误用 `uni.switchTab` 会静默失败，不跳转。

---

## 五、行动项

1. **[✅ 已决策 2026-05-31]** tabBar 保持 4 个：Home / Library / Capture / AI。Workspace 和 Archive 作为子页面。
2. **[✅ 已完成]** 在 `src/pages.json` 注册 `pages/workspace/index`（普通路由，非 tabBar）。
3. **[任务 3]** Workspace 入口放在 AI tab 页中（按钮跳转，用 `navigateTo`）。
4. **[任务 3]** Archive 入口放在 Home tab 页中（按钮跳转，用 `navigateTo`）。
5. **[持续]** tabBar 页（Home/Library/Capture/AI）之间跳转用 `switchTab`；子页面用 `navigateTo`。
6. **[可选清理]** 根目录下孤立的 `pages/` 和 `pages.json` 可在 sprint 结束后删除。
