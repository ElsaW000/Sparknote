# 数据契约

状态: Active
更新时间: 2026-06-01

## Fragment（片段）

核心数据模型，所有内容以片段形式存储。

### 字段定义

| 字段            | 类型      | 说明                                              |
|-----------------|-----------|---------------------------------------------------|
| `id`            | string    | 片段唯一标识（UUID）                              |
| `content`       | string    | 片段正文内容                                      |
| `content_type`  | enum      | `personal_content` 或 `reference_content`         |
| `subtype`       | string    | 想法 / 日记 / 录音 / 书摘 / 网页 / 文件           |
| `title`         | string?   | 标题（可选，参考内容常用）                        |
| `tags`          | string[]  | 标签列表                                          |
| `source_url`    | string?   | 来源 URL（网页/书摘时使用）                       |
| `created_at`    | ISO 8601  | 创建时间                                          |
| `updated_at`    | ISO 8601  | 最后更新时间                                      |

### content_type 分类规则

```
personal_content  →  💡想法 / ✍日记 / 🎙录音
  用途：AI 反思分析原料，参与记忆偏差检测

reference_content  →  📖书摘 / 🌐网页 / 📎文件
  用途：知识库存储，不参与偏差分析
```

---

## Report（洞察报告）

月度 AI 生成的反思报告。

### 字段定义

| 字段            | 类型      | 说明                          |
|-----------------|-----------|-------------------------------|
| `id`            | string    | 报告唯一标识                  |
| `month`         | string    | 报告月份，格式 `YYYY-MM`      |
| `title`         | string    | 报告标题                      |
| `summary`       | string    | 摘要正文（Markdown）          |
| `session_stats` | object    | 会话统计数据                  |
| `created_at`    | ISO 8601  | 生成时间                      |

---

## ChatSession（对话会话）

| 字段        | 类型     | 说明                                        |
|-------------|----------|---------------------------------------------|
| `id`        | string   | 会话 ID                                     |
| `mode`      | enum     | `普通对话` / `苏格拉底式引导` / `创作辅助`  |
| `title`     | string   | 会话标题（AI 生成或用户编辑）               |
| `messages`  | array    | 消息列表（role: user/assistant + content）  |
| `created_at`| ISO 8601 | 创建时间                                    |

---

## API 端点（后端）

AI 服务使用 DashScope 兼容接口：
- Base URL: `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions`
- Model: `qwen-plus`

### Fragment API

| 方法   | 路由                  | 说明               |
|--------|-----------------------|--------------------|
| POST   | `/fragments`          | 创建片段           |
| GET    | `/fragments`          | 获取片段列表       |
| GET    | `/fragments/:id`      | 获取单个片段       |
| PATCH  | `/fragments/:id`      | 更新片段           |
| DELETE | `/fragments/:id`      | 删除片段           |

### Report API

| 方法 | 路由              | 说明             |
|------|-------------------|------------------|
| GET  | `/reports`        | 获取报告历史列表 |
| POST | `/reports/generate` | 触发生成本月报告 |
| GET  | `/reports/:id`    | 获取报告详情     |

---

## 约定
- 所有时间字段使用 ISO 8601 UTC 格式（`2026-06-01T10:00:00Z`）
- API 请求/响应体均为 JSON，Content-Type: `application/json`
- 分页参数: `?page=1&limit=20`（默认 limit 20）