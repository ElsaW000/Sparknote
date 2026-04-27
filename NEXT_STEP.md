# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**Phase 2 PRD 就绪（commit 4f75b03），代码无新变动，继续等待 Jie 启动 Agent 系统实现**

## 下一步任务
- **实现 Agent 预设模板系统的后端部分**
- 具体范围（基于 PRD/06-agent-customization.md + PRD/07-agent-design.md）：
  1. 数据库：User 表增加 `agent_name`、`agent_prompt`、`agent_template` 字段；新建 `agent_templates` 预设模板表
  2. API：
     - `GET /agent/templates` — 返回预设角色列表（creator/coach/brainstorm/editor/custom）
     - `GET /agent/config` — 返回当前用户的 Agent 配置
     - `PUT /agent/config` — 更新用户的 Agent 配置
  3. AI 调用改造：`_ai_reply` / `chat_completion` 注入用户选定的 system_prompt
  4. 初始化预设模板数据（4个预设角色）
- 不包含：前端 Agent 设置页面、对话导出、角色创建

## 阻塞点与补救
- 阻塞点：无技术阻塞。PRD 字段设计清晰，API 数量少且标准。
- 补救动作：
  1. Echo 读取 backend/main.py 的 User model 和 AI 调用逻辑
  2. 确认现有数据库结构，设计 migration
  3. 依次实现 API endpoints → 数据模型 → AI 注入 → 种子数据
  4. 写 API tests 覆盖

## 人工测试
- 待 Agent 后端完成后验证：
  1. `GET /agent/templates` 返回 4 个预设角色
  2. `PUT /agent/config` 切换模板后，`POST /conversations/{id}/message` 使用对应 system prompt
  3. 用户未配置时默认使用 `creator`

## 背景
- 代码静止于：2026-03-18（workspace editor scroll convergence）
- PRD 静止于：2026-04-27（Phase 2 PRD commit `4f75b03`）
- 核心方向：**"把碎片激活成新创意"** — Agent 模板系统让用户定制 AI 灵魂
- 当前状态：PRD 就绪，代码未开始，等待 Jie 确认启动

----
*Last review: 2026-04-27 21:47 UTC+8 (cron) — Phase 2 PRD ready, no code changes since last review, awaiting Jie start*
