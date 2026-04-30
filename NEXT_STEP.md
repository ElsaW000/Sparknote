# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：TAG-03（常用标签快捷选择）**未完成**
  - 后端：存在 `/tags/suggest`，需要改造为 `/tags/frequent` + 完整 schema
    - 当前返回：`[{tag: str, count: int}]`
    - PRD 要求：`[{id, name, count, recent}]`
    - 缺失：`id`（来自 `notetag.id`）、`recent`（7天内使用，需 join note.created_at）
    - 命名不符：PRD 要求 `/tags/frequent`，当前是 `/tags/suggest`
  - `NoteRead.tags` 返回 `List[str]`，PRD 要求 `List[{id, name}]`
  - 前端标签快捷选择 UI：未开始
  - git 状态：40分钟内无新 commit（最后 commit `9698ecf` at 21:15）

## 下一步任务
- **实现 TAG-03 后端完整改造（`/tags/frequent` + `NoteRead.tags` schema）**
  - PRD spec：`PRD/backend-python/p0/TAG-03-frequent-tags.md`
  - 数据库确认：
    - `notetag` 表有 `id` 自增主键 ✅
    - `notetag` 无 `created_at`，需通过 `JOIN note ON notetag.note_id = note.id` 的 `MAX(note.created_at)` 判断 `recent`
  - 具体改动：
    1. **重命名/改造 `/tags/suggest` → `/tags/frequent`**：
       - 返回格式：`[{id, name, count, recent}]`
       - `name` = `notetag.tag`
       - `id` = 取该用户该 tag name 对应的最小 `notetag.id`（确定性）
       - `count` = 按 tag name 使用次数降序
       - `recent: true` = 该用户至少有 1 条关联 note 在 7 天内创建
    2. **更新 `NoteRead.tags` schema**：`List[str]` → `List[{id: int, name: str}]`
       - 修改 `_note_to_read()` 中 tags 构建逻辑，返回 `{id, name}` 对象列表
    3. 跑通 `pytest backend/tests -q` 确认无回归
    4. 完成后进入前端标签快捷选择 UI 实现

## 阻塞点与补救
- 阻塞点：
  - `notetag` 表无 `created_at`，`recent` 逻辑需用 `JOIN note` 替代
  - `NoteRead.tags` 的 `id` 字段：同一 tag name 在多条 note 上有多条 `notetag` 记录，取哪个 id 需要确定（建议取 min）
- 补救动作（我接下来应做什么）：
  1. 写 SQL/ORM 查询验证 `/tags/frequent` 逻辑（单用户 join 验证）
  2. 修改 `main.py` 中 `/tags/suggest` → `/tags/frequent` 并补充完整字段
  3. 更新 `NoteRead` schema + `_note_to_read()` 函数
  4. 运行 pytest 确认无回归
  5. 继续前端 UI 实现

## 人工测试
-

---

## Phase 5 P0 进度总览

| ID | 描述 | 实现 | 状态 |
|----|------|------|------|
| AUTH-04 | 注册验证码防刷 | backend captcha + frontend UI + test | ✅ done |
| AUTH-05 | 邮箱验证 | - | 未开始 |
| TAG-03 | 常用标签快捷选择 | `/tags/frequent` 后端 + 前端UI | **进行中** |
| NOTE-07 | 全局搜索 | done | done |
| NOTE-08 | 组合筛选过滤 | done backend+frontend | done |
| NOTE-09 | 置顶/收藏 | done | done |
| NOTE-10 | 模板笔记 | done | done |
| CAL-02 | 智能文件夹/保存筛选 | - | 未开始 |

## 本次操作记录（生成时间：2026-04-30 21:55 Asia/Shanghai）

- 确认 TAG-03 后端部分完成但不满足 PRD spec
  - `/tags/suggest` 存在但命名不符、缺少 `id` 和 `recent` 字段
  - `NoteRead.tags` 仍为 `List[str]` 而非对象数组
  - 数据库确认：`notetag` 表有 `id` 主键 ✅，无 `created_at` → recent 需 join note 表 ✅
- 前端标签快捷选择 UI：未开始
- git 状态：40分钟无新 tracked 文件变更（最后 commit `9698ecf` at 21:15）
- 下一步行动：改造 `/tags/suggest` → `/tags/frequent` + 更新 NoteRead schema，然后接前端 UI
