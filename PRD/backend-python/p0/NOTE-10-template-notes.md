# NOTE-10 模板创建笔记

## 用户故事
作为用户，我希望用模板快速创建结构化笔记。

## 验收标准
- 提供至少 3 个模板（灵感、会议、复盘）
- 模板可预填字段（标题/标签/结构块）

## API 设计

### 新增: GET /templates
**Response**: `200 {"templates": [{"id": 1, "name": "会议纪要", "icon": "meeting", "title_template": "【会议】{date} {topic}", "content_template": "## 会议目标\n\n## 讨论要点\n\n## 行动项\n\n## 下次会议", "default_tags": ["会议"]}, {"id": 2, "name": "灵感卡片", "icon": "bulb", "title_template": "💡 {date} {title}", "content_template": "## 灵感\n{content}\n\n## 关联\n", "default_tags": ["灵感"]}, {"id": 3, "name": "复盘", "icon": "review", "title_template": "复盘 {date}", "content_template": "## 完成情况\n\n## 问题与改进\n\n## 下一步\n", "default_tags": ["复盘"]}]}`
- 模板数据可以是代码中的常量或 `templates` 表（推荐后者，方便后续扩展）

### 新增: POST /templates/preview
**Request**: `{"template_id": 1, "variables": {"date": "2026-04-30", "topic": "Q2规划"}}`
**Response**: `200 {"title": "【会议】2026-04-30 Q2规划", "content": "## 会议目标\n..."}`

### 修改: POST /notes
**Request** 新增字段:
- `template_id: int` (optional) — 使用模板创建
- `template_variables: dict` (optional) — 模板变量值

**Logic**:
- 若有 `template_id`，先用模板 title/content 填充，再用用户传入值覆盖
- `default_tags` 自动添加到 tags 列表

### 数据库变更
```sql
CREATE TABLE templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    icon TEXT,
    title_template TEXT,
    content_template TEXT NOT NULL,
    default_tags TEXT,  -- JSON array, e.g. '["会议"]'
    sort_order INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 前端配合
- "新建笔记"按钮旁加"从模板创建"入口
- 模板选择弹窗（图标+名称预览）
- 可预览模板展开效果后再创建
