# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：NOTE-10 模板笔记 — **✅ 已完成（frontend build 验证通过 + commit 903a4bf）**

## 下一步任务
- **开始实现 NOTE-08 组合筛选（依赖 NOTE-07 全局搜索，已完成）**
  - 规格：`PRD/backend-python/p0/NOTE-08.md`
  - 预期工作：
    - 后端：扩展 `GET /notes/search` 支持多条件组合（时间范围 + 标签 + 关键词 + 排序）
    - 前端：在笔记列表页面添加筛选栏（日期范围选择器、标签多选、排序选项）
    - API 测试覆盖

## 阻塞点与补救
- 阻塞点：无
- 补救动作：无

## 已完成的工作
- ✅ NOTE-07 全局搜索（commit 724b3c4）
- ✅ NOTE-09 置顶/收藏（commit 4b83393）
- ✅ NOTE-10 模板笔记：
  - 后端（commit 8fe67a4）：`GET /templates`、`POST /templates/preview`、`POST /notes` 支持 `template_id`
  - 前端（commit 903a4bf）：`_openTemplateSelector()`、预览弹窗、编辑器预填充、`FAB` 双按钮

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
4. `NOTE-08` 组合筛选 — 🔄 下一步
5. `TAG-03` 常用标签 — 相对独立
6. `AUTH-04/05` 注册验证码/邮箱验证 — 需第三方服务，排在靠后

## 参考文档
- Phase 5 benchmark: `PRD/phases/05-feature-benchmark-and-prd-expansion.md`
- Phase 5 index: `PRD/phases/00-index.md`
- P0 目录: `PRD/backend-python/p0/`
- NOTE-08 规格: `PRD/backend-python/p0/NOTE-08.md`
- 最后更新：2026-04-30 16:15 (Asia/Shanghai)
