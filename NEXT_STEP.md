# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：AUTH-04（注册验证码防刷）✅ **已完成**
  - 后端：`GET /auth/captcha` + `POST /auth/register` 验证码校验已实现
  - 前端：`register.dart` 已有完整验证码 UI
  - 测试：`pytest` 24/24 通过，包含 `test_registration_captcha`

## 下一步任务
- **实现 TAG-03 常用标签快捷选择**（backend + frontend）
  - 当前状态：
    - 后端已有 `/tags/suggest` 端点，但 PRD spec 要求 `/tags/frequent` + `recent` 标记
    - 前端笔记编辑器没有标签快捷选择 UI
  - PRD spec：`PRD/backend-python/p0/TAG-03-frequent-tags.md`
  - 最小可行方案：
    1. Backend：新增 `GET /tags/frequent`，返回前 20 个标签（按 count 降序），标记 `recent: true`（最近 7 天用过）
    2. Backend：确认 `GET /notes` 每个 note 携带 `tags: [{id, name}]`
    3. Frontend：笔记编辑器标签栏左侧显示 `GET /tags/frequent` 结果（图标+名称，最多 10 个），点击即添加

## 阻塞点与补救
- 阻塞点：当前无阻塞
- 补救动作：
  1. 读取 `PRD/backend-python/p0/TAG-03-frequent-tags.md` 确认完整 spec
  2. 检查后端 `NoteTag` 表结构和现有标签统计逻辑
  3. 检查 `GET /notes` 是否已返回 `tags` 字段
  4. 实现 `/tags/frequent` 后端端点
  5. 前端编辑器添加标签快捷选择组件

## 人工测试
-

---

## Phase 5 P0 进度总览

| ID | 描述 | 实现 | 状态 |
|----|------|------|------|
| AUTH-04 | 注册验证码防刷 | backend captcha + frontend UI + test | ✅ done |
| AUTH-05 | 邮箱验证 | - | 未开始 |
| TAG-03 | 常用标签快捷选择 | 下一个 | 未开始（后端部分已有 `/tags/suggest`） |
| NOTE-07 | 全局搜索 | done | done |
| NOTE-08 | 组合筛选过滤 | done backend+frontend | done |
| NOTE-09 | 置顶/收藏 | done | done |
| NOTE-10 | 模板笔记 | done | done |
| CAL-02 | 智能文件夹/保存筛选 | - | 未开始 |

## 本次操作记录（生成时间：2026-04-30 21:15 Asia/Shanghai）

- **重要发现**：AUTH-04 实际上已经完成！后端和前端验证码均已实现，测试全部通过
  - 之前被误标为"未开始"是因为检查不够仔细（后端测试覆盖率被测试 disable 遮蔽）
  - 修正：AUTH-04 ✅ 完成
- 下一个待处理 P0：TAG-03（常用标签快捷选择）
- AUTH-05（邮箱验证）需要 SMTP 环境，建议排在 TAG-03 之后处理
- git 状态：仅有 NEXT_STEP.md 被本 cron 修改
