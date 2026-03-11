# L1-06 AI 洞察视角系统（AI Insight Perspectives）

## 1. 目标与边界

目标：把 AI 洞察做成“视角卡片系统”，支持默认视角与用户自定义视角。
边界：先做文本笔记洞察，不做多模态推理。

## 2. 能力清单（Feature IDs）

- `AI-INSIGHT-01` 视角卡片库（复盘整理/自我觉察/思维决策）
- `AI-INSIGHT-02` 默认视角执行（如默认洞察、逆向思考、CBT）
- `AI-INSIGHT-03` 自定义视角模板
- `AI-INSIGHT-04` 洞察历史与范围重跑

## 3. 闭环流程（事件流）

`选择视角 -> 组装 Prompt 模板 -> 执行分析 -> 返回结构化洞察 -> 保存历史 -> 用户二次提问`

## 4. 状态与数据模型

- `InsightPerspective`: id/name/category/prompt_template/is_default
- `InsightRun`: id/user_id/perspective_id/note_ids/result/status/created_at

## 5. 接口契约（API）

- `API-AI-01`: `GET /insights/perspectives`（待加）
- `API-AI-02`: `POST /insights/run`（待加）
- `API-AI-03`: `GET /insights/history`（待加）

## 6. 规则清单（Rules）

- `R-AI-01`: 洞察输出必须包含“结论 + 证据片段 + 行动建议”
- `R-AI-02`: 洞察可重跑且结果可追溯输入范围
- `R-AI-03`: 用户自定义模板需做敏感指令过滤

## 7. 代码映射（Code Mapping）

- `MAP-AI-01`: [ai_provider.py](/d:/02-Projects/01-Sparknote/backend/ai_provider.py)
- `MAP-AI-02`: [main.py](/d:/02-Projects/01-Sparknote/backend/main.py)
- `MAP-AI-03`: （待建）`mobile/lib/pages/insights.dart`

## 8. 指标与告警

- 洞察成功率
- 平均洞察耗时
- 洞察被采纳率（用户点击“采纳建议”）

## 9. 验收标准

- 可按一级类目查看视角卡片
- 选定视角后能对笔记生成结构化洞察
- 洞察历史可回查、可重跑
