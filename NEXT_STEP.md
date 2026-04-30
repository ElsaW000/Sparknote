# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：AUTH-04（认证令牌刷新）尚未开始，仍处于等待执行状态
- 距上次功能提交（fd9faf2 NOTE-08 完成，18:35）已超过 1 小时 20 分钟，无新代码提交

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

## 本次操作记录（生成时间：2026-04-30 19:55 Asia/Shanghai）

- 检测到最近 ~80 分钟内无新 git 提交（最后功能提交 fd9faf2 于 18:35）
- Backend 状态需人工确认（上次确认 19:45 健康）
- AUTH-04 描述清晰，无阻塞，仍是当前唯一下一步目标
- 存在少量 untracked 临时文件（debug脚本、zip等），不属于功能代码，不影响主流程
