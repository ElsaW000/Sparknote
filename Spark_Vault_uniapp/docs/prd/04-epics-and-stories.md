# Spark Vault Epics & User Stories

> 版本：3.0（4-Tab 重构版）| 更新日期：2026-05-31  
> ⚠️ 旧 Epics（Capture Tab / AI Tab / Workspace / Archive）已废弃，见文末变更记录

---

## Epic 1: 用户认证 (Authentication)

| ID | Story | 验收标准 | 状态 |
|----|-------|----------|------|
| AUTH-01 | 作为新用户，我需要注册账号 | 邮箱+密码注册 → 自动登录 | ✅ 已实现 |
| AUTH-02 | 作为已注册用户，我需要登录 | 邮箱密码登录 → 进入主页 | ✅ 已实现 |
| AUTH-03 | 作为登录用户，我需要退出登录 | Me Tab → 退出 → 回登录页 | ✅ 已实现 |

---

## Epic 2: 碎片收集 (Library Capture)

> 路由：`pages/library/index`（含内联录入）+ `pages/library/editor`（全屏编辑）

| ID | Story | 验收标准 | 状态 |
|----|-------|----------|------|
| LIB-CAP-01 | 作为用户，我需要在 Library 快速录入文字想法 | 顶部 textarea → 保存 → 出现在碎片列表 | 🔨 重构中 |
| LIB-CAP-02 | 作为用户，我需要进入全屏编辑页写长碎片 | 点击 ⤢ 图标 → 进入 editor 页 | ❌ 待开发 |
| LIB-CAP-03 | 作为用户，我需要拍照并 OCR 识别文字 | 📷 按钮 → 拍照 → OCR 识别 → 内联展示识别文字 | ❌ 待开发 |
| LIB-CAP-04 | 作为用户，我需要录音并保存原始音频 | 🎙 按钮 → 录制 → 保存 .m4a → 显示播放条 | ❌ 待开发 |
| LIB-CAP-05 | 作为用户，我需要粘贴网页链接自动解析 | 🌐 按钮 → 输入 URL → 解析标题摘要 → 显示卡片 | ❌ 待开发 |
| LIB-CAP-06 | 作为用户，录音完成后我需要手动归类（个人/参考） | 录音保存后弹出选择：💡 我的想法 / 📖 参考资料 | ❌ 待开发 |
| LIB-CAP-07 | 作为用户，我需要在全屏编辑器内插入图片/录音/链接 | 底部附件行 📷🎙🔗📎 → 内联插入 | ❌ 待开发 |

---

## Epic 3: 碎片库管理 (Library Browser)

> 路由：`pages/library/index`（Tab）+ `pages/library/browser`（全量浏览 S3）

| ID | Story | 验收标准 | 状态 |
|----|-------|----------|------|
| LIB-01 | 作为用户，我需要在 Library Tab 看到碎片列表 | personal / reference chip 筛选 + 时间倒序 | 🔨 重构中 |
| LIB-02 | 作为用户，我需要进入全量碎片浏览页 | 点击 ≡ → browser 页，支持大类/细分/排序筛选 | ❌ 待开发 |
| LIB-03 | 作为用户，我需要搜索碎片 | 全量浏览页顶部 ⌕ → 关键词搜索 | ❌ 待开发 |
| LIB-04 | 作为用户，我需要删除碎片 | 长按或滑动 → 删除确认 | 🔨 重构中 |
| LIB-05 | 作为用户，我需要查看并编辑碎片详情 | 点击碎片 → 进入 editor 页（编辑模式）| ❌ 待开发 |

---

## Epic 4: AI 对话 (Chat Session)

> 路由：`pages/chat/index`（Tab）+ `pages/chat/session`（全屏对话）

| ID | Story | 验收标准 | 状态 |
|----|-------|----------|------|
| CHAT-01 | 作为用户，我需要在 Chat Tab 选择对话模式 | 4 张模式卡（记忆纠偏/导师/创意/自由探索）→ 点击进入 session | ❌ 待开发 |
| CHAT-02 | 作为用户，进入导师模式后我需要选择导师角色 | AI 第一条消息显示角色选择卡（稻盛和夫/芒格/苏格拉底/自定义）| ❌ 待开发 |
| CHAT-03 | 作为用户，我需要与 AI 进行多轮对话 | 气泡式对话 + AI 引用我的碎片作为脚注 | ❌ 待开发 |
| CHAT-04 | 作为用户，AI 进行记忆纠偏时只读取我的个人内容 | AI context 仅包含 personal_content，不包含 reference_content | ❌ 待开发 |
| CHAT-05 | 作为用户，我需要查看历史对话列表 | Chat Tab 下方历史列表，显示模式+预览+时间 | ❌ 待开发 |

