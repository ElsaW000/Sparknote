# CAL-02 智能文件夹/保存筛选

## 用户故事
作为用户，我希望保存一组筛选条件，下次一键查看。

## 验收标准
- 可保存筛选条件并命名
- 支持编辑与删除保存筛选

## API 设计

### 新增: GET /saved-views
**Response**: `200 {"views": [{"id": 1, "name": "工作相关", "filters": {"tag_ids": [1], "date_from": "2026-01-01"}, "created_at": "..."}]}`

### 新增: POST /saved-views
**Request**: `{"name": "工作相关", "filters": {"tag_ids": [1], "date_from": "2026-01-01"}}`
**Response**: `201 {"id": 1, "name": "工作相关", ...}`

### 新增: PUT /saved-views/{id}
**Request**: `{"name": "新名称", "filters": {...}}`
**Response**: `200`

### 新增: DELETE /saved-views/{id}
**Response**: `200`

### 前端使用方式
- 用户在笔记列表筛选好后，点击"保存当前筛选"
- 保存的视图显示在左侧边栏，点击后自动应用筛选条件
- 可重命名/删除

### 数据库变更
```sql
CREATE TABLE saved_views (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    filters TEXT NOT NULL,  -- JSON: {"tag_ids": [], "date_from": null, "date_to": null, "sort": "updated_at"}
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX idx_saved_views_user ON saved_views(user_id);
```

### 前端配合
- 笔记列表页左侧加"已保存视图"面板
- 当前筛选条件旁加💾保存按钮
- 保存视图后，下次打开自动恢复上次视图
