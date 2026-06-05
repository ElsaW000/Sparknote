# ⚠️ DEPRECATED — Library Detail（已废弃）

> 更新日期：2026-05-31  
> 迁移去向：`pages/library/editor`（S2 全屏编辑）

---

# Library Detail — 碎片详情编辑（原文保留）

> 路由：`pages/library/detail?id={id}` | 子页面  
> 源文件：`src/pages/library/detail.vue`  
> 入口：Library 列表页点任意片段卡片

---

## 1. 页面目的

查看单条片段的完整内容，并支持编辑所有字段（含 AI 摘要、收藏状态），或删除该片段。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ Fragment Detail                 │
│ View and edit a captured fragment│
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ [textarea] 原文              │ │
│ │ Source Type ___________     │ │
│ │ Source Title ___________    │ │
│ │ Author _____ Page # ___     │ │
│ │ Source URL ______________   │ │
│ │ Tags ___________________    │ │
│ │ Personal Comment [textarea] │ │
│ │ AI Summary   [textarea]     │ │
│ │ ☐ Favorite                  │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ [Save Changes]                  │
│ [Delete Fragment]               │
└─────────────────────────────────┘
```

---

## 3. 数据流

```
onLoad(query.id)
    ↓
vaultStore.getFragmentById(id)
    ↓
填充 form（所有字段）
    ↓
用户编辑后点 [Save Changes]
    ↓
vaultStore.updateFragment(id, form)  → navigateBack()

点 [Delete Fragment]
    ↓
vaultStore.deleteFragment(id)  → navigateBack()
```

---

## 4. 字段列表

| 字段 | 类型 | 说明 |
|------|------|------|
| `originalText` | textarea | 原文（必填）|
| `sourceType` | input | 来源类型 |
| `sourceTitle` | input | 来源标题 |
| `author` | input | 作者 |
| `pageNumber` | input | 页码 |
| `sourceUrl` | input | 来源 URL |
| `tagsText` | input | 逗号分隔的标签 |
| `userComment` | textarea | 个人备注 |
| `aiSummary` | textarea | AI 摘要（可手动编辑）|
| `favoriteStatus` | checkbox | 收藏状态 |

---

## 5. 待解决问题

| 问题 | 说明 | 优先级 |
|------|------|--------|
| id 不存在时只显示"not found" | 无返回按钮引导，用户可能卡住 | 低 |
| Delete 无二次确认 | 直接删除 | 中 |
| sourceType 是 input 不是 picker | 用户可输入任意值，可能与过滤不兼容 | 中 |
