# NOTE-07 全局搜索

## 用户故事
作为用户，我希望按关键词快速找到历史笔记。

## 验收标准
- 支持标题/内容/标签检索
- 搜索结果按更新时间倒序
- 空结果显示明确提示

## API 设计

### 新增: GET /notes/search
**Query params**:
- `q: str` (required) — 搜索关键词，最少 1 字符
- `page: int` (default: 1)
- `limit: int` (default: 20, max: 50)

**Response**: `200 {"results": [...], "total": 42, "page": 1, "limit": 20}`
**Logic**:
```sql
SELECT n.* FROM notes n
LEFT JOIN note_tags nt ON n.id = nt.note_id
LEFT JOIN tags t ON nt.tag_id = t.id
WHERE n.user_id = :uid
  AND (
    n.title LIKE '%:q%'
    OR n.content LIKE '%:q%'
    OR t.name LIKE '%:q%'
  )
GROUP BY n.id
ORDER BY n.updated_at DESC
LIMIT :limit OFFSET :offset
```
- 支持中文分词（SQLite FTS5 或 LIKE + 简单空格分词）
- 去重（同一 note 有多个匹配标签只出现一次）

### 性能考量
- 初期用 LIKE 查询可接受，note 量 > 1 万后建议迁移到 SQLite FTS5 全文索引
- 可加 `CREATE INDEX idx_notes_user_updated` 加速排序

### 前端配合
- 全局搜索框（顶栏），输入即搜（debounce 300ms）
- 结果高亮匹配关键词
