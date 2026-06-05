# ⚠️ DEPRECATED — Archive 报告历史列表（已废弃）

> 更新日期：2026-05-31  
> 迁移去向：`pages/report/index`（成长报告列表 S4）

---

# Archive — 报告历史列表（原文保留）

> 路由：`pages/archive/index` | 子页面  
> 源文件：`src/pages/archive/index.vue`  
> 入口：Home 页（navigateTo）

---

## 1. 页面目的

展示所有 Workspace 合成的历史报告，提供查看详情、删除报告，以及数据库诊断（种子数据重载、清空 Vault）的功能。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ AI Research Archives            │
├─────────────────────────────────┤
│ 报告卡片列表                     │
│ ┌────────────────────────────┐  │
│ │ 报告标题              ×    │  │
│ │ Prompt: "..."              │  │
│ │ 2026-05-31                 │  │
│ └────────────────────────────┘  │
├─────────────────────────────────┤
│ （空态）No previous research... │
├─────────────────────────────────┤
│ Thinking Studio Settings        │  ← AI 状态卡片
│ ● Local Heuristics Fallback     │
├─────────────────────────────────┤
│ Database Diagnostics & Seeds    │  ← 诊断面板
│ [Fragments: N]  [Reports: N]    │
│ [⇩ Re-load Seeds] [! Nuke Vault]│
└─────────────────────────────────┘
```

---

## 3. 数据来源 & 交互

| 操作 | 方法 | 说明 |
|------|------|------|
| 刷新 | `onShow → vaultStore.refresh()` | |
| 点报告卡片 | `navigateTo /pages/archive/report-detail?id=` | |
| 点 × 删除 | `vaultStore.deleteReport(id)` | |
| Re-load Seeds | `vaultStore.loadCuratedSeeds()` | 重载示例片段 |
| Nuke Vault | `vaultStore.clearAll()` | ⚠️ 需要二次确认（待验证）|

---

## 4. 待解决问题

| 问题 | 说明 | 优先级 |
|------|------|--------|
| Nuke Vault 是否有二次确认 | 清空所有数据，需验证代码 | 高 |
| AI 状态卡固定显示"本地模式" | 接入真实 AI 后应动态展示 | 中（P1）|
