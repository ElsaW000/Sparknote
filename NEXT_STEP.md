# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：NOTE-08 组合筛选 — **🔄 未开始（上次 cron 后 ~50 分钟仍无新 commit，距上次 16:15 已超 30 分钟）**

## 下一步任务
- **开始实现 NOTE-08 组合筛选（backend 优先）**
  1. 后端 `GET /notes` 新增 query params：`tag_ids`, `date_from`, `date_to`, `sort`, `order`, `match`
  2. SQL WHERE/HAVING 组装（`INNER JOIN` + `HAVING COUNT(DISTINCT tag_id)` 全匹配；`IN` 任一匹配）
  3. 索引（`idx_notes_user_created`）
  4. pytest 覆盖
  5. 前端筛选面板（Flutter notes.dart 侧边栏，标签多选 + 日期范围，URL sync + localStorage）

## 阻塞点与补救
- 阻塞点：无阻塞，规格清晰 NOTE-07 参考可用
- 补救动作：
  1. `backend/main.py` — `GET /notes` 添加 query params 解析（tag_ids, date_from, date_to, sort, order, match）
  2. SQL query 组装（INNER JOIN note_tags 做标签筛选，HAVING COUNT 做全/任一匹配）
  3. 运行 pytest 确认不破坏现有测试
  4. Flutter 侧边栏筛选面板（参考 NOTE-07 搜索的实现模式）

## Phase 5 P0 实现进度
| ID | 功能 | 规格 | 实现 |
|----|------|------|------|
| AUTH-04 | 注册验证码 | ✅ | ❌ 未开始 |
| AUTH-05 | 邮箱验证 | ✅ | ❌ 未开始 |
| TAG-03 | 常用标签 | ✅ | ❌ 未开始 |
| **NOTE-07** | **全局搜索** | ✅ | **✅ 已完成** |
| **NOTE-08** | **组合筛选** | ✅ | **🔄 下一步** |
| **NOTE-09** | **置顶/收藏** | ✅ | **✅ 已完成** |
| **NOTE-10** | **模板笔记** | ✅ | **✅ 已完成** |
| CAL-02 | 智能文件夹 | ✅ | ❌ 未开始 |

## 推荐实现顺序
1. ~~`NOTE-07` 全局搜索~~ — ✅ 已完成
2. ~~`NOTE-09` 置顶/收藏~~ — ✅ 已完成
3. ~~`NOTE-10` 模板笔记~~ — ✅ 已完成
4. `NOTE-08` 组合筛选 — 🔄 **下一步（backend 先开）**
5. `TAG-03` 常用标签 — 相对独立
6. `AUTH-04/05` 注册验证码/邮箱验证 — 需第三方服务，排在靠后

## 参考文档
- NOTE-08 规格: `PRD/backend-python/p0/NOTE-08-filter-combination.md`
- NOTE-07 参考: `PRD/backend-python/p0/NOTE-07-global-search.md`（实现模式可复用）
- 最后更新：2026-04-30 17:05 (Asia/Shanghai)
