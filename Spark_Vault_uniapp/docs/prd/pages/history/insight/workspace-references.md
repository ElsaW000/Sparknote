# ⚠️ DEPRECATED — Workspace References（已废弃）

> 更新日期：2026-05-31  
> 迁移去向：`pages/report/detail` 内的碎片引用区块

---

# Workspace References — 引用溯源（原文保留）

> 路由：`pages/workspace/references?ids=1,2,3` | 子页面  
> 源文件：`src/pages/workspace/references.vue`  
> 入口：workspace/index [View Vault References]、workspace/result [View References]、archive/report-detail [Open References]

---

## 1. 页面目的

展示某份报告引用的所有原始片段，支持点击进入 Library 详情查看完整内容。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ Workspace References            │
│ Fragments cited by the latest..│
├─────────────────────────────────┤
│ 引用片段卡片列表                 │
│ ┌────────────────────────────┐  │
│ │ [BOOK] 书名                 │  │
│ │ 原文摘录...                 │  │
│ └────────────────────────────┘  │
│ ...                             │
├─────────────────────────────────┤
│ （无引用时）                     │
│ No references were linked...   │
└─────────────────────────────────┘
```

---

## 3. 数据流

```
onLoad(query.ids)  → "1,2,3" → split → [1, 2, 3]
        ↓
ids.map(id => vaultStore.getFragmentById(id)).filter(Boolean)
        ↓
展示 references[]

点片段卡片
        ↓
navigateTo /pages/library/detail?id={id}
```
