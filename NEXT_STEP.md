# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**TAG-03 常用标签快捷选择** — 代码已有改动（后端 `TagItem` 结构、`/tags/frequent` 逻辑、前端标签 chips），但尚未提交到 git
- 过去 10 分钟：后端测试持续通过（24 passed），代码有未提交变更（backend/main.py、backend/tests/test_api.py、mobile/lib/pages/notes.dart 有改动）
- 项目无新提交已超过 **45 天**

## 下一步任务
- **提交 TAG-03 相关变更 + 人工验收**
  1. 先将 `backend/main.py`、`backend/tests/test_api.py`、`mobile/lib/pages/notes.dart` 合并提交（或清理后提交）
  2. 人工验收：打开 http://127.0.0.1:8080，走核心流程：登录 → 笔记列表 → 快速输入/长笔记 → 灵感工作台 → 标签 chips 显示 + 点击追加行为
  3. 验收后：通知 Echo 推进 AUTH-05（邮箱验证）或指定新任务
  4. 如决定暂停 Sparknote：告知 Echo 切换其他项目

## 阻塞点与补救
- 阻塞点：TAG-03 代码已有改动但未 commit，导致自动化测试可能与本地运行代码不一致
- 补救动作（Echo 侧）：
  1. 检查未提交变更是否与 TAG-03 功能一致
  2. 如一致：git add + commit，注明"TAG-03 frequent tags"
  3. 重新运行 pytest 验证
  4. 等待 Jie 完成人工验收

## 人工测试
- ✅ TAG-03 后端：TagItem 结构 + /tags/frequent — 代码已改，待提交验证
- ✅ TAG-03 前端：frequent tag chips UI — 代码已改，待提交验证
- ✅ 自动化测试：24 passed（基于 committed 版本）
- ⏳ **人工验收**：常用标签 chips 显示 + 点击追加行为
- ⏳ **人工回归**：桌面端完整功能流

---

## Phase 5 P0 进度总览

| ID | 描述 | 状态 |
|----|------|------|
| AUTH-04 | 注册验证码防刷 | ✅ done |
| AUTH-05 | 邮箱验证 | 待启动（TAG-03 验收后） |
| TAG-03 | 常用标签快捷选择 | ⏳ 代码已改，待提交 + 人工验收 |
| NOTE-07 | 全局搜索 | ✅ done |
| NOTE-08 | 组合筛选过滤 | ✅ done |
| NOTE-09 | 置顶/收藏 | ✅ done |
| NOTE-10 | 模板笔记 | ✅ done |
| CAL-02 | 智能文件夹/保存筛选 | 未开始 |

---

## PRD 视野备忘

当前 MVP 已实现：登录注册 / 笔记 CRUD / 灵感工作台 AI 对话 / 附件上传 / 音频转写 / Notion 配置 / 标签系统 / 热力图日历

PRD 规划的后续功能：知识库导入 / 风格学习 / 角色系统 / 脚本生成 / PRD 生成 / 多角色 Agent

**如果 Jie 决定继续 Sparknote**：建议下一个迭代以「风格学习 + 个性化 Agent」为核心目标，从 PRD 3.2 节展开。

---

**本次更新时间：2026-05-01 12:35 Asia/Shanghai**
