# ⚠️ DEPRECATED — Archive Report Detail（已废弃）

> 更新日期：2026-05-31  
> 迁移去向：`pages/report/detail`（报告详情 S5）

---

# Archive Report Detail — 报告详情（原文保留）

> 路由：`pages/archive/report-detail?id={id}` | 子页面  
> 源文件：`src/pages/archive/report-detail.vue`  
> 入口：archive/index 点击报告卡片

---

## 1. 页面目的

展示单条历史报告的完整内容（标题、prompt、生成内容），提供查看引用片段和删除报告的操作。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ Report Detail                   │
│ {{ report.title }}              │
├─────────────────────────────────┤
│ Prompt: "{{ report.userPrompt }}"│
│ ─────────────────────────────── │
│ {{ report.generatedContent }}   │
├─────────────────────────────────┤
│ [Open References]               │
│ [Delete Report]                 │
└─────────────────────────────────┘
```

---

## 3. 数据流

```
onLoad(query.id)
        ↓
vaultStore.getReportById(id)
        ↓
显示 title / userPrompt / generatedContent

[Open References]
        ↓
navigateTo /pages/workspace/references?ids={report.relatedFragmentIds.join(',')}

[Delete Report]
        ↓
vaultStore.deleteReport(id) → navigateBack()
```
