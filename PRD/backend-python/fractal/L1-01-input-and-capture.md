# L1-01 输入与记录（Input & Capture）

## 1. 目标与边界

目标：降低记录摩擦，保证“1 秒可写入，3 秒可回看”。
边界：只覆盖输入链路，不含标签深度组织与 AI 深度分析。

## 2. 能力清单（Feature IDs）

- `CAP-01` 快速文本录入
- `CAP-02` 对话式输入建笔记
- `CAP-03` 注册后首笔记引导
- `CAP-04` 外部输入通道（后续：微信/API）

## 3. 闭环流程（事件流）

`打开输入 -> 本地校验 -> 调用创建接口 -> 返回 NoteRead -> 列表刷新 -> 日历可见`

## 4. 状态与数据模型

- `DraftNote`: title/content/tags
- `PersistedNote`: id/title/content/tags/created_at/user_id

## 5. 接口契约（API）

- `API-CAP-01`: `POST /notes`
- `API-CAP-02`: `GET /notes`

## 6. 规则清单（Rules）

- `R-CAP-01`: 内容为空时禁止提交
- `R-CAP-02`: 保存失败必须给前端可见错误
- `R-CAP-03`: 保存成功后必须触发列表刷新

## 7. 代码映射（Code Mapping）

- `MAP-CAP-01`: [notes.dart](/d:/02-Projects/01-Sparknote/mobile/lib/pages/notes.dart)
  - 关联规则：`R-CAP-01/02/03`
- `MAP-CAP-02`: [main.py](/d:/02-Projects/01-Sparknote/backend/main.py)
  - 关联规则：`R-CAP-03`

## 8. 指标与告警

- 录入成功率 >= 99%
- 新建后 2s 内可见率 >= 99%
- 错误提示覆盖率 = 100%

## 9. 验收标准

- 新建笔记后立即出现在列表
- 日历视图能按 `created_at` 看到当天笔记
- 网络异常时用户能看到失败原因
