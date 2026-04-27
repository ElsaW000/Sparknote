# Sparknote AI Agent 功能规格

## 概述

让用户自定义 AI 的"灵魂"——系统提示词、语气、风格，形成专属的创作助手。类似 WordPress 主题系统：底层能力预置，用户只定制表层。

---

## 1. 数据模型

### 1.1 用户设置扩展

在 User 表增加字段：

| 字段 | 类型 | 描述 |
|------|------|------|
| agent_name | VARCHAR(50) | Agent 昵称 |
| agent_prompt | TEXT | 自定义系统提示词 |
| agent_template | VARCHAR(50) | 预设模板 ID（ nullable） |

### 1.2 预设模板表

| 字段 | 类型 | 描述 |
|------|------|------|
| id | INT | 主键 |
| name | VARCHAR(50) | 模板名称 |
| description | TEXT | 模板描述 |
| system_prompt | TEXT | 系统提示词内容 |
| icon | VARCHAR(20) | 图标 emoji |

---

## 2. 预设模板

### 模板1：创作搭子
- **名称**：创作搭子
- **描述**：陪你聊天，帮你扩展灵感
- **提示词**：你是 Sparknote 的创作搭子，擅长帮用户扩展想法、讨论情节。不要直接给答案，要引导用户自己思考。

### 模板2：写作教练
- **名称**：写作教练
- **描述**：给你写作建议，帮你改稿
- **提示词**：你是资深写作教练，擅长点评文章结构、语言风格。给用户具体、可执行的修改建议。

### 模板3：头脑风暴
- **名称**：头脑风暴
- **描述**：快速生成大量创意点子
- **提示词**：你是创意机器，擅长在短时间内抛出大量点子。不要过滤，先发散再收敛。

### 模板4：自定义
- **名称**：自定义
- **描述**：完全自定义你的 AI
- **提示词**：用户自己写

---

## 3. API 设计

### 3.1 获取用户 Agent 配置

```
GET /agent/config
```

Response:
```json
{
  "agent_name": "我的创作搭子",
  "agent_template": "creator",
  "custom_prompt": null
}
```

### 3.2 更新 Agent 配置

```
PUT /agent/config
```

Request:
```json
{
  "agent_name": "我的创作搭子",
  "agent_template": "creator",
  "custom_prompt": "你是我的小说助手..."
}
```

### 3.3 获取预设模板列表

```
GET /agent/templates
```

Response:
```json
[
  {
    "id": "creator",
    "name": "创作搭子",
    "description": "陪你聊天，帮你扩展灵感",
    "icon": "🎭"
  },
  {
    "id": "coach",
    "name": "写作教练",
    "description": "给你写作建议，帮你改稿",
    "icon": "📝"
  },
  {
    "id": "brainstorm",
    "name": "头脑风暴",
    "description": "快速生成大量创意点子",
    "icon": "💡"
  },
  {
    "id": "custom",
    "name": "自定义",
    "description": "完全自定义你的 AI",
    "icon": "⚙️"
  }
]
```

---

## 4. 对话流程修改

### 4.1 调用 AI 时注入系统提示词

原来的调用：
```python
messages = [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": prompt},
]
```

修改后：
```python
system_prompt = user.agent_custom_prompt or TEMPLATES[user.agent_template].prompt

messages = [
    {"role": "system", "content": system_prompt},
    {"role": "user", "content": prompt},
]
```

---

## 5. 前端页面

### 5.1 Agent 设置入口
- 在"我的"页面增加"AI 助手设置"入口

### 5.2 设置页面
- 展示当前模板
- 切换模板（点击卡片选择）
- 自定义文本框（当选择"自定义"时显示）
- Agent 昵称输入框
- 预览效果

---

## 6. MVP 范围

### P0（必须）
- 用户切换预设模板
- 对话时使用选定的系统提示词
- Agent 昵称展示

### P1（可选）
- 自定义提示词编辑
- Agent 名称自定义
- 预设模板列表

---

## 7. 后续扩展

- 支持预设 skills（根据模板加载不同 skills）
- MCP 工具配置（不同模板有不同的工具权限）
- 对话风格选择（正式/轻松/简洁）

---

## 8. 技术实现

### 8.1 数据库迁移

```sql
ALTER TABLE user ADD COLUMN agent_name VARCHAR(50);
ALTER TABLE user ADD COLUMN agent_prompt TEXT;
ALTER TABLE user ADD COLUMN agent_template VARCHAR(50);
```

### 8.2 后端改动

1. `main.py` 增加 agent 相关字段到 User model
2. 新增 `/agent/config` 和 `/agent/templates` 接口
3. 修改 `_ai_reply` 函数支持自定义 system prompt

### 8.3 前端改动

1. 新增 Agent 设置页面
2. 模板选择组件
3. 自定义提示词编辑框