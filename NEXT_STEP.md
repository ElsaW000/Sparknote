# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**Phase 5 P0 规格拆解 — 已完成**

## 下一步任务
- **从 Phase 5 P0 中选一个开始实现**（推荐顺序）：
  1. `NOTE-07` 全局搜索 — 低依赖，独立实现
  2. `NOTE-09` 置顶/收藏 — 数据库加字段即可
  3. `NOTE-10` 模板创建笔记 — 需建表，逻辑简单
  4. `AUTH-04` 注册验证码 — 需接入第三方服务，稍复杂
- **建议从 `NOTE-07` 全局搜索开始**，原因是：用户体验提升明显、实现路径清晰、无外部依赖

## 阻塞点与补救
- 阻塞点：无（规格已就绪，可直接开工）
- 补救动作：无需补救，等待 Jie 确认从哪个 story 开始

## 人工测试
- MVP 核心功能 ✅ 已完成并通过测试
- Phase 5 功能 ❌ 未开始实现
- **等待 Jie 确认从哪个 P0 story 开始实现**

---

## 项目快照（2026-04-30 13:05）
- MVP 核心功能 ✅ 已完成
- Phase 5 benchmark PRD ✅ 已生成（8 P0 stories）
- Phase 5 P0 实施规格 ✅ **本次已完成 — 8/8 specs 输出到 `PRD/backend-python/p0/`**
- Phase 5 P0 实现 ❌ 未开始
- DEVLOG 最近条目：2026-03-18（静默 6 周）
- 最后人工指令：多轮 cron 无响应

## Phase 5 P0 规格文件（本次输出）
| ID | 规格文件 |
|----|---------|
| AUTH-04 | `PRD/backend-python/p0/AUTH-04-captcha-register.md` |
| AUTH-05 | `PRD/backend-python/p0/AUTH-05-email-verify.md` |
| TAG-03 | `PRD/backend-python/p0/TAG-03-frequent-tags.md` |
| NOTE-07 | `PRD/backend-python/p0/NOTE-07-global-search.md` |
| NOTE-08 | `PRD/backend-python/p0/NOTE-08-filter-combination.md` |
| NOTE-09 | `PRD/backend-python/p0/NOTE-09-pin-favorite.md` |
| NOTE-10 | `PRD/backend-python/p0/NOTE-10-template-notes.md` |
| CAL-02 | `PRD/backend-python/p0/CAL-02-smart-folder.md` |

## 参考文档
- Phase 5 benchmark: `PRD/phases/05-feature-benchmark-and-prd-expansion.md`
- Phase 5 index: `PRD/phases/00-index.md`
- P0 目录: `PRD/backend-python/p0/`
- 最后更新：2026-04-30 13:05 (Asia/Shanghai)
