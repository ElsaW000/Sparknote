# Spark Vault — 技术实现方案

状态: Active  
更新时间: 2026-06-02  
作者: Copilot + Jie  
适用版本: P1 MVP（4-Tab uni-app）

---

## 1. 整体架构

```
┌─────────────────────────────────────────────┐
│              uni-app 前端                    │
│  (H5 / 微信小程序 / Android App)             │
│                                             │
│  pages/          ← 纯展示 + 交互            │
│  store/          ← 状态编排（vaultStore）    │
│  services/       ← 领域逻辑 + API 调用       │
└────────────────────┬────────────────────────┘
                     │ HTTP
                     ▼
┌─────────────────────────────────────────────┐
│           FastAPI 后端代理                   │
│  (backend/main.py)                          │
│                                             │
│  POST /v1/chat/completions  ← ⚠️ 待补充     │
│  POST /conversations/...   ← 已有（旧接口） │
│  POST /audio/transcribe    ← 已有           │
└────────────────────┬────────────────────────┘
                     │ HTTPS
                     ▼
         DashScope API (阿里云)
         model: qwen-plus
```

**运行时数据存储：**  
- 所有片段、会话、报告 → `uni.setStorageSync`（本地 localStorage / App 沙箱）  
- 无云端同步（P2 规划中，使用 Supabase）

---

## 2. 前端分层设计

### 2.1 层次职责

| 层 | 目录 | 职责 | 不能做什么 |
|---|---|---|---|
| 页面层 | `pages/` | 渲染 UI、响应用户事件、调用 store | 直接操作存储、直接调 API |
| 状态层 | `src/store/vaultStore.js` | 协调数据 CRUD、维护 derived state（metrics, filtered） | 含 UI 逻辑 |
| 领域逻辑层 | `src/services/vaultLogic.js` | 纯函数（createFragment、filterFragments、computeMetrics…） | 副作用 |
| 数据访问层 | `src/services/vaultRepository.js` | 封装 uni.storage 读写 | 业务判断 |
| AI 服务层 | `src/services/aiService.js` | chatCompletion、buildSystemPrompt、BUILTIN_MENTORS | 状态管理 |
| Skills 层 | `src/services/skillsService.js` | Skills CRUD、内置导师开关 | AI 调用 |

### 2.2 Store API 速查

```js
const store = getVaultStore()   // 单例，页面中 import 后直接使用

// 状态（响应式引用，onShow 后调用 store.refresh() 刷新）
store.state.fragments          // Fragment[]
store.state.filteredFragments  // Fragment[]（按 filters 过滤）
store.state.reports            // Report[]
store.state.sessions           // ChatSession[]
store.state.metrics            // { totalFragments, weeklyNew, chatCount, reportCount }
store.state.weeklyDigest       // string（本地生成的文字摘要）

// Fragment
store.saveFragment(input)          // → { ok, fragment }
store.updateFragment(id, patch)    // → { ok, fragment }
store.deleteFragment(id)           // → { ok }
store.getFragmentById(id)          // → Fragment | undefined

// Session
store.saveSession(input)           // → { ok, session }
store.updateSession(id, patch)     // → { ok, session }
store.deleteSession(id)            // → { ok }
store.getSessionById(id)           // → ChatSession | undefined

// Report
store.getReportById(id)            // → Report | undefined
store.deleteReport(id)             // → { ok }

// Filter (Library tab)
store.updateFilters({ query, chip })
store.refresh()
```

### 2.3 导航规则

| 场景 | 方式 | 示例 |
|---|---|---|
| Tab 间跳转 | `uni.switchTab` | Home → Chat |
| 打开子页 | `uni.navigateTo` | Library → editor |
| 返回 | `uni.navigateBack` | 所有子页返回键 |
| 跨 Tab 传参（如 Home → Chat 指定模式） | `uni.setStorageSync('pending_chat_mode', mode)` 后 switchTab，onShow 读取并清除 | |
| 子页传参 | URL query string `?id=xxx` | report/detail?id=123 |
| 编辑器草稿 | `uni.setStorageSync('editor_draft', {...})` 后 navigateTo `?from=draft` | |

---

## 3. 数据模型

### 3.1 Fragment

```js
{
  id: number,                  // Date.now() + seed，整数
  content: string,             // 正文（必填）
  content_type: 'personal_content' | 'reference_content',
  subtype: '想法'|'日记'|'录音'|'书摘'|'网页'|'文件',
  title: string | null,
  tags: string[],
  source_url: string | null,
  created_at: number,          // Unix timestamp (ms)
  updated_at: number
}
```

