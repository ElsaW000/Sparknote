# ⚠️ DEPRECATED — Capture Metadata（已废弃）

> 更新日期：2026-05-31

Metadata 设置已内嵌到 `pages/library/editor` 全屏编辑页，不再是独立页面。

---

# Capture Metadata（原文保留） — 元数据表单

> 路由：`pages/capture/metadata` | 子页面  
> 源文件：`src/pages/capture/metadata.vue`  
> 入口：从 capture/index 通过 `navigateTo /pages/capture/metadata?ocrText=...` 进入

---

## 1. 页面目的

提供一个独立的元数据填写表单，用于在 OCR 识别完成后补充来源信息（书名、作者、页码等），填写完成后将数据回传 Capture 主页。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ Metadata                        │
│ Provide additional context...   │
├─────────────────────────────────┤
│ Source Type  [picker]           │  ← 来源类型（picker，非 chip）
│ Source Title ___________        │
│ Author ___________              │
│ Page Number ___________         │
│ Source URL ___________          │
│ Tags (comma-separated)          │
│ Personal Comment [textarea]     │
├─────────────────────────────────┤
│ （如果携带 ocrText 则显示）      │
│ OCR Text (read-only)            │
│ [textarea readonly]             │
├─────────────────────────────────┤
│ [Confirm & Return]  [Cancel]    │
└─────────────────────────────────┘
```

---

## 3. 数据流

```
navigateTo /pages/capture/metadata?ocrText=<encoded>
        ↓
onLoad(query.ocrText) → form.ocrText = decodeURIComponent(query.ocrText)
        ↓
用户填写 Source Type/Title/Author/Page/URL/Tags/Comment
        ↓
[Confirm & Return]
        ↓
uni.$emit('capture-metadata-result', { ...form })
uni.navigateBack()

[Cancel] → uni.navigateBack()（不发送事件）
```

---

## 4. 与 capture/index 元数据区的区别

| 维度 | capture/index 元数据区 | capture/metadata.vue |
|------|----------------------|----------------------|
| 位置 | 嵌入在主页底部 | 独立子页面 |
| Source Type | chip 选择器 | picker 选择器 |
| 触发时机 | 随时可填 | OCR 后跳转进入 |
| 目的 | 主流程直接填写 | OCR 后分步填写，体验更聚焦 |

---

## 5. 待解决问题

| 问题 | 说明 | 优先级 |
|------|------|--------|
| capture/index 没有明确跳转到此页的逻辑（待验证）| OCR 结果是否会自动跳转到 metadata.vue？ | 高（需确认）|
| ocrText 通过 URL query 传递 | 长文本 URL 可能超出限制 | 中 |
| 与主页元数据区功能重复 | 两套元数据入口，用户可能混淆 | 中 |
