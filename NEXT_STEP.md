# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**AUTH-04 前端接入 Turnstile 防机器人验证**（后端 `/auth/turnstile/verify` 已实现，前端 `login.dart` 待接入）

## 下一步任务
- **在 `mobile/lib/pages/login.dart` 中接入 Cloudflare Turnstile widget，实现登录防机器人验证**
  - 后端已有 `POST /auth/turnstile/verify` 端点，登录接口已支持 `turnstile_token` 字段
  - 前端需：引入 Turnstile JS SDK → 在登录表单渲染 invisible/widget Turnstile → 登录提交时附上 `turnstile_token`

## 阻塞点与补救
- 阻塞点：无技术阻塞
- 补救动作：
  1. 在 `mobile/lib/pages/login.dart` 的 `<head>` 或全局 JS 中引入 Turnstile script
  2. 在登录按钮上方添加 Turnstile widget div（使用 sitekey）
  3. 登录 `onPressed` 时从 `turnstile` ref 读取 token，随 `email`/`password` 一起 POST 到 `/auth/login`

## 人工测试
- 需在非自动化浏览器环境下测试登录流程，确认 Turnstile token 正确通过验证

---

**记录**
- Phase 6 P0 状态（2026-05-15 21:09 盘点）：
  - [x] NOTE-07: 搜索全文本（后端+前端 ✅，已 commit 209acde）
  - [ ] NOTE-08: 加密+解密（需确认状态）
  - [x] NOTE-09: pin/unpin（后端+前端 ✅，已 commit 209acde）
  - [ ] AUTH-04: 登录保护（Turnstile，后端就绪，**前端待接入**）
  - [ ] AUTH-05: 注册保护（Turnstile，未开始）
  - [ ] CAL-02: 日程化（未开始）
- Phase 7 暂停（streaming AI / realtime recording / clipboard paste / Notion sync）
- cron review: 2026-05-15 21:09 CST
