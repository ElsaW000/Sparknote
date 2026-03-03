# Sparknote Architecture Document

## 1. System Overview

### 1.1 Architecture Pattern

**Client-Server Architecture** with RESTful API

```
┌─────────────┐         ┌─────────────┐
│   Flutter   │  <--->   │   FastAPI   │
│   Mobile   │  HTTP    │   Backend   │
└─────────────┘         └─────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
              ┌─────▼─────┐      ┌──────▼──────┐
              │  SQLite   │      │ DashScope   │
              │  (Data)   │      │    (AI)     │
              └───────────┘      └─────────────┘
```

---

## 2. Component Design

### 2.1 Frontend (Flutter Mobile)

| 模块 | 职责 |
|------|------|
| `lib/pages/login.dart` | 登录/注册页面 |
| `lib/pages/notes.dart` | 笔记列表页 |
| `lib/pages/note_detail.dart` | 笔记详情页 |
| `lib/pages/chat.dart` | 对话页 |
| `lib/services/api.dart` | API调用封装 |
| `lib/services/auth.dart` | 认证管理 |

### 2.2 Backend (FastAPI)

| 模块 | 职责 | 文件 |
|------|------|------|
| Auth | 用户认证 | `backend/main.py` |
| Notes | 笔记CRUD | `backend/main.py` |
| AI | AI功能调用 | `backend/ai_provider.py` |
| Worker | 异步AI处理 | `backend/ai_worker.py` |

### 2.3 Database Schema

```sql
-- Users表
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notes表
CREATE TABLE notes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR(255),
    content TEXT,
    tags TEXT,  -- JSON array
    ai_summary TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Conversations表
CREATE TABLE conversations (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Messages表
CREATE TABLE messages (
    id INTEGER PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    role VARCHAR(20) NOT NULL,  -- 'user' or 'assistant'
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id)
);
```

---

## 3. API Endpoints

### 3.1 Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register new user |
| POST | `/auth/login` | Login and get token |

### 3.2 Notes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notes` | List all notes |
| POST | `/notes` | Create new note |
| GET | `/notes/{id}` | Get note by ID |
| PUT | `/notes/{id}` | Update note |
| DELETE | `/notes/{id}` | Delete note |
| POST | `/notes/{id}/summarize` | AI summarize note |
| POST | `/notes/{id}/continue` | AI continue writing |

### 3.3 Conversations

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/conversations` | List conversations |
| POST | `/conversations` | Create conversation |
| GET | `/conversations/{id}/messages` | Get messages |
| POST | `/conversations/{id}/messages` | Send message |

---

## 4. AI Integration

### 4.1 AI Provider (DashScope)

```python
# backend/ai_provider.py
class AIProvider:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.model = "qwen-turbo"
    
    def summarize(self, text: str) -> str:
        # 调用AI总结文本
        pass
    
    def chat(self, messages: list) -> str:
        # 调用AI对话
        pass
```

### 4.2 Async Worker

```python
# backend/ai_worker.py
# 后台异步处理AI任务
# 避免阻塞主请求
```

---

## 5. Security

### 5.1 Authentication

- JWT Token (Bearer Token)
- Token过期时间: 24小时

### 5.2 Data Isolation

- 每个用户只能访问自己的笔记
- API层验证user_id

### 5.3 Password Security

- 使用 `pbkdf2_sha256` 加密
- 不存储明文密码

---

## 6. Deployment

### 6.1 Development

```bash
# Backend
cd backend
source .venv/bin/activate
uvicorn main:app --reload

# Frontend
cd mobile
flutter run
```

### 6.2 Production (To be decided)

- Backend: Docker + Cloud Run / Railway / Render
- Database: Supabase (PostgreSQL)
- CDN: CloudFlare

---

## 7. Future Considerations

- [ ] Web端支持
- [ ] 实时同步 (WebSocket)
- [ ] 多语言支持
- [ ] 导出功能 (PDF, Markdown)

---

*Created: 2026-03-01*
*Method: BMad Method - /create-architecture*
