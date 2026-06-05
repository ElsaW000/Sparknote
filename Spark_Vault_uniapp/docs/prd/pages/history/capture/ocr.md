# ⚠️ DEPRECATED — Capture OCR（已废弃）

> 更新日期：2026-05-31  
> 旧路由：`pages/capture/ocr`

OCR 功能现通过 Library Tab 的 📷 快捷按钮触发，不再是独立页面。

---

---

## 1. 页面目的

让用户选择一张图片（书页截图或普通截图），通过 Tesseract.js 在本地识别图中文字，确认后将文字传回 Capture 主页。

---

## 2. 页面结构

```
┌─────────────────────────────────┐
│ OCR Presets                     │
│ Capture text from images using  │
│ Tesseract.js (offline)          │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │  ← Book 模式
│ │ Book / Document             │ │
│ │ Scan a book page...         │ │
│ │ [📖 Scan Book Page]         │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │  ← Screenshot 模式
│ │ Screenshot / Article        │ │
│ │ Extract text from screen... │ │
│ │ [🖼️ Scan Screenshot]        │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Tips for best results           │  ← 使用提示
│ • 清晰光线、避免装饰字体...      │
├─────────────────────────────────┤
│ （识别完成后显示）               │
│ Recognized Text                 │
│ [textarea readonly]             │
│ [Use This Text]  [Discard]     │
├─────────────────────────────────┤
│ （出错时显示）                   │
│ 错误提示文字                    │
└─────────────────────────────────┘
```

---

## 3. 识别流程

```
点 [Scan Book Page] 或 [Scan Screenshot]
        ↓
uni.chooseImage({ sourceType: ['album', 'camera'] })
        ↓
Tesseract.recognize(filePath, 'eng', { logger: 显示进度 })
        ↓
成功 → recognizedText = result.data.text（trim）
失败 → errorMsg = "OCR failed: ..."
        ↓
用户点 [Use This Text]
        ↓
① 直接调用 capturePage.$vm.onOcrResult(text)（最优先）
② uni.$emit('capture-ocr-result', { text })（fallback）
        ↓
uni.navigateBack()
```

---

## 4. 局限性

| 限制 | 说明 |
|------|------|
| 仅支持英文 | `Tesseract.recognize(path, 'eng')`，中文需额外语言包 |
| 本地运行 | 无需联网，但 tesseract.js 加载时间较长（首次约 2-3s）|
| 两种模式无实质区别 | Book 和 Screenshot 均选 `['album', 'camera']`，逻辑相同 |
| H5 环境限制 | `uni.chooseImage` 在 H5 可能有跨域限制，App 端表现更好 |

---

## 5. 待解决问题

| 问题 | 说明 | 优先级 |
|------|------|--------|
| 中文 OCR 不支持 | 需加载 chi_sim 语言包 | 高（国内用户场景）|
| Book / Screenshot 模式无区别 | 两个按钮逻辑完全一样，用户产生误解 | 中 |
| 无"返回并手动输入"入口 | 如果识别质量差，用户只能 Discard 后手动返回 | 低 |