---

## Epic 5: 成长报告 (Report)

> 路由：`pages/report/list`（S4）+ `pages/report/generate`（S4b Sheet）+ `pages/report/detail`（S5）

| ID | Story | 验收标准 | 状态 |
|----|-------|----------|------|
| RPT-01 | 作为用户，我需要在 Home Tab 看到最新 AI 周报 | AI 自动生成的成长摘要卡片，可展开 | ❌ 待开发 |
| RPT-02 | 作为用户，我需要查看报告历史列表 | S4 页，按月分组，含报告类型 chip | ❌ 待开发 |
| RPT-03 | 作为用户，我需要手动生成报告 | S4 点击"+ 生成新报告" → S4b Sheet → 选类型/时间/话题 → 开始生成 | ❌ 待开发 |
| RPT-04 | 作为用户，我需要查看报告详情 | S5 页：核心洞察 + 思维模式 + 建议下一步 | ❌ 待开发 |
| RPT-05 | 作为用户，我需要对报告给出反馈 | S5 底部：✅基本准确/⚠️不完全对/🙅没这么严重 + 文字框 | ❌ 待开发 |
| RPT-06 | 作为用户，我需要从报告直接跳转开始对话 | "建议下一步"中的"立即开始这个对话"→ navigateTo chat/session | ❌ 待开发 |

---

## Epic 6: 个性化设置 (Me / Skills)

> 路由：`pages/me/index`（Tab）+ `pages/me/skills`（S6）

| ID | Story | 验收标准 | 状态 |
|----|-------|----------|------|
| ME-01 | 作为用户，我需要查看个人信息和会员状态 | Me Tab 顶部：头像 + 昵称 + 会员状态 | ❌ 待开发 |
| ME-02 | 作为用户，我需要启用/禁用内置导师模板 | Skills 页 → toggle 开关 → 立即生效 | ❌ 待开发 |
| ME-03 | 作为用户，我需要创建自定义 Skill | Skills 页 → + 创建 → 输入名称/图标/prompt → 保存 | ❌ 待开发 |

---

## 优先级规划

### P0（当前阶段必做）

- 4-Tab 导航重构（`pages.json` + tabBar）
- LIB-CAP-01：Library 快速录入
- LIB-01：Library Tab 碎片列表（personal/reference 分类）
- CHAT-01：Chat Tab Session 发起
- CHAT-02/03：全屏对话 + 导师角色选择
- CHAT-04：AI 仅读取 personal_content
- RPT-02/03/04：报告列表 + 生成 + 详情
- RPT-05：用户反馈

### P1（重构完成后）

- LIB-CAP-02~07：全屏编辑 + OCR + 录音 + 链接
- LIB-02/03：全量浏览 + 搜索
- RPT-01：AI 周报自动生成
- RPT-06：报告跳转对话
- ME-01~03：Me Tab 完整实现

---

## 废弃 Epic 记录

| 废弃 Epic | 原因 | 迁移去向 |
|-----------|------|----------|
| Epic 2: Capture Tab | Capture Tab 并入 Library | LIB-CAP-* |
| Epic 4: AI Tab（整理文字） | 旧 AI Tab 重新定位为 Chat | CHAT-* |
| Epic 5: Workspace（生成报告） | Workspace 合并为 Report | RPT-* |
| Epic 6: Archive（报告归档）| 并入 Report | RPT-* |

---

## Epic 1: 用户认证 (User Authentication)

**目标**: 用户能够注册和登录，并选择身份定位

### Stories

| ID | Story | 验收标准 |
|----|-------|----------|
| AUTH-01 | 作为新用户，我需要用邮箱注册，以便创建账号 | 1. 输入邮箱和密码<br>2. 点击注册按钮<br>3. **选择身份定位**（小说/产品/内容/全部）<br>4. 收到注册成功提示<br>5. 自动登录 |
| AUTH-02 | 作为已注册用户，我需要用邮箱密码登录，以便使用产品 | 1. 输入邮箱和密码<br>2. 点击登录按钮<br>3. 成功进入笔记列表页 |
| AUTH-03 | 作为登录用户，我需要退出登录，以便切换账号 | 1. 点击退出按钮<br>2. 返回登录页 |

---

## Epic 2: 片段采集 (Fragment Capture)

**当前实现**：`src/pages/capture/index.vue`

### Stories