**content_type 分类规则：**
- `personal_content`（💡想法 / ✍日记 / 🎙录音）→ AI 分析原料，参与记忆纠偏
- `reference_content`（📖书摘 / 🌐网页 / 📎文件）→ 知识库，不参与偏差分析

### 3.2 ChatSession

```js
{
  id: number,
  mode: 'memory' | 'mentor' | 'writing' | 'report',
  title: string,
  mentorId: string | null,     // e.g. 'inamori', 'munger', 'socrates'
  messages: [
    { role: 'user' | 'assistant', content: string, citation?: string }
  ],
  created_at: number,
  updated_at: number
}
```

### 3.3 Report

```js
{
  id: number,
  title: string,
  month: string,               // 'YYYY-MM'
  type: 'weekly' | 'reflection' | 'report',
  content: string,             // AI 生成正文（Markdown）
  generatedContent: string,    // 同 content（兼容旧字段）
  relatedFragmentIds: number[],
  created_at: number
}
```

### 3.4 Skill（自定义 AI 配置）

```js
{
  id: string,                  // builtin: 'inamori'/'munger'/'socrates'; custom: uuid
  name: string,
  emoji: string,
  desc: string,
  prompt: string,              // 系统 prompt 注入文本
  is_builtin: boolean,
  is_enabled: boolean          // builtin 用；custom 始终 true
}
```

### 3.5 LocalStorage Keys

| Key | 类型 | 说明 |
|---|---|---|
| `spark_vault_fragments` | Fragment[] | 所有碎片 |
| `spark_vault_sessions` | ChatSession[] | 所有会话 |
| `spark_vault_reports` | Report[] | 所有报告 |
| `spark_vault_skills` | Skill[] | 自定义 Skills |
| `spark_vault_builtin_enabled` | `{ inamori: bool, munger: bool, socrates: bool }` | 内置导师开关 |
| `pending_chat_mode` | string | 跨 Tab 传参（临时，读后清除） |
| `editor_draft` | object | 编辑器草稿（临时） |
| `feedback_{reportId}` | object | 报告用户反馈 |

---

## 4. AI 集成方案

### 4.1 当前接口（前端视角）

前端 `aiService.js` 调用：

```
POST ${VITE_API_BASE_URL}/v1/chat/completions
Body: {
  model: 'qwen-plus',
  messages: [ {role, content}, ... ],
  temperature: 0.7,
  max_tokens: 1000
}
Response: OpenAI-compatible format
  .choices[0].message.content → string
```

### 4.2 ⚠️ 关键缺口：后端缺少 `/v1/chat/completions` 代理路由

旧后端（`main.py`）使用 `/conversations/{id}/message`（异步 + 轮询），不暴露 `/v1/chat/completions`。

**修复方案（方案 A，推荐）：** 在 `main.py` 加一个薄代理路由：

```python
from fastapi.responses import JSONResponse
import os, requests

@app.post("/v1/chat/completions")
async def chat_completions_proxy(request: Request):
    """透传代理：前端 → 本后端 → DashScope，解决跨域 + API key 不暴露"""
    body = await request.json()
    dash_key = os.getenv("DASHSCOPE_API_KEY", "")
    if not dash_key:
        raise HTTPException(status_code=503, detail="DASHSCOPE_API_KEY not configured")
    
    resp = requests.post(
        "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {dash_key}",
            "Content-Type": "application/json"
        },
        json=body,
        timeout=60
    )
    return JSONResponse(content=resp.json(), status_code=resp.status_code)
```

**CORS 配置**（已在 main.py 的 CORSMiddleware 里）：确保 `allow_origins` 包含 H5 开发地址（`http://localhost:5173` 等）。

### 4.3 System Prompt 策略（buildSystemPrompt）

| Mode | System Prompt 策略 |
|---|---|
| `memory` | 记忆/认知顾问角色 + 注入前 10 条 `personal_content` 片段 |
| `mentor` | 使用选定 mentor 的 persona prompt + 注入片段上下文 |
| `writing` | 创意写作助手角色 + 注入片段 |
| `report` | 成长分析师角色 + 注入片段（生成结构化报告） |

**注入规则：**
- 只取 `personal_content` 片段（不含 reference_content）
- 最多注入前 10 条，每条截断至 200 字符
- API 发送只取最近 10 条消息（token 控制）

