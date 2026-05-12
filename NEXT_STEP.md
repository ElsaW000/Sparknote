# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**Phase 6 未启动，等待 Jie 确认**
- 无代码变更（最近代码提交 `de17e0c` = 2026-05-11，距今约 12 小时）
- AUTH-05 和 CAL-02 PRD 规格文档均已存在且规格清晰

## 下一步任务
- **开始 Phase 6：按以下顺序执行**
  1. **AUTH-05（邮箱验证）** — `PRD/backend-python/p0/AUTH-05-email-verify.md` 已存在，规格清晰，无依赖
     - `POST /auth/request-verification` — 生成6位验证码，存 `email_verification` 表
     - `POST /auth/verify-email` — 验证邮箱，标记用户为已验证
     - 未验证账号登录时提示"请先验证邮箱"
  2. **CAL-02（智能文件夹）** — `PRD/backend-python/p0/CAL-02-smart-folder.md` 已存在
     - CRUD: `GET/POST/PUT/DELETE /saved-views`
  3. **MVP 稳定性清理** — 桌面端体验回归测试 + 后端 API 回归验证

### P0 后端实现状态（8 项中 6 项已有 API，2 项缺失）

| 功能 | 后端状态 |
|------|---------|
| AUTH-04 注册验证码 | ✅ 已实现 |
| **AUTH-05 邮箱验证** | ❌ 缺失 |
| TAG-03 常用标签 | ✅ 已实现 |
| NOTE-07 全局搜索 | ✅ 已实现 |
| NOTE-08 组合筛选 | ✅ 已实现 |
| NOTE-09 置顶/收藏 | ✅ 已实现 |
| NOTE-10 模板笔记 | ✅ 已实现 |
| **CAL-02 智能文件夹** | ❌ 缺失 |

## 阻塞点与补救
- 阻塞点：Phase 6 范围已知（AUTH-05 + CAL-02），Jie 未确认执行顺序
- 补救动作：
  1. **等待 Jie 确认**：是否按 AUTH-05 → CAL-02 → MVP稳定性 的顺序执行
  2. Jie 确认后，Echo 拆分 Issue 并开始实现 AUTH-05

## 人工测试
- MVP 基础流程（登录 → 笔记 → AI 工作区）等待人工桌面端回归验证
- 当前 backend 测试基准：**24 passed**（本次验证）

---

> 最后代码更新：2026-05-11（`de17e0c` — PRD 文档结构整理）
> 本次 NEXT_STEP 更新：2026-05-12 11:15（Shanghai）
> 状态：Backend ✅ UP（24 passed），代码无变化，等待 Jie 确认 Phase 6 执行方向
