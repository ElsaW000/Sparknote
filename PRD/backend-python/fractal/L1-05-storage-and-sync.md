# L1-05 存储与同步（Storage & Sync）

## 1. 目标与边界

目标：保证数据可靠保存、跨端一致、可恢复。
边界：当前以 SQLite/单机开发环境为主，预留 PostgreSQL 扩展。

## 2. 能力清单（Feature IDs）

- `SYNC-01` 多端同步一致性
- `STO-01` 图片/附件存储分层
- `STO-02` 存储配额与会员权益
- `REC-01` 数据恢复与导出（后续）

## 3. 闭环流程（事件流）

`客户端写入 -> 服务端持久化 -> 拉取同步 -> 冲突处理 -> 一致性确认`

## 4. 状态与数据模型

- `SyncCursor`: user_id/last_sync_at/version
- `AssetMeta`: asset_id/user_id/url/size/content_type

## 5. 接口契约（API）

- `API-SYNC-01`: `GET /notes`（增量模式后续扩展）
- `API-STO-01`: `POST /assets`（待加）

## 6. 规则清单（Rules）

- `R-SYNC-01`: 写后读一致性必须成立
- `R-SYNC-02`: 超配额写入必须返回明确错误码

## 7. 代码映射（Code Mapping）

- `MAP-SYNC-01`: [main.py](/d:/02-Projects/01-Sparknote/backend/main.py)
- `MAP-SYNC-02`: [notes.dart](/d:/02-Projects/01-Sparknote/mobile/lib/pages/notes.dart)

## 8. 指标与告警

- 写入成功率
- 同步延迟 P95
- 数据不一致工单数

## 9. 验收标准

- 新建后在同会话内可立即读到
- 切换端后可拉到同一用户数据
