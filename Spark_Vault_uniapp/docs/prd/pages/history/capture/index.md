# ⚠️ DEPRECATED — Capture 录入主页（已废弃）

> 更新日期：2026-05-31  
> 旧路由：`pages/capture/index`（tabBar Tab 3）

此页面已废弃。所有录入功能已迁移至 `pages/library/index`（Library Tab）。

---

---

## 1. 页面目的

提供三种灵感片段录入方式：手动输入、OCR 扫描、语音录制。支持 AI 辅助生成标签和摘要后保存到 Vault。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ Capture Inspiration             │
├─────────────────────────────────┤
│ ▣ OCR Prototype Presets         │  ← OCR 入口卡片（→ ocr.vue）
│ [Book Page OCR] [Screenshot OCR]│
├─────────────────────────────────┤
│ 🎙 口述记录                      │  ← 语音录制卡片
│ [🎤 按住说话]                    │
├─────────────────────────────────┤
│ Fragment Quote/Text:            │  ← 主文本输入框
│ [textarea]                      │
├─────────────────────────────────┤
│ AI Auto-Assist: [Generate ✦]   │
│ aiSummary 展示区                 │
├─────────────────────────────────┤
│ Metadata Settings               │
│ Source Type chips               │  ← 来源类型
│ Source Title / Author / Page    │
│ Source URL                      │
│ Personal Comment                │
│ Semantic Tags (comma-sep)       │
├─────────────────────────────────┤
│ [Save into Vault Study]         │  ← :disabled="!form.originalText"
└─────────────────────────────────┘
```

---

## 3. 三种录入路径

| 路径 | 触发 | 流程 |
|------|------|------|
| 手动输入 | 直接在 textarea 输入/粘贴 | 填表 → Generate（可选）→ Save |
| OCR | 点"Book Page OCR"或"Screenshot OCR" | navigateTo `capture/ocr` → Tesseract 识别 → 文字回传 → 自动填入 originalText |
| 语音 | 按住"按住说话" | `uni.getRecorderManager()` → 录制完成后**文件路径**填入 originalText（无 STT）|

---

## 4. AI Auto-Assist

| 功能 | 实现 | 备注 |
|------|------|------|
| 标签生成 | `fallbackTags(text)` 本地关键词提取 | P1 M4 接入真实 AI |
| 摘要生成 | `fallbackSummary(text)` 本地截断 | P1 M4 接入真实 AI |

---

## 5. 数据流

```
form.originalText（必填）+ 其他元数据 + aiSummary
        ↓
vaultStore.saveFragment({ ...form, aiSummary })
        ↓
toast "Saved" → resetForm()（留在当前页，不跳转）
```

---

## 6. OCR / Metadata 子页面回传机制

- OCR 结果：`uni.$emit('capture-ocr-result', { text })` + 直接调用 `capturePage.$vm.onOcrResult()`
- Metadata 结果：`uni.$emit('capture-metadata-result', { ...form })`
- capture/index 监听这两个事件，接收后填入 form

---

## 7. 待解决问题

| 问题 | 说明 | 优先级 |
|------|------|--------|
| "Source Type Type" 文案 typo | 标签多了一个"Type" | 低 |
| 语音无 STT | 录制后只填文件路径 | 中（P1）|
| 保存后留在页面 | 仅 toast + resetForm，无跳转 Library | 待产品决策 |
| OCR/语音卡片置顶 | 主输入框需滚动才能看到 | 中 |
