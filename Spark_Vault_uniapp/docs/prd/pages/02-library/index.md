# Library Tab — 碎片收集与浏览

> 路由：`pages/library/index` | tabBar Tab 2  
> 源文件：`src/pages/library/index.vue`  
> 线框图：`/tab-design.html` Row 1 · Tab 2（Library）

---

## 1. 页面目的

碎片收集的主入口，同时展示最近碎片列表。Capture Tab 已废弃，录入功能内嵌本页顶部。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ Library              [⌕]  [≡]  │  ← ⌕搜索, ≡ → S3 全量浏览
│ 我的知识碎片                     │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │  ← ＋ 添加碎片卡片
│ │ ＋ 添加碎片                 │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │ 随手记录一个想法…      ⤢│ │ │  ← textarea，⤢ → S2
│ │ └─────────────────────────┘ │ │
│ │ 点击 ⤢ 全屏编辑（图片/录音/链接）│ │
│ │ [💡 想法] [📖 书摘] [🌐 网页] [其他]│ │  ← 来源类型 chip（录入前选）
│ │ ┌──────┐ ┌──────┐ ┌──────┐  │ │  ← 录入方式按钮
│ │ │ 📷   │ │ 🎙   │ │ 🌐   │  │ │
│ │ │ 拍照 │ │ 录音 │ │ 网页 │  │ │
│ │ │OCR识别│ │存原件│ │粘链接│  │ │
│ │ └──────┘ └──────┘ └──────┘  │ │
│ │ [保存到 Library]             │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ [全部47] [💡想法] [📖书摘] [🌐网页] [🎙录音] │  ← 碎片列表筛选（横向滚动）
├─────────────────────────────────┤
│ 全部碎片 · 47                   │
│ ┌────────────────────────────┐  │
│ │ 💡 想法  #认知  刚刚       │  │
│ │ "努力不一定有回报…"         │  │
│ └────────────────────────────┘  │
│ ┌────────────────────────────┐  │
│ │ 🎙 录音  #日常  3天前      │  │
│ │ ▶ ━━━━━━━━  00:42          │  │
│ │ 📝 转录文字 [点击生成]      │  │
│ └────────────────────────────┘  │
└─────────────────────────────────┘
```

---

## 3. 关键交互

| 触发 | 行为 |
|------|------|
| 点击 ⌕（搜索）| navigateTo `pages/library/browser`（S3，搜索模式）|
| 点击 ≡（右上角）| navigateTo `pages/library/browser`（S3 全量浏览）|
| 点击 ⤢（textarea 右下角）| navigateTo `pages/library/editor`（S2 全屏编辑）|
| 点击 📷 | 打开相机/图片选择 → OCR 识别 → 进入 editor |
| 点击 🎙 | 启动录音 → 保存原始音频文件 |
| 点击 🌐 | 展开网页链接输入框 → 粘贴 URL → 自动抓取 |
| 点击碎片卡片 | navigateTo `pages/library/editor?id=xxx`（编辑模式）|
| 点击录音碎片"转录文字" | 按需调用 STT → 文字内联显示 |

---

## 4. 碎片类型（content_type 字段）

| 值 | 显示名 | 典型来源 | AI 行为 |
|----|--------|----------|---------|
| `personal_content` | 我的内容 | 💡 想法 / ✍ 日记 / 🎙 录音 | AI 分析（记忆纠偏）|
| `reference_content` | 参考资料 | 📖 书摘 / 🌐 网页 / 📎 文件 | AI 引用（知识库）|

---

## 5. 语音录音规范

- 录制完成后**立即保存原始音频（.m4a）**，不自动转写
- 碎片卡片中显示 ▶ 播放条 + 时长
- STT（语音转文字）按需触发：用户主动点击"转写"时才调用
- 录音完成后弹出类型选择（personal_content / reference_content）

---

*更新：2026-05-31 | 前版旧 Library（搜索/收藏/来源过滤）已重构，参见 Epic LIB-*

---

## 1. 页面目的

展示 Vault 中的所有片段，支持关键词搜索、来源过滤、标签过滤、收藏筛选，提供进入详情、合并的入口。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ Library                         │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │  ← 过滤卡片
│ │ [⌕ Search keyword...]     × │ │
│ │ [All][Book][Browser][Ebook] │ │  ← Source Type chips
│ │ [All Tags][#AI][#写作]      │ │  ← Tag chips
│ │ ☐ Starred only  [Merge →]  │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ 片段卡片列表（filteredFragments）│
│ ┌────────────────────────────┐  │
│ │ [BOOK]            ♡  ⌫    │  │
│ │ "原文摘录..."               │  │
│ │ 书名 • 作者 • Page 28       │  │
│ │ AI Summary: 摘要            │  │
│ │ #标签1  #标签2  +2          │  │
│ └────────────────────────────┘  │
├─────────────────────────────────┤
│ （空态）Vault Empty              │
│ [New Capture]                   │
└─────────────────────────────────┘
```

---

## 3. 数据来源

| 数据 | 来源 |
|------|------|
| `fragments` | `vaultStore.state.filteredFragments` |
| `allTags` | `vaultStore.state.metrics.allTags` |
| `filters` | `vaultStore.state.filters` |

刷新：`onShow` → `syncState()` → `vaultStore.refresh()`  
过滤：`vaultStore.updateFilters({ query, sourceType, selectedTag, onlyFavorites })`

---

## 4. 交互行为

| 操作 | 方法 | 说明 |
|------|------|------|
| 搜索输入 | `applyFilters()` | `@input` 实时触发 |
| Source chip | `selectSource(source)` | 单选，默认"All" |
| Tag chip | `selectTag(tag)` | 单选，默认"All" |
| Starred only | `toggleFavorites()` | checkbox |
| 点卡片 | `navigateTo /pages/library/detail?id=` | 进入详情 |
| ♡/♥ | `vaultStore.toggleFavorite(id)` | 收藏切换 |
| ⌫ | `vaultStore.deleteFragment(id)` | 删除（无二次确认）|
| Merge | `navigateTo /pages/library/merge` | 进入合并页 |
| 空态 New Capture | `switchTab /pages/capture/index` | |

---

## 5. 待解决问题

| 问题 | 说明 | 优先级 |
|------|------|--------|
| 删除无二次确认 | 直接删除无法撤销 | 中 |
| 无分页/虚拟列表 | 大量数据会影响性能 | 中（P1）|
