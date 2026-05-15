# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**AUTH-04 前端接入 Turnstile（login.dart）** — 未开始，backend/main.py 已 committed，login.dart 尚未修改

## 下一步任务
- **在 `mobile/lib/pages/login.dart` 中接入 Cloudflare Turnstile widget**
  - 后端已有 `POST /auth/login` 支持 `captcha_id` + `captcha_answer`，且 `REQUIRE_LOGIN_CAPTCHA` 环境变量控制开关
  - 前端需要：
    1. 在 `mobile/lib/config.dart` 中添加 Turnstile sitekey 常量（如 `static const turnstileSitekey = '1x00000000000000000000AA';`，测试用 sitekey）
    2. 在 `LoginPageState` 中添加 `String? _turnstileToken` 状态（或用 GlobalKey）
    3. 在登录表单上方/下方插入 Turnstile widget
    4. 登录提交时读取 Turnstile token，附加到登录请求（`captcha_id`/`captcha_answer` 字段）
    5. 若 `REQUIRE_LOGIN_CAPTCHA=1` 且无 token，后端返回 403

## 阻塞点与补救
- 阻塞点：无技术阻塞（后端已就绪，login.dart 可直接修改，register.dart 已有类似 captcha 参考实现）
- 补救动作：
  1. 参考 `register.dart` 的 captcha 实现模式
  2. 添加 `turnstile_sitekey` 到 config.dart（测试环境用默认 sitekey）
  3. 在 `login.dart` 中类似地添加 Turnstile widget 和 token 获取逻辑
  4. 登录按钮 onPressed 时获取 token，POST 时附加 captcha_id / captcha_answer

## 人工测试
- 待前端接入完成后，在非自动化浏览器环境下测试登录流程，确认 captcha token 通过验证

---

**记录**
- Phase 6 P0 状态（2026-05-15 21:59 盘点）：
  - [x] NOTE-07: 搜索全文本（后端+前端 ✅）
  - [x] NOTE-09: pin/unpin（后端+前端 ✅）
  - [~] AUTH-04: 登录保护 Turnstile（**后端已 committed，login.dart 前端未开始**）
  - [ ] AUTH-05: 注册保护 Turnstile（未开始）
  - [ ] CAL-02: 日程化（未开始）
- Phase 7 暂停（streaming AI / realtime recording / clipboard paste / Notion sync）
- cron review: 2026-05-15 21:59 CST
- 无新代码变更（距上次 commit 约 20 分钟）
