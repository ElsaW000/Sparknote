# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：NOTE-10 模板笔记前端实现 — **⏳ 未开始（后端刚完成）**

## 下一步任务
- **实现 NOTE-10 前端入口：模板选择弹窗 + 预览 + 创建笔记**

## 阻塞点与补救
- 阻塞点：无（后端刚完成，24 tests passed）
- 补救动作：
  1. 在 Flutter 笔记页面添加"从模板创建"入口按钮（FloatingActionButton 附近）
  2. 实现模板选择弹窗（展示 3 个模板：会议纪要、灵感卡片、复盘）
  3. 调用 `GET /templates` 获取模板列表（需 Bearer token）
  4. 点击模板后调用 `POST /templates/preview` 预览展开效果
  5. 确认后调用 `POST /notes`（带 `template_id` 和 `template_variables`）创建笔记

## 实现步骤（按顺序）
1. ~~数据库 — 新建 `templates` 表（seed 3 个模板）~~ ✅
2. ~~后端 API — `GET /templates`、`POST /templates/preview`、`POST /notes` 支持 `template_id`~~ ✅（commit 8fe67a4，24 passed）
3. **前端入口 — "新建笔记"按钮旁加"从模板创建"入口，模板选择弹窗，预览后再创建** ⏳ ← 当前
4. Flutter build 验证

## 规格参考
- `PRD/backend-python/p0/NOTE-10-template-notes.md`
- 后端实现：`backend/main.py`（`_seed_templates`、`GET /templates`、`POST /templates/preview`、`_apply_template_to_note`）

## 人工测试
- MVP 核心功能 ✅ 已完成
- Phase 5 P0 规格 ✅ 已完成（8/8 specs）
- NOTE-07 全局搜索 ✅ 已完成
- NOTE-09 置顶/收藏 ✅ 已完成
- NOTE-10 模板笔记 — 后端 ✅ / 前端 ⏳ **当前**
- NOTE-10 前端完成后需人工体验完整流程

---

## Phase 5 P0 实现进度
| ID | 功能 | 规格 | 实现 |
|----|------|------|------|
| AUTH-04 | 注册验证码 | ✅ | ❌ 未开始 |
| AUTH-05 | 邮箱验证 | ✅ | ❌ 未开始 |
| TAG-03 | 常用标签 | ✅ | ❌ 未开始 |
| **NOTE-07** | **全局搜索** | ✅ | **✅ 已完成** |
| NOTE-08 | 组合筛选 | ✅ | ❌ 未开始（依赖 NOTE-07） |
| **NOTE-09** | **置顶/收藏** | ✅ | **✅ 已完成** |
| **NOTE-10** | **模板笔记** | ✅ | **⏳ 前端** |
| CAL-02 | 智能文件夹 | ✅ | ❌ 未开始 |

## 推荐实现顺序
1. ~~`NOTE-07` 全局搜索~~ — ✅ 已完成
2. ~~`NOTE-09` 置顶/收藏~~ — ✅ 已完成
3. `NOTE-10` 模板笔记 — ⏳ 前端实现中（后端已完）
4. `NOTE-08` 组合筛选 — 依赖 NOTE-07 完成
5. `AUTH-04` 注册验证码 — 需接入第三方服务，稍复杂

## 参考文档
- Phase 5 benchmark: `PRD/phases/05-feature-benchmark-and-prd-expansion.md`
- Phase 5 index: `PRD/phases/00-index.md`
- P0 目录: `PRD/backend-python/p0/`
- 最后更新：2026-04-30 14:45 (Asia/Shanghai)
