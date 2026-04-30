# TAG-03 常用标签快捷选择 + 自定义新增

## 用户故事
作为用户，我希望编辑笔记时可点选常用标签，也可手动新增。

## 验收标准
- 编辑器显示"最近使用/高频标签"
- 点击标签可一键添加到笔记
- 输入新标签回车可创建并选中

## API 设计

### 新增: GET /tags/frequent
**Response**: `200 {"tags": [{"id": 1, "name": "工作", "count": 42, "recent": true}, ...]}`
**Logic**:
- 最近 7 天使用过的标签标记 `recent: true`
- 按 `count` 降序，取前 20 条
- 只返回当前用户的标签（join with user's notes）

### 修改: POST /notes (和 PATCH /notes/{id})
**Behavior**:
- 保持现有 hashtag 提取逻辑不变
- 同时支持前端传入 `tags: [id1, id2, "新标签名"]` 覆盖或补充自动提取结果
- 若 tag name 不存在则创建后关联

### 修改: GET /notes (笔记列表)
**Response** 扩展:
- 每个 note 携带 `tags: [{"id": 1, "name": "工作"}, ...]`
- 方便前端在编辑时预填充已有标签

### 数据库变更
- `tags.count` 字段需要维护（每次 note 创建/删除/标签变更时更新）
- 建议加 `tags.last_used_at` 方便查最近使用

### 前端配合
- 笔记编辑器标签栏：
  - 左侧显示 `GET /tags/frequent` 结果（图标+名称，最多 10 个）
  - 点击即添加到当前笔记 tag 列表
  - 输入框输入新标签名，回车创建
