# Sparknote Backend

当前后端已覆盖 Sparknote MVP 的主要接口，不再只是最小原型。

## 已实现接口能力

### 基础
- `GET /health`
- `GET /debug/ai`

### 认证
- `GET /auth/captcha`
- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`

### 笔记
- `POST /notes`
- `GET /notes`
- `GET /notes/{note_id}`
- `PATCH /notes/{note_id}`
- `DELETE /notes/{note_id}`

附加能力：
- `GET /notes?tag=`
- `GET /notes?q=`
- `GET /notes?since=`
- 自动提取正文中的 `#hashtag`

### 标签与关系
- `GET /tags/suggest`
- `GET /notes/{note_id}/related`
- `POST /notes/{note_id}/relations`
- `DELETE /notes/{note_id}/relations/{relation_id}`

### 统计与回顾
- `GET /stats/heatmap`
- `GET /review/daily`

### AI 工作流
- `POST /conversations`
- `POST /conversations/{id}/message`
- `GET /conversations/{id}/messages`
- `POST /conversations/{id}/close`

说明：
- 用户消息进入后台任务队列
- 前端通过轮询消息列表获取 AI 回复
- 关闭会话时会生成总结笔记

### 附件与音频
- `GET /notes/{note_id}/attachments`
- `POST /notes/{note_id}/attachments`
- `POST /audio/transcribe`
- `/uploads/...` 静态文件访问

### 洞察与集成
- `GET /insights/perspectives`
- `POST /insights/run`
- `GET /insights/history`
- `GET /integrations/notion`
- `PUT /integrations/notion`

### 商业化占位
- `GET /me/subscription`
- `POST /billing/checkout`

## 当前验证结果

2026-03-16：

- 运行：`PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 .\.venv\Scripts\python.exe -m pytest backend\tests -q`
- 结果：`17 passed`
- 说明：中文 hashtag 自动提取回归已修复

## 本地启动

```bash
python -m pip install -r backend/requirements.txt
uvicorn backend.main:app --reload --port 8000
```

## 环境变量

- `DATABASE_URL`
- `JWT_SECRET_KEY`
- `ACCESS_TOKEN_EXPIRE_MINUTES`
- `REQUIRE_REGISTER_CAPTCHA`
- `REGISTER_CAPTCHA_TTL_SECONDS`
- `DASHSCOPE_API_KEY` / `DASHSCOPE`
- `DASHSCOPE_URL`
- `DASHSCOPE_ASR_MODEL`
- `OPENAI_API_KEY`

## 已知限制

- 外部 AI 服务不可用时会回退到 mock / 错误兜底内容
- 总结与回复不是流式
- 上传文件目前保存在本地 `uploads/`
