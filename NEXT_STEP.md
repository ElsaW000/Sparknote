# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：AUTH-04（认证令牌刷新）尚未开始，仍处于等待执行状态

## 下一步任务
- **实现 AUTH-04 认证令牌刷新**（backend）
  - 当前状态：JWT 有过期时间（默认 24h，`exp` 字段），但无 `/auth/refresh` 端点
  - 参考 `PRD/phases/05-feature-benchmark-and-prd-expansion.md`：
    - 添加 access token 过期验证与刷新机制
    - `/auth/register` 已返回 token（无需改）
    - 过期时统一返回 400，提示"令牌已过期"
  - 最小可行方案：
    1. 在 User 表增加 `refresh_token` 字段
    2. `POST /auth/refresh` 端点：用 refresh_token 换新 access_token
    3. `POST /auth/login` 时同时返回 access_token + refresh_token
    4. Token 路由中捕获 `JWTError` 并返回 400 + "令牌已过期"
  - 建议先与 Elisa 确认刷新流程细节（refresh_token 有效期、是否需要 revoke 机制）
  - 参考 `PRD/backend-python/p0/` 下已有 spec 格式，可照此格式写 AUTH-04 spec

## 阻塞点与补救
- 阻塞点：无阻塞，PRD 有基本描述，可直接开始实现
- 补救动作：
  1. 读取 `backend/main.py` 中 `create_access_token` 和 auth 路由，确认当前 token 结构
  2. 检查 User 模型，确认是否有 `refresh_token` 字段
  3. 参照 Phase 5 spec 补充 refresh 机制

## 人工测试
-

---

## Phase 5 P0 进度总览

| ID | 描述 | 实现 | 状态 |
|----|------|------|------|
| AUTH-04 | 认证令牌刷新 | backend | 🔄 下一个 |
| AUTH-05 | 邮箱验证 | backend | 未开始 |
| TAG-03 | 批量标签管理 | — | 未认领 |
| NOTE-07 | 笔记复制/移动 | ✅ | ✅ 已完成 |
| NOTE-08 | 组合筛选过滤 | ✅ backend+frontend | ✅ 已完成 |
| NOTE-09 | 置顶/排序视图 | ✅ | ✅ 已完成 |
| NOTE-10 | 模板笔记 | ✅ | ✅ 已完成 |
| CAL-02 | 日历到期提醒 | — | 未认领 |

## 本次操作记录（生成时间：2026-04-30 19:35 Asia/Shanghai）

- 检测到最近 ~60 分钟内无新 git 提交（最后提交 18:35）
- 存在少量 untracked 临时文件（debug脚本、zip等），不属于功能代码
- NOTE-08 已完成（18:35 commit），AUTH-04 顺延为下一个目标
- Backend 已有基础 JWT 过期逻辑（AUTH-04 需补充 refresh 机制）
- 无新的功能代码改动，仅 NEXT_STEP.md 自身有未提交变更（本次更新）
