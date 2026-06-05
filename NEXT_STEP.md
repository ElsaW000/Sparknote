# NEXT STEP for Sparknote

## 当前状态（2026-06-02）

**uni-app 4-Tab 重构：全部页面代码已完成 ✅**

所有 13 个任务已在 Copilot 会话中完成交付。

---

## 已完成

| 文件 | 说明 |
|------|------|
| `pages.json` | 4-Tab 结构（Home / Library / Chat / Me）+ 子页面注册 |
| `src/services/aiService.js` | chatCompletion + buildSystemPrompt + 3 内置导师 |
| `src/services/skillsService.js` | Skills 增删改查（内置开关 + 自定义） |
| `pages/home/index.vue` | 首页：统计卡 + AI Digest + 报告历史入口 |
| `pages/library/index.vue` | 库页：内联捕捉卡 + 碎片列表 |
| `pages/library/editor.vue` | 全屏编辑器（新建 / 编辑，支持 URL 预览） |
| `pages/library/browser.vue` | 全量浏览 + 搜索 + 分类过滤 |
| `pages/chat/index.vue` | 聊天启动页：4 种模式卡 + 历史会话列表 |
| `pages/chat/session.vue` | 全屏对话（导师选择 + AI 流 + 会话持久化） |
| `pages/me/index.vue` | 我的页：用户卡 + 升级 Banner + 设置列表 |
| `pages/me/skills.vue` | Skills 管理：内置开关 + 自定义创建/编辑 |
| `pages/report/list.vue` | 报告历史（按月分组） |
| `pages/report/detail.vue` | 报告详情 + 三档用户反馈 |

---

## 下一步行动

### 立即（本周）
1. **HBuilderX 运行验证**：用 H5 模式跑一遍完整流程
   - 碎片新建 → 编辑 → 浏览
   - Chat 记忆纠偏 → 对话（需后端 `http://127.0.0.1:8000` 启动）
   - Me → Skills 开关
   - Home 报告入口 → 详情
2. **启动后端**：`cd backend && python main.py`（AI 对话需要）
3. **排查 console 错误**：重点看 store import 路径、tabBar 图标路径

### 短期（下周）
4. **tabBar 图标**：替换为正式 SVG/PNG（当前 pages.json 使用文字符号占位）
5. **AI 报告生成**：`pages/chat/session.vue` mode=report 时的报告写入逻辑（当前 AI 回复仅存为消息，未写入 `reports` store）
6. **Home AI Digest**：接通真实 `generateWeeklyDigest()` 逻辑（当前为 mock 文案）

### 已知限制
- 语音录音 / OCR 识图：UI 占位，需后端支持
- 云账号 / 退出登录：当前为本地模式占位
- report 反馈只写 localStorage，未接后端

---
- 更新时间：2026-06-02
- 状态：代码完成，待运行验证
