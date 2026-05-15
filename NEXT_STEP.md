# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**Phase 6 NOTE-07/09 前端接入已完成**（代码在 working tree，尚未 commit；后端测试 24 passed）

## 下一步任务
- **提交 NOTE-07/09 前端接入代码，然后转向 AUTH-04：登录页接入 Cloudflare Turnstile 防机器人验证**
  - 后端 `/auth/turnstile/verify` 端点已实现（backend/main.py）
  - 前端登录页（`mobile/lib/pages/login.dart`）需要接入 Turnstile widget，在登录时将 token 随请求一起发送
  - 这是 Phase 6 中安全类 P0 项，可与后端联动验证

## 阻塞点与补救
- 阻塞点：无技术阻塞
- 补救动作：
  1. `git add mobile/lib/pages/notes.dart; git commit -m "feat(notes): NOTE-07 search + NOTE-09 pin/unpin frontend integration"`
  2. 读取 `mobile/lib/pages/login.dart`，参考后端 `turnstile/verify` 端点签名，在登录表单添加 Turnstile widget 并随 `POST /auth/login` 提交 `turnstile_token` 字段

## 人工测试
- NOTE-07 搜索和 NOTE-09 pin 功能接入后需人工验证：
  - 搜索关键词能正确过滤笔记列表
  - Pin/Unpin 后笔记顺序正确更新
- Turnstile 接入后需在非浏览器自动化环境下测试登录流程

---

**记录**
- Phase 6 P0 状态（2026-05-15 20:49 盘点）：
  - [x] NOTE-07: 搜索全文本（后端+前端 ✅）
  - [ ] NOTE-08: 加密+解密（需确认状态）
  - [x] NOTE-09: pin/unpin（后端+前端 ✅）
  - [ ] AUTH-04: 登录保护（Turnstile，后端就绪，前端待接入）
  - [ ] AUTH-05: 注册保护（Turnstile，未开始）
  - [ ] CAL-02: 日程化（未开始）
- Phase 7 暂停（streaming AI / realtime recording / clipboard paste / Notion sync）
- cron review: 2026-05-15 20:49 CST
