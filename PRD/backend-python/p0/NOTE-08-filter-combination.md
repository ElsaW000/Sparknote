# NOTE-08 组合筛选（标签+日期）

## 用户故事
作为用户，我希望按标签和日期范围过滤笔记。

## 验收标准
- 支持多标签组合筛选
- 支持创建日期范围筛选
- URL 或本地状态保留当前筛选条件

## API 设计

### 修改: GET /notes
**Query params** 新增:
- `tag_ids: str` — 逗号分隔的 tag ID 列表，如 `1,2,3`
- `date_from: str` — ISO date，筛选 created_at >= date_from
- `date_to: str` — ISO date，筛选 created_at <= date_to
- `sort: updated_at | created_at | pinned` (default: updated_at)
- `order: asc | desc` (default: desc)
- `match: all | any` (default: any) — 标签全匹配还是任一匹配

**Example**: `GET /notes?tag_ids=1,2&date_from=2026-01-01&date_to=2026-03-31&sort=pinned`

**Response**:
- 标签筛选: SQL with `INNER JOIN note_tags ON ... WHERE tag_id IN (:tag_ids)` + `GROUP BY note_id HAVING COUNT(DISTINCT tag_id) = :num_tags`（全匹配模式）

### 数据库变更
- 确认 `notes.created_at` 已有索引
- 可选: `CREATE INDEX idx_notes_user_created ON notes(user_id, created_at)`

### 前端配合
- 笔记列表页侧边栏加筛选面板
- 标签多选（checkbox）+ 日期范围选择器
- 筛选条件同步到 URL query params（支持分享/浏览器前进后退）
- 记住用户上次筛选状态（localStorage）
