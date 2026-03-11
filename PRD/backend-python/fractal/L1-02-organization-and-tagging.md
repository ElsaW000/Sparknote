# L1-02 组织与分类（Organization & Tagging）

## 1. 目标与边界

目标：用最小操作完成标签组织，支持“手动 + 自动 + 推荐”三路并行。
边界：不覆盖跨笔记图谱，仅覆盖标签与筛选。

## 2. 能力清单（Feature IDs）

- `TAG-01` 手动标签
- `TAG-02` 内容中 `#tag` 自动提取
- `TAG-03` 常用标签快捷选择 + 自定义新增（新增）
- `TAG-04` 标签筛选（下一步）

## 3. 闭环流程（事件流）

`输入标签/内容 -> 标准化 -> 去重 -> 持久化 -> 列表渲染 -> 可筛选`

## 4. 状态与数据模型

- `NoteTag`: note_id/user_id/tag
- `TagUsage`: tag/used_count/last_used_at（待加）

## 5. 接口契约（API）

- `API-TAG-01`: `POST /notes` 携带 tags
- `API-TAG-02`: `PATCH /notes/{id}` 更新 tags
- `API-TAG-03`: `GET /tags/suggest`（待加）

## 6. 规则清单（Rules）

- `R-TAG-01`: `#idea` 与 `idea` 归一为同一标签
- `R-TAG-02`: 标签去重，顺序稳定
- `R-TAG-03`: 更新内容时应同步重算自动标签

## 7. 代码映射（Code Mapping）

- `MAP-TAG-01`: [main.py](/d:/02-Projects/01-Sparknote/backend/main.py)
  - `_normalize_tags/_extract_tags_from_content/_merge_tags`
- `MAP-TAG-02`: [notes.dart](/d:/02-Projects/01-Sparknote/mobile/lib/pages/notes.dart)
  - `_extractHashtagTags/_mergeTags`

## 8. 指标与告警

- 标签提取准确率（人工抽样） >= 95%
- 标签重复率 <= 1%

## 9. 验收标准

- 内容输入 `#工作 #idea` 后保存结果有对应标签
- 更新内容新增 hashtag 后，标签列表同步变化
- 常用标签（`TAG-03`）点击后可直接附加到笔记
