# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**Phase 6 P0 后端全部完成，前端部分完成（TAG-03/08/10 ✅，NOTE-07/09 后端✅前端❌），AUTH-04/05 + CAL-02 未开始**

## 下一步任务
- **唯一方向：将 NOTE-07（全局搜索）和 NOTE-09（置顶/收藏）前端接入现有后端**
  - 两者后端已 commit，前端未对应实现
  - NOTE-07: 基础搜索（GET /notes?q=）已工作；专用全文字段搜索（GET /notes/search，同时搜 title/content/tags）未接入 UI
  - NOTE-09: `PATCH /notes/{id}/pin` 后端已就绪；前端仅有 sort by pinned 选项，无 pin/unpin 按钮

## 阻塞点与补救
- 阻塞点：无阻塞性技术问题，所有后端已就绪
- 补救动作：
  1. NOTE-09: 在笔记卡/详情操作区添加 pin/unpin 按钮（调用 `PATCH /notes/{id}/pin`），切换后刷新列表
  2. NOTE-07: 考虑将搜索入口接入 `/notes/search` 端点以支持标签搜索，或明确当前 `GET /notes?q=` 行为已满足需求

## 人工测试
- Phase 6 功能基础测试已通过（backend 24 passed）
- NOTE-07/09 前端接入后需人工验证 UI 交互

---

**上下文摘要**
- Phase 6 P0 完成状态（2026-05-14 22:30 盘点）：
  - ✅ TAG-03: 后端+前端（2026-04-30 + 2026-05-01）
  - ✅ NOTE-07: 后端完成，搜索功能部分可用（GET /notes?q=✅，/notes/search UI 未接入❌）
  - ✅ NOTE-08: 后端+前端（2026-04-30）
  - ✅ NOTE-09: 后端完成，前端无 pin/unpin 按钮（仅 sort 选项）
  - ✅ NOTE-10: 后端+前端（2026-04-30）
  - ❌ AUTH-04: 未开始（注册验证码防刷 Turnstile）
  - ❌ AUTH-05: 未开始（邮箱验证）
  - ❌ CAL-02: 未开始（智能文件夹）
- Phase 7 增强（streaming AI / realtime recording / clipboard paste / Notion sync）：未开始
- cron review: 2026-05-14 22:30 CST
