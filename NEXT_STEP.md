# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**Phase 6 NOTE-07/09 前端接入仍待完成（上次 cron 确认后无新代码改动）**
- 最近代码提交：2026-05-14 22:35（约 19 小时前无新改动）

## 下一步任务
- **唯一方向：完成 NOTE-07（搜索全文本接入）和 NOTE-09（pin/unpin 按钮）的后端-前端对接**

### NOTE-07 搜索全文本接入
- 后端 `/notes/search` 端点已就绪（main.py:1233）
- 前端已有 `GET /notes?q=` 基础搜索，但使用的是普通查询参数，未接入全文字段搜索
- 补救动作：在 `mobile/lib/pages/notes.dart` 的 `_applySearch()` 中，把 `q` 搜索改为调用 `/notes/search`（或保留 `q=` 但升级后端使其同时搜 title/content/tags）

### NOTE-09 pin/unpin 按钮
- 后端 `PATCH /notes/{id}/pin` 已就绪
- 前端 `notes.dart:688` 已有 sort filter segment `pinned`（可按置顶筛选），但笔记卡操作区无 pin/unpin 切换按钮
- 补救动作：在笔记卡操作行添加 pin/unpin IconButton，调用 `PATCH /notes/{id}/pin`，切换后刷新列表

## 阻塞点与补救
- 阻塞点：无阻塞性技术问题；后端均已就绪，等待前端接入
- 补救动作：
  1. 在 `mobile/lib/pages/notes.dart` 笔记卡操作区添加 pin/unpin 按钮（调用 PATCH /notes/{id}/pin）
  2. 确认搜索需求：是保持当前 `GET /notes?q=` 还是升级为 `/notes/search` 全文本搜索，按需接入

## 人工测试
- Phase 6 功能基础测试已通过（backend 24 passed，2026-05-14 22:30）
- NOTE-07 搜索和 NOTE-09 pin 功能前端接入后需人工验证 UI 交互
- 当前：功能等待人工体验，不自动推进新功能

---

**上下文摘要**
- Phase 6 P0 完成状态（2026-05-14 22:30 盘点，2026-05-15 17:53 确认无新改动）：
  - ✅ TAG-03: 后端+前端（2026-04-30 + 2026-05-01）
  - ✅ NOTE-07: 后端完成，搜索功能部分可用（GET /notes?q=✅，/notes/search 全文本未接入❌）
  - ✅ NOTE-08: 后端+前端（2026-04-30）
  - ✅ NOTE-09: 后端完成，前端无 pin/unpin 按钮（仅 sort filter）
  - ✅ NOTE-10: 后端+前端（2026-04-30）
  - ❌ AUTH-04: 未开始（注册验证码防刷 Turnstile）
  - ❌ AUTH-05: 未开始（邮箱验证）
  - ❌ CAL-02: 未开始（智能文件夹）
- Phase 7 增强（streaming AI / realtime recording / clipboard paste / Notion sync）：未开始
- cron review: 2026-05-15 17:53 CST
