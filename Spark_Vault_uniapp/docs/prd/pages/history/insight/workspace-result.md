# ⚠️ DEPRECATED — Workspace Result（已废弃）

> 更新日期：2026-05-31  
> 迁移去向：`pages/report/detail`（报告详情 S5）

---

# Workspace Result — 合成报告详情（原文保留）

> 路由：`pages/workspace/result?reportId={id}` | 子页面  
> 源文件：`src/pages/workspace/result.vue`  
> 入口：Archive 列表页点击报告（查看历史报告）

---

## 1. 页面目的

展示某一条已保存报告的完整内容，并提供查看引用片段的入口。注意：Workspace 合成后的**即时结果**内联在 workspace/index 页面展示，本页面主要用于查看**历史报告**。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ Workspace Result                │
│ {{ report.title }}              │
├─────────────────────────────────┤
│ （有报告时）                     │
│ ┌─────────────────────────────┐ │
│ │ {{ report.generatedContent }}│ │
│ │ [View References]           │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ （无报告时）                     │
│ Generate a workspace report... │
│ [Back to Workspace]             │
└─────────────────────────────────┘
```

---

## 3. 数据流

```
onLoad(query.reportId)
        ↓
vaultStore.getReportById(reportId)
        ↓
显示 report.title + report.generatedContent

[View References]
        ↓
navigateTo /pages/workspace/references?ids=1,2,3

[Back to Workspace]
        ↓
uni.navigateBack()（已修复：原为 uni.switchTab 误跳 tabBar）
```
