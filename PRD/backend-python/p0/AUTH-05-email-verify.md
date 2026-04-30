# AUTH-05 邮箱验证

## 用户故事

作为新用户，我希望完成邮箱验证后再使用核心功能。

## 验收标准

- 注册成功后触发验证邮件
- 未验证账号登录后提示"请先验证邮箱"
- 验证完成后可正常登录

## API 设计

### 新增: POST /auth/request-verification

**Request**: `{"email": "user@example.com"}`

**Response**: `200 {"message": "verification sent"}`

**Logic**:
- 生成 6 位数字 code，6 小时内有效
- 存 `email_verification` 表 (email, code, expires_at, used)
- 发送邮件（code 明文或链接含 code）

### 新增: POST /auth/verify-email

**Request**: `{"email": "user@example.com", "code": "123456"}`

**Response**: `200 {"message": "email verified"}`

**Error**: `400 {"error": "invalid_code"}`

### 修改: POST /auth/login

**Response**

新增:
- 若账号已注册但未验证: `403 {"error": "email_not_verified", "message": "请先验证邮箱"}`

### 修改: GET /notes (及其他受保护接口)

**Response**

新增:
- 未验证账号访问时: `403 {"error": "email_not_verified"}`

### 数据库变更

```sql
CREATE TABLE email_verifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL,
    code TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Add index on (email, code) for fast lookup
```

### 用户表变更

```sql
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
```

### 前端配合

- 登录后检测到 `email_not_verified` → 跳转邮箱验证引导页
- 注册成功后 → 跳转"请去邮箱验证"提示页
- 提供"重新发送验证码"按钮（限流：1次/分钟）
