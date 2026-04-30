# NOTE-09 置顶/收藏

## 用户故事
作为用户，我希望把重要笔记置顶方便回看。

## 验收标准
- 列表区分"置顶"和"普通"
- 可随时取消置顶

## API 设计

### 新增: POST /notes/{id}/pin
**Response**: `200 {"pinned": true}`
**Logic**: 设置 `notes.is_pinned = TRUE`, `notes.pinned_at = NOW()`

### 新增: DELETE /notes/{id}/pin
**Response**: `200 {"pinned": false}`
**Logic**: 设置 `notes.is_pinned = FALSE`

### 修改: GET /notes
**Query params** 新增:
- `filter: all | pinned | unpinned` (default: `all`)

**Response**:
- 列表默认按 `pinned DESC, updated_at DESC` 排序
- 每个 note 携带 `"is_pinned": true/false` 字段

### 数据库变更
```sql
ALTER TABLE notes ADD COLUMN is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE notes ADD COLUMN pinned_at DATETIME;
CREATE INDEX idx_notes_user_pinned ON notes(user_id, is_pinned, pinned_at DESC);
```

### 前端配合
- 笔记卡片右上角加⭐/📌图标按钮
- 置顶笔记在列表顶部显示，有视觉区分
