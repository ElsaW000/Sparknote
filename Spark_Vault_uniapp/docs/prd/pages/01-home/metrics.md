# ⚠️ DEPRECATED — Metrics Detail（已废弃）

> 更新日期：2026-05-31

旧路由：`pages/dashboard/metrics`  
此独立 Metrics 页已废弃。数据概览统计现在内嵌在 `pages/home/index` 主页中，不再是独立子页面。

---

---

## 1. 页面目的

展示 Vault 的详细统计数据：片段总数、收藏数、来源分布、标签数量、每周洞见全文。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ Metrics Detail                  │  ← 标题
│ Vault activity, source dist...  │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │  ← 数值面板
│ │ Total Fragments: N          │ │
│ │ Favorite Fragments: N       │ │
│ │ Reports: N                  │ │
│ │ Primary Source: Book        │ │
│ │ Tag Count: N                │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Source Distribution             │  ← 来源分布面板
│ Book: N                         │
│ Browser: N                      │
│ ...                             │
├─────────────────────────────────┤
│ Weekly Insight                  │  ← 每周洞见（完整文本）
│ {{ weeklyDigest }}               │
└─────────────────────────────────┘
```

---

## 3. 数据来源

| 数据 | 来源 |
|------|------|
| `metrics` | `vaultStore.state.metrics` |
| `weeklyDigest` | `vaultStore.state.weeklyDigest` |
| `sourceRows` | `metrics.sourceCounts`（Object.entries 展开）|

刷新时机：`onShow` → `syncState()` → `vaultStore.refresh()`

---

## 4. 待解决问题

| 问题 | 说明 | 优先级 |
|------|------|--------|
| Home 页无明确入口 | Home 页代码中没有显式"查看详细指标"按钮，需确认入口 | 高（待验证）|
| 无图表可视化 | 来源分布仅文字列表，无饼图/柱状图 | 低（P2）|