### 4.4 报告写入缺口（⚠️ 待实现）

当前 `mode=report` 的 AI 回复仅存为 ChatSession 消息，**不会自动写入 `store.state.reports`**。

待补充逻辑（在 `session.vue` 的 AI 回复处理后）：

```js
if (this.mode === 'report') {
  store.saveReport({  // store 需要补充 saveReport 方法
    title: `成长报告 · ${new Date().toLocaleDateString()}`,
    content: reply,
    type: 'report',
    relatedFragmentIds: personalFragments.map(f => f.id)
  })
}
```

---

## 5. 页面路由表

### TabBar（pages.json 已配置）

| Tab | 路径 | 说明 |
|---|---|---|
| 🏠 首页 | `pages/home/index` | 统计 + AI Digest + 报告入口 |
| 📚 库 | `pages/library/index` | 内联捕捉 + 碎片列表 |
| 💬 聊 | `pages/chat/index` | 4 种模式 + 历史会话 |
| 👤 我 | `pages/me/index` | 设置 + Skills 入口 |

### 子页面

| 路径 | 入口 | 参数 |
|---|---|---|
| `pages/library/editor` | Library Tab（新建/编辑按钮） | `?id=xxx`（编辑）或无参数（新建）；`?from=draft`（草稿） |
| `pages/library/browser` | Library Tab（≡ 图标） | 无 |
| `pages/chat/session` | Chat Tab（模式卡/历史列表） | `?mode=xxx`（新建）或 `?sessionId=xxx`（续) |
| `pages/me/skills` | Me Tab（个性化行） | 无 |
| `pages/report/list` | Home Tab（报告历史行） | 无 |
| `pages/report/detail` | Report List | `?id=xxx` |

---

## 6. 环境配置

### 前端（`Spark_Vault_uniapp/.env`）

```env
VITE_API_BASE_URL=http://127.0.0.1:8000
```

H5 开发时 vite 会自动代理；打包 App 时需改为后端实际地址。

### 后端（`backend/.env`）

```env
DASHSCOPE_API_KEY=sk-xxxxx
DATABASE_URL=sqlite:///./sparknote.db   # 本地开发
SECRET_KEY=your-jwt-secret
```

---

## 7. 启动方式

### 后端

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
# 或直接：python main.py
```

验证：`GET http://localhost:8000/health` → `{"status": "ok"}`

### 前端（HBuilderX）

1. HBuilderX 打开 `Spark_Vault_uniapp/` 文件夹
2. 运行 → 运行到浏览器（H5 调试）或运行到 Android 模拟器
3. 确认 `.env` 中 `VITE_API_BASE_URL` 指向已启动的后端

---

## 8. 已知缺口与待办（技术视角）

| # | 问题 | 严重度 | 解决方案 | 状态 |
|---|---|---|---|---|
| 1 | 后端缺 `POST /v1/chat/completions` 路由 | 🔴 阻塞 AI 对话 | 见 §4.2，加 30 行代理代码 | ❌ 待做 |
| 2 | `mode=report` 不写入 reports store | 🟡 功能不完整 | 见 §4.4，session.vue + saveReport | ❌ 待做 |
| 3 | store 缺 `saveReport` 方法 | 🟡 | vaultStore.js 补充 | ❌ 待做 |
| 4 | tabBar 图标用 emoji 占位 | 🟢 体验问题 | 替换为 PNG/SVG 资源 | ❌ 待做 |
| 5 | Home Digest 用本地 generateWeeklyDigest（纯文本拼接） | 🟢 | 接通 AI 生成 | ❌ 待做 |
| 6 | 语音录音 / OCR 识图 | 🟢 功能占位 | 需后端 audio/transcribe 接入 | ❌ 远期 |
| 7 | 云账号 / 多设备同步 | 🟢 P2 规划 | Supabase Auth + PostgreSQL | ❌ P2 |

---

## 9. 下一步行动优先级

1. **加后端代理路由**（§4.2）→ AI 对话跑通
2. **HBuilderX H5 运行**，排查 console 错误
3. **补 saveReport + session.vue 写入逻辑**（§4.4）→ 报告功能完整
4. **替换 tabBar 图标** → 视觉达标
5. **端到端验证路径**：新建碎片 → 开启记忆纠偏对话 → 生成报告 → 查看详情 → 提交反馈