| ID | Story | 验收标准 | 当前状态 |
|----|-------|----------|----------|
| CAP-01 | 作为用户，我需要手动输入文字片段，以便记录灵感 | 1. 打开 Capture 页<br>2. 在文本框输入内容<br>3. 点击"Save into Vault Study"<br>4. 片段出现在 Library | ✅ 已实现 |
| CAP-02 | 作为用户，我需要 OCR 预设，以便快速模拟书页/截图录入 | 1. 点击"Book Page OCR"或"Screenshot OCR"<br>2. 表单自动填充<br>3. 点击保存 | ✅ 已实现（模拟） |
| CAP-03 | 作为用户，我需要 AI 自动生成标签和摘要，以便减少手动操作 | 1. 填入原文<br>2. 点击"Generate Tags & Summary"<br>3. 标签和摘要自动填入 | ✅ 已实现（本地 fallback） |
| CAP-04 | 作为用户，我需要填写来源元数据，以便追溯片段出处 | Source Type / Title / Author / Page # / URL | ✅ 已实现 |

---

## Epic 3: 片段库管理 (Library)

**当前实现**：`src/pages/library/`

### Stories

| ID | Story | 验收标准 | 当前状态 |
|----|-------|----------|----------|
| LIB-01 | 作为用户，我需要查看所有片段列表 | 卡片展示原文、标签、摘要、来源 | ✅ 已实现 |
| LIB-02 | 作为用户，我需要搜索片段 | 关键词搜索（原文/标签/作者/来源）| ✅ 已实现 |
| LIB-03 | 作为用户，我需要按来源类型过滤 | 点击 Source chip 过滤 | ✅ 已实现 |
| LIB-04 | 作为用户，我需要按标签过滤 | 点击 Tag chip 过滤 | ✅ 已实现 |
| LIB-05 | 作为用户，我需要收藏/取消收藏片段 | 点击 ♥ 切换收藏状态 | ✅ 已实现 |
| LIB-06 | 作为用户，我需要查看片段详情并编辑 | 点击卡片进入 detail 页，可修改后保存 | ✅ 已实现 |
| LIB-07 | 作为用户，我需要合并多个片段 | 选择 2+ 片段，确认合并，生成新片段 | ✅ 已实现 |
| LIB-08 | 作为用户，我需要删除片段 | 点击 ⌫ 从 Library 移除 | ✅ 已实现 |

---

## Epic 4: AI 整理 (AI Tab)

**当前实现**：`src/pages/ai/index.vue`

### Stories

| ID | Story | 验收标准 | 当前状态 |
|----|-------|----------|----------|
| AI-01 | 作为用户，我需要粘贴文字让 AI 整理（标签/摘要/清洁文本）| 输入文字 → 点"整理✦" → 展示 AI 结果 → 保存到 Library | ✅ 已实现 |
| AI-02 | 作为用户，我需要从 AI 页进入 Workspace | 点击 Workspace 入口卡片 → navigateTo workspace | ✅ 已实现 |

---

## Epic 5: AI 工作台 (Workspace)

**当前实现**：`src/pages/workspace/`

### Stories

| ID | Story | 验收标准 | 当前状态 |
|----|-------|----------|----------|
| WS-01 | 作为用户，我需要输入创作方向让 AI 合成报告 | 输入 prompt + 选报告类型 → 生成内容 | ✅ 已实现 |
| WS-02 | 作为用户，我需要查看报告引用了哪些片段 | 点"View Vault References" → references 页 | ✅ 已实现 |
| WS-03 | 作为用户，我需要查看合成结果详情 | 报告存入 archive 后可在 result 页查看 | ✅ 已实现 |

---

## Epic 6: 报告归档 (Archive)

**当前实现**：`src/pages/archive/`

### Stories

| ID | Story | 验收标准 | 当前状态 |
|----|-------|----------|----------|
| ARC-01 | 作为用户，我需要查看历史报告列表 | Archive 页展示所有已保存报告 | ✅ 已实现 |
| ARC-02 | 作为用户，我需要查看报告详情 | 点击报告 → navigateTo report-detail | ✅ 已实现 |
| ARC-03 | 作为用户，我需要删除不需要的报告 | 点 × 删除，更新列表 | ✅ 已实现 |

---

## 优先级（当前 uni-app 阶段）

### P0 已完成

- CAP-01 ~ CAP-04：片段采集
- LIB-01 ~ LIB-08：片段库管理
- AI-01 ~ AI-02：AI 整理
- WS-01 ~ WS-03：AI 工作台
- ARC-01 ~ ARC-03：报告归档

### P1 计划中（M4）

- 后端 DashScope AI 接入（替换本地 fallback）
- 用户登录 / 云端数据同步（P2）

---

*Source: current docs PRD set | 更新至 uni-app 当前实现状态*
