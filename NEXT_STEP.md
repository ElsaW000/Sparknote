# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**Phase 5 完成，Phase 6 未启动** — 近 10 分钟无代码变更，项目处于等待状态。

## 下一步任务
- **等待 Jie 确认 Phase 6 第一个任务**：
  - 通过 TBC issue 或直接消息分配具体 P0 任务给 Echo；
  - 或确认从哪个功能故事开始实现（推荐从 `AUTH-04` 注册验证码防刷或 `NOTE-07` 全局搜索开始）。
- P0 功能清单（Phase 6 可选起点）：
  1. `AUTH-04` 注册验证码防刷（Cloudflare Turnstile）
  2. `AUTH-05` 邮箱验证
  3. `TAG-03` 常用标签快捷选择
  4. `NOTE-07` 全局搜索（标题+正文+标签）
  5. `NOTE-08` 组合筛选（标签+日期）
  6. `NOTE-09` 置顶/收藏
  7. `NOTE-10` 模板创建笔记
  8. `CAL-02` 智能文件夹/保存筛选

## 阻塞点与补救
- 阻塞点：Phase 6 无 TBC issue 分配，无具体任务指令。
- 补救动作：Jie 通过 `tbc-db.py issue-create` 分配第一个 P0 任务，或直接发消息给 Echo 指定起点。

## 技术状态
- Backend：pytest 18+ passed，FastAPI 正常运行
- Mobile：Flutter Web 可构建，MVP 功能已实现
- PRD：`PRD/phases/05-feature-benchmark-and-prd-expansion.md` 有 8 个 P0 功能故事可直接开发
- Git：近 10 分钟无代码变更（仅 NEXT_STEP.md 自身更新）

## 人工测试
- MVP 基础功能已就绪，**等待 Jie 确认 Phase 6 启动方向**。

---
_NEXT_STEP.md updated by cron at 2026-05-08 12:06 (Asia/Shanghai)_
