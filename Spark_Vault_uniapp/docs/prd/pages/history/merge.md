# ⚠️ DEPRECATED — Library Merge（已废弃）

> 更新日期：2026-05-31

碎片合并功能已移除，新设计中 Library 不支持合并操作。

---

# Library Merge — 碎片合并（原文保留）

> 路由：`pages/library/merge` | 子页面  
> 源文件：`src/pages/library/merge.vue`  
> 入口：Library 列表页 [Merge →] 按钮

---

## 1. 页面目的

从所有片段中勾选 2 条或以上，合并为一条新片段，可选择是否删除原始片段。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ Merge Fragments                 │
│ Select two or more fragments... │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │  ← 操作面板
│ │ Selected fragments: N       │ │
│ │ Merged Source Title _______ │ │
│ │ ☐ Delete originals after    │ │
│ │ [Confirm Merge]             │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ 片段列表（可多选）               │
│ ┌────────────────────────────┐  │
│ │ ☐  书名 / 来源              │  │
│ │    原文摘录（截断）...       │  │
│ └────────────────────────────┘  │
│ ...                             │
└─────────────────────────────────┘
```

---

## 3. 数据流

```
onShow → vaultStore.refresh() → 加载全量 fragments
        ↓
用户勾选片段（toggle(id)，selectedIds[]）
输入 Merged Source Title（title）
勾选"Delete originals"（deleteOriginals）
        ↓
[Confirm Merge]
        ↓
vaultStore.mergeSelected(selectedIds, title, deleteOriginals)
        ↓
ok → toast "Fragments merged" → navigateBack()
error → toast 错误信息
```

---

## 4. 合并规则（vaultLogic.mergeFragments）

- 所有原始片段的 `originalText` 拼接（换行分隔）
- tags 合并去重
- `sourceType` 取第一个片段的值
- `deleteOriginals` = true 时删除参与合并的片段

---

## 5. 待解决问题

| 问题 | 说明 | 优先级 |
|------|------|--------|
| 显示全量片段（不受 Library 过滤影响）| 用户在 Library 过滤后进入 merge，还是看到全部片段 | 低 |
| 选 < 2 条时无 UI 提示 | 错误通过 toast 显示，无行内高亮提示 | 低 |
| title 为空可以合并 | 合并标题可以为空，后续在 Library 无法区分 | 低 |
