# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：AUTH-04（注册验证码防刷）尚未开始，距上次功能提交（fd9faf2 NOTE-08 完成，18:35）已超过 2.5 小时，无新代码提交

## 下一步任务
- **实现 AUTH-04 注册验证码防刷**（backend + frontend）
  - 当前状态：无验证码校验，`POST /auth/register` 直接接受请求
  - PRD spec：`PRD/backend-python/p0/AUTH-04-captcha-register.md`
  - 最小可行方案：
    1. Backend：添加 `GET /auth/captcha-config` 返回验证码 widget 配置（site key）
    2. Backend：`POST /auth/register` 新增 `captcha_token` 字段校验，失败返回 `400 invalid_captcha`
    3. Frontend：注册页嵌入 Turnstile widget，提交时带上 token
    4. 环境变量：`TURNSTILE_SECRET_KEY` / `HCAPTCHA_SECRET_KEY`
  - 可先使用 Cloudflare Turnstile（免费、无需用户点击）或简单图片验证码作为 MVP

## 阻塞点与补救
- 阻塞点：无阻塞，PRD spec 完整，可直接开始实现
- 补救动作：
  1. 读取 `PRD/backend-python/p0/AUTH-04-captcha-register.md` 确认完整 spec
  2. 读取 `backend/main.py` 中 `/auth/register` 路由，确认当前参数
  3. 决定使用 Turnstile 还是简单图片验证码作为 MVP

## 人工测试
-

---

## Phase 5 P0 进度总览

| ID | 描述 | 实现 | 状态 |
|----|------|------|------|
| AUTH-04 | 注册验证码防刷 | 下一个 | 未开始 |
| AUTH-05 | 邮箱验证 | - | 未开始 |
| TAG-03 | 常用标签快捷选择 | - | 未开始 |
| NOTE-07 | 全局搜索 | done | done |
| NOTE-08 | 组合筛选过滤 | done backend+frontend | done |
| NOTE-09 | 置顶/收藏 | done | done |
| NOTE-10 | 模板笔记 | done | done |
| CAL-02 | 智能文件夹/保存筛选 | - | 未开始 |

## 本次操作记录（生成时间：2026-04-30 21:05 Asia/Shanghai）

- 检测到最近 150 分钟内无新 git 提交（最后功能提交 fd9faf2 于 18:35）
- **重要更正**：之前的 NEXT_STEP 将 AUTH-04 误标为"认证令牌刷新"，实际 PRD spec 中 AUTH-04 = "注册验证码防刷"（captcha），已更正
- 存在少量 untracked 临时文件（debug脚本等），不属于功能代码
- AUTH-04 无阻塞，PRD spec 完整，可立即开始
