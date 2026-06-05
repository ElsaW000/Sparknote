# ⚠️ DEPRECATED — Capture Tab（已废弃）

> 更新日期：2026-05-31

Capture Tab 已废弃。录入功能全部内嵌到 **Library Tab**（`pages/library/index`）：
- 文字输入 → Library 顶部 textarea + ⤢ 全屏编辑
- OCR 扫描 → Library 快捷按钮 📷
- 语音录制 → Library 快捷按钮 🎙
- 网页收藏 → Library 快捷按钮 🌐

旧路由入口：`pages/capture/index`（已不存在）

---

---

## 本 Tab 包含的页面

| 文件 | 路由 | 类型 |
|------|------|------|
| [index.md](index.md) | `pages/capture/index` | tabBar 主页 |
| [ocr.md](ocr.md) | `pages/capture/ocr` | 子页面（navigateTo）|
| [metadata.md](metadata.md) | `pages/capture/metadata` | 子页面（navigateTo）|

---

## 录入流程总览

```
主录入（index）
    ├── 手动输入 → 直接填表 → 保存
    ├── OCR 流程 → [ocr.vue] 选图识别 → 文字回传 → [metadata.vue] 填元数据 → 保存
    └── 语音录制 → 录音路径填入 originalText（无 STT）
```
