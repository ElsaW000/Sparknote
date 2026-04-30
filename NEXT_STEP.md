# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：NOTE-08 组合筛选已全部完成（backend 2bb484c + frontend 3c0949b）

## 下一步任务
- **实现 AUTH-04 认证令牌刷新**（backend）：在 FastAPI 中为 JWT access token 添加自动过期与刷新机制
  - 当前 JWT 无过期验证，前端登录后 token 永久有效
  - 建议：access token 15-30min 过期，提供 `/auth/refresh` 端点用 refresh token 换新 access token
  - 可参考 Auth-04 描述或与 Elisa 确认具体刷新流程

## 阻塞点与补救
- 阻塞点：无（NOTE-08 已完成）
- 补救动作：N/A

## 人工测试
- NOTE-08 组合筛选（标签+日期+排序+match）需端到端验证
- 可在笔记页面点击"筛选"按钮测试各参数组合

---

## Phase 5 P0 进度总览

| ID | 描述 | 实现 | 状态 |
|----|------|------|------|
| AUTH-04 | 认证令牌刷新 | backend | 🔄 下一个 |
| AUTH-05 | 刷新令牌机制 | backend | 未开始 |
| TAG-03 | 批量标签管理 | — | 未认领 |
| NOTE-07 | 笔记复制/移动 | ✅ | ✅ 已完成 |
| NOTE-08 | 组合筛选过滤 | ✅ backend+frontend | ✅ 已完成 |
| NOTE-09 | 置顶/排序视图 | ✅ | ✅ 已完成 |
| NOTE-10 | 模板笔记 | ✅ | ✅ 已完成 |
| CAL-02 | 日历到期提醒 | — | 未认领 |

## 本次操作记录（生成时间：2026-04-30 18:35 Asia/Shanghai）

- 检测到 notes.dart 有 440 行未提交 diff
- `flutter analyze lib/pages/notes.dart` → 7 issues（均为 warning/info，无错误）
- 已 commit：`feat: NOTE-08 combination filter frontend`（3c0949b）
- NOTE-08 全部完成，下一步推进 AUTH-04
