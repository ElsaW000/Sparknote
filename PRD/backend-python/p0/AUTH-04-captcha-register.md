# AUTH-04 注册验证码防刷

## 用户故事

作为新用户，我希望注册时通过验证码校验，防止机器人滥用接口。

## 验收标准

- 注册页显示验证码组件
- 后端在 `POST /auth/register` 校验验证码 token
- 校验失败返回 400，前端提示"验证码验证失败"

## API 设计

### 修改: POST /auth/register

**Request**

新增字段:
- `captcha_token: str` (required) — Turnstile/hCaptcha server-side token

**Response**

新增 error case:
- `400 {"error": "invalid_captcha", "message": "验证码验证失败"}`

### 后端实现要点

- 依赖: `turnstile` 或 `hcaptcha` Python SDK
- 环境变量: `TURNSTILE_SECRET_KEY` / `HCAPTCHA_SECRET_KEY`
- 验证函数: `verify_captcha(token: str, ip: str = None) -> bool`
- 验证在密码强度检查之前进行，fail-fast

### 数据库变更

- 无新表

### 前端配合

- 在注册表单嵌入 Turnstile widget (site key from `GET /auth/captcha-config`)
- 提交时带上 `widget_response` token
