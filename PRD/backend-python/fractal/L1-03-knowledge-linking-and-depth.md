# L1-03 知识连接与深化（Knowledge Linking & Depth）

## 1. 目标与边界

目标：让“散点笔记”变成“可复用知识网络”。
边界：当前优先做轻链接，不先做复杂图数据库。

## 2. 能力清单（Feature IDs）

- `LINK-01` 反向链接（新增）
- `LINK-02` 相关笔记推荐
- `LINK-03` 对话总结落地为笔记（已具备基础）

## 3. 闭环流程（事件流）

`生成/更新笔记 -> 关联索引更新 -> 展示关联笔记 -> 用户继续编辑`

## 4. 状态与数据模型

- `NoteRelation`: source_note_id/target_note_id/relation_type/score
- `ConversationSummary`: conversation_id/note_id/summary

## 5. 接口契约（API）

- `API-LINK-01`: `GET /notes/{id}/related`（待加）
- `API-LINK-02`: `POST /conversations/{id}/close`（已存在）

## 6. 规则清单（Rules）

- `R-LINK-01`: 相似推荐必须可解释（至少给出关键词）
- `R-LINK-02`: 总结生成失败时不应破坏原会话数据

## 7. 代码映射（Code Mapping）

- `MAP-LINK-01`: [main.py](/d:/02-Projects/01-Sparknote/backend/main.py)
  - `close_conversation`
- `MAP-LINK-02`: [chat.dart](/d:/02-Projects/01-Sparknote/mobile/lib/pages/chat.dart)
  - “生成总结”交互链路

## 8. 指标与告警

- 总结成功率 >= 98%
- 用户点击“相关笔记”CTR（后续）

## 9. 验收标准

- 对话可生成总结并落笔记
- 后续新增 related API 后，可返回可读关联结果
