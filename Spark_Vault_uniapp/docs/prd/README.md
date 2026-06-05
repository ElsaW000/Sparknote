# PRD 产品文档

> Spark Vault（InspireVault）uni-app 产品需求文档集合  
> 工作目录：`Spark_Vault_uniapp/`

---

## 文档索引

### 产品设计文档（来自原始 PRD 存档）

| 文件 | 内容 | 时间 |
|------|------|------|
| [01-product-brief.md](01-product-brief.md) | 产品简介、目标用户、MVP 范围 | 2026-03 |
| [02-product-prd.md](02-product-prd.md) | 完整 PRD，知识库 + Agent + 创作工作台 | 2026-04 |
| [03-new-positioning.md](03-new-positioning.md) | 新定位：从记录灵感 → 把碎片激活成新创意 | 2026-04 |
| [04-epics-and-stories.md](04-epics-and-stories.md) | 用户故事与验收标准 | 2026-03 |
| [05-ui-design.md](05-ui-design.md) | UI 设计规范（色彩、字体、交互原则）| 2026-03 |

### 页面级设计规格（按 Tab 组织）

**Tab 1 — Home**

| 文件 | 路由 |
|------|------|
| [pages/home/index.md](pages/home/index.md) | `pages/index/index` |
| [pages/home/metrics.md](pages/home/metrics.md) | `pages/dashboard/metrics` |

**Tab 2 — Library**

| 文件 | 路由 |
|------|------|
| [pages/library/index.md](pages/library/index.md) | `pages/library/index` |
| [pages/library/detail.md](pages/library/detail.md) | `pages/library/detail` |
| [pages/library/merge.md](pages/library/merge.md) | `pages/library/merge` |

**Tab 3 — Capture**

| 文件 | 路由 |
|------|------|
| [pages/capture/index.md](pages/capture/index.md) | `pages/capture/index` |
| [pages/capture/ocr.md](pages/capture/ocr.md) | `pages/capture/ocr` |
| [pages/capture/metadata.md](pages/capture/metadata.md) | `pages/capture/metadata` |

**Tab 4 — Insight**

| 文件 | 路由 |
|------|------|
| [pages/insight/index.md](pages/insight/index.md) | `pages/ai/index` |
| [pages/insight/workspace-index.md](pages/insight/workspace-index.md) | `pages/workspace/index` |
| [pages/insight/workspace-result.md](pages/insight/workspace-result.md) | `pages/workspace/result` |
| [pages/insight/workspace-references.md](pages/insight/workspace-references.md) | `pages/workspace/references` |
| [pages/insight/archive-index.md](pages/insight/archive-index.md) | `pages/archive/index` |
| [pages/insight/archive-report-detail.md](pages/insight/archive-report-detail.md) | `pages/archive/report-detail` |

---

## 说明

- 所有页面均对应 `src/pages/` 下的 Vue 文件
- 导航策略：tabBar 页间用 `switchTab`，子页面用 `navigateTo`
- 数据层：所有页面通过 `vaultStore`（单例）共享状态
