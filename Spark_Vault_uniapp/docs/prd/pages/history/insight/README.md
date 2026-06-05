# ⚠️ DEPRECATED — Insight Tab（已废弃）

> 更新日期：2026-05-31

---

## 变更说明

**Insight Tab 已在 4-Tab 重构中废弃并拆分：**

| 旧页面 | 旧路由 | 迁移去向 |
|--------|--------|----------|
| Insight Tab（AI 整理）| `pages/ai/index` | → `pages/chat/index`（Chat Tab，Session 发起入口）|
| Workspace | `pages/workspace/index` | → `pages/report/generate`（生成报告 Sheet）|
| Workspace Result | `pages/workspace/result` | → `pages/report/detail`（报告详情 S5）|
| Workspace References | `pages/workspace/references` | → 报告详情内的碎片引用区块 |
| Archive | `pages/archive/index` | → `pages/report/list`（报告历史列表 S4）|

---

## 新 Chat Tab 文档

新的 Chat Tab 设计文档位于（待创建）：  
`docs/prd/pages/chat/index.md`

Chat Tab 的核心变化：
- **不是**文字整理工具
- **不是**在 Tab 页内直接对话（无输入框）
- **是** Session 发起入口（4 种模式卡片）+ 历史列表
- 实际对话在全屏 `pages/chat/session` 进行

---

---

## 本 Tab 包含的页面

| 文件 | 路由 | 类型 |
|------|------|------|
| [index.md](index.md) | `pages/ai/index` | tabBar 主页 |
| [workspace-index.md](workspace-index.md) | `pages/workspace/index` | 子页面（navigateTo）|
| [workspace-result.md](workspace-result.md) | `pages/workspace/result` | 子页面（navigateTo + reportId）|
| [workspace-references.md](workspace-references.md) | `pages/workspace/references` | 子页面（navigateTo + ids）|
| [archive-index.md](archive-index.md) | `pages/archive/index` | 子页面（navigateTo，也从 Home 入口进入）|
| [archive-report-detail.md](archive-report-detail.md) | `pages/archive/report-detail` | 子页面（navigateTo + id）|

---

## AI 功能导航图

```
AI Tab（ai/index）
    ↓ navigateTo
Workspace（workspace/index）→ 合成结果内联展示
    ├── [View References] → workspace/references → [点片段] → library/detail
    └── [Archive 历史] → Archive（从 Home 也可进入）
                            ↓
                        archive/report-detail → workspace/references
```
