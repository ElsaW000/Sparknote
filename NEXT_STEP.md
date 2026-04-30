# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：NOTE-08 backend 已提交，frontend 筛选 UI 尚未开始

## 下一步任务
- **实现 NOTE-08 前端筛选 UI**：在 `mobile/lib/pages/notes.dart` 中为笔记列表添加组合筛选功能
  - 参数：tag_ids（多选标签，拼接为逗号分隔）、date_from / date_to（日期范围）、sort（updated_at/created_at/pinned）、order（asc/desc）、match（all/any）
  - 调用 `GET /notes?tag_ids=&date_from=&date_to=&sort=&order=&match=`
  - UI 形式建议：BottomSheet 或 ExpandableFilterBar

## 阻塞点与补救
- 阻塞点：NOTE-08 frontend 筛选 UI 完全没有实现
- 补救动作：
  1. 参考 `mobile/lib/pages/notes.dart` 现有列表 UI 结构
  2. 添加筛选 BottomSheet/FilterBar，包含：标签多选、日期范围选择器、排序方式选择
  3. 将筛选参数追加到 notes API 调用中
  4. 筛选条件变化后刷新笔记列表

## 人工测试
- 等待 NOTE-08 frontend 实现后进行端到端人工测试

---

## Phase 5 P0 进度总览

| ID | 描述 | 实现 | 状态 |
|----|------|------|------|
| AUTH-04 | 认证令牌刷新 | backend | 未完成 |
| AUTH-05 | 刷新令牌机制 | backend | 未完成 |
| TAG-03 | 批量标签管理 | — | 未认领 |
| NOTE-07 | 笔记复制/移动 | ✅ | ✅ 已完成 |
| NOTE-08 | 组合筛选过滤 | ✅ backend 已提交 | 🔄 frontend 未开始 |
| NOTE-09 | 置顶/排序视图 | ✅ | ✅ 已完成 |
| NOTE-10 | 模板笔记 | ✅ | ✅ 已完成 |
| CAL-02 | 日历到期提醒 | — | 未认领 |

## 本次操作记录（生成时间：2026-04-30 18:15 Asia/Shanghai）

- git commit backend/main.py — NOTE-08 backend 已提交 ✅ (2bb484c)
- NOTE-08 frontend UI 尚未开始实现
