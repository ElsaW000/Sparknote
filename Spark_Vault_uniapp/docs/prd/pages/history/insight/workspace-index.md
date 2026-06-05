# ⚠️ DEPRECATED — Workspace AI 工作台（已废弃）

> 更新日期：2026-05-31  
> 迁移去向：`pages/report/generate`（生成新报告 S4b）

---

# Workspace — AI 合成工作台（原文保留）

> 路由：`pages/workspace/index` | 子页面  
> 源文件：`src/pages/workspace/index.vue`  
> 入口：AI Tab Workspace 卡片、Home 页（如有配置）

---

## 1. 页面目的

用户输入创作方向（prompt），选择报告类型，AI 基于 Library 中的所有片段合成结构化报告，结果内联展示并自动保存到 Archive。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ AI Thinking Workspace           │
├─────────────────────────────────┤
│ What would you like to          │
│ synthesize?                     │
│ [textarea prompt]               │
│ [Outline][Research][Journal]    │  ← 报告类型 chips
│ [TopicMap][Ideas][Essay]        │
│ [✦ Synthesize Studio Draft]    │
├─────────────────────────────────┤
│ （有结果时）                     │
│ Synthesized Draft  [Clear Draft]│
│ 合成内容卡片                    │
│ [View Vault References]         │
│ Related Vault Fragments 列表    │
└─────────────────────────────────┘
```

---

## 3. 合成逻辑

```
vaultStore.generateWorkspaceReport({ prompt, reportType })
        ↓
generateLocalWorkspaceReport(prompt, fragments, reportType)
（关键词匹配片段 → 生成结构化报告，本地算法）
        ↓
repository.saveReport(...)
state.workspaceResult = report
state.workspaceReferences = 相关片段
```

> ⚠️ 当前为本地算法（非真实 AI），P1 M4 接入 DashScope 后替换。

---

## 4. 报告类型

| key | 标签 |
|-----|------|
| `Outline` | Writing Outline（默认）|
| `Research` | Research Report |
| `Journal` | Reflection Journal |
| `TopicMap` | Topic Map |
| `Ideas` | Content Ideas |
| `Essay` | Essay Draft |

---

## 5. 待解决问题

| 问题 | 说明 | 优先级 |
|------|------|--------|
| 本地算法质量有限 | 关键词匹配，非语义理解 | 中（P1 M4）|
| clearDraft 直接突变 state | `vaultStore.state.workspaceResult = null` | 低 |
