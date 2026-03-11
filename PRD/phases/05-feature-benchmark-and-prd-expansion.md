# Sparknote PRD 扩展（官方功能对标）

## 1) 对标范围与结论

本次对标基于官方文档（Notion / Evernote / Apple Notes / Obsidian / Cloudflare / Firebase），共提炼出 **22 个可落地功能点**：

- `P0（本阶段应补齐）`: 8 项
- `P1（下一阶段）`: 9 项
- `P2（增强项）`: 5 项

---

## 2) 官方功能证据（来源）

- Notion 数据库属性（多选标签、可直接新建标签）
  - https://www.notion.com/help/database-properties
- Notion 数据库模板（可复用结构）
  - https://www.notion.com/help/database-templates
- Evernote 过滤（按标签/创建时间/更新时间）
  - https://help.evernote.com/hc/en-us/articles/360050105293-Filter-your-notes-list
- Evernote 嵌套标签
  - https://help.evernote.com/hc/en-us/articles/4412905761299-Create-nested-tags
- Apple Notes 标签与智能文件夹（按标签/时间等过滤）
  - https://support.apple.com/en-mt/102288
  - https://support.apple.com/en-mide/guide/notes/apd58edc7964/mac
- Obsidian 核心插件（Daily Notes、Backlinks、Search、Tags）
  - https://help.obsidian.md/plugins
  - https://help.obsidian.md/plugins/daily-notes
- Cloudflare Turnstile（登录/注册表单保护，服务端校验 token）
  - https://developers.cloudflare.com/turnstile/tutorials/login-pages/
- Firebase Auth 邮箱验证
  - https://firebase.google.com/docs/auth/web/manage-users

---

## 3) 功能差距清单（Gap List）

### A. 认证与安全

1. 注册防刷验证码（Turnstile/hCaptcha）
2. 邮箱验证（注册后需验证再进入核心功能）
3. 密码找回（邮件重置）
4. 登录失败防爆破（限流/冷却）

### B. 笔记输入与组织

5. 模板化新建笔记（会议纪要/灵感卡片/复盘）
6. 日记/每日笔记入口（Daily Note）
7. 常用标签快捷选择（最近使用 + 高频）
8. 标签管理页（重命名/合并/删除）
9. 标签层级（父标签/子标签，P2）
10. 收藏/置顶笔记

### C. 检索与筛选

11. 全局搜索（标题+正文+标签）
12. 组合筛选（标签/创建日期/更新时间）
13. 保存筛选视图（类似智能文件夹）
14. 空标签/无标签快速筛选

### D. 关联与结构化

15. 反向链接（Backlinks）
16. 引用关系可视化（P2）
17. 笔记属性扩展（状态、优先级、来源）

### E. 协作与可靠性

18. 导入（从 Markdown / 其他笔记工具）
19. 版本恢复（最近编辑快照）
20. 多端同步冲突提示
21. 附件/图片 OCR（P2）
22. 语音记录转写（P2）

---

## 4) 建议纳入 PRD 的新增 Stories（可直接开发）

## P0（建议立即进入开发）

### AUTH-04 注册验证码防刷

- 用户故事：作为新用户，我希望注册时通过验证码校验，防止机器人滥用接口。
- 验收标准：
  - 注册页显示验证码组件。
  - 后端在 `/auth/register` 校验验证码 token。
  - 校验失败返回 400，前端提示“验证码验证失败”。

### AUTH-05 邮箱验证

- 用户故事：作为新用户，我希望完成邮箱验证后再使用核心功能。
- 验收标准：
  - 注册成功后触发验证邮件。
  - 未验证账号登录后提示“请先验证邮箱”。
  - 验证完成后可正常登录。

### TAG-03 常用标签快捷选择 + 自定义新增

- 用户故事：作为用户，我希望编辑笔记时可点选常用标签，也可手动新增。
- 验收标准：
  - 编辑器显示“最近使用/高频标签”。
  - 点击标签可一键添加到笔记。
  - 输入新标签回车可创建并选中。

### NOTE-07 全局搜索

- 用户故事：作为用户，我希望按关键词快速找到历史笔记。
- 验收标准：
  - 支持标题/内容/标签检索。
  - 搜索结果按更新时间倒序。
  - 空结果显示明确提示。

### NOTE-08 组合筛选（标签+日期）

- 用户故事：作为用户，我希望按标签和日期范围过滤笔记。
- 验收标准：
  - 支持多标签组合筛选。
  - 支持创建日期范围筛选。
  - URL 或本地状态保留当前筛选条件。

### NOTE-09 置顶/收藏

- 用户故事：作为用户，我希望把重要笔记置顶方便回看。
- 验收标准：
  - 列表区分“置顶”和“普通”。
  - 可随时取消置顶。

### NOTE-10 模板创建笔记

- 用户故事：作为用户，我希望用模板快速创建结构化笔记。
- 验收标准：
  - 提供至少 3 个模板（灵感、会议、复盘）。
  - 模板可预填字段（标题/标签/结构块）。

### CAL-02 智能文件夹/保存筛选

- 用户故事：作为用户，我希望保存一组筛选条件，下次一键查看。
- 验收标准：
  - 可保存筛选条件并命名。
  - 支持编辑与删除保存筛选。

---

## 5) 下一阶段（P1）建议

- `AUTH-06` 忘记密码与邮件重置
- `TAG-04` 标签管理页（重命名/合并）
- `NOTE-11` 最近编辑历史与回滚
- `NOTE-12` 导入 Markdown
- `LINK-01` 反向链接
- `LINK-02` 关联笔记推荐
- `AI-04` OCR 提取图片文字（先离线/后云端）
- `AI-05` 语音转写
- `SYNC-01` 多端冲突提示

---

## 6) 说明

- 上述清单是“官方能力的可执行抽象”，不是逐字照搬。
- 实施时建议先做 `P0` 的 8 项，把“可用性 + 可找回 + 可组织”打牢，再推进 AI 增强项。
