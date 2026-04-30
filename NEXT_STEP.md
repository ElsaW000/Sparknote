# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**Phase 1 整体暂停，等待 Jie 明确优先级方向**

## 下一步任务
- 等待 Jie 确认 Phase 1 的任务方向（两个可选方向）：
  1. **Phase 1A**：将 Phase 5 benchmark PRD 中 8 个 P0 stories 逐条写出实现规格（backend + frontend 接口定义），交付给 AI-O Agent 作为开发输入
  2. **Phase 1B**：从 8 个 P0 中选一个最先可落地的功能直接开始实现（建议从 NOTE-07 全局搜索或 AUTH-04 注册验证码开始）

## 阻塞点与补救
- 阻塞点：Phase 5 benchmark PRD（2026-04-25）已完成，包含 8 个 P0 stories（AUTH-04/AUTH-05/TAG-03/NOTE-07/NOTE-08/NOTE-09/NOTE-10/CAL-02），但尚未拆解为可执行的技术规格和实现步骤
- 补救动作：
  1. **建议 Jie 优先推进 Phase 1A**——Echo 将 8 个 P0 stories 逐条拆解为接口定义、数据模型、验收标准，输出到 `PRD/backend-python/p0/` 目录
  2. 规格确认后，AI-O Agent 可直接按规格开发，无需反复确认边界
  3. 或者 Jie 指定 Phase 1B，Echo 直接选一个功能动手实现

## 人工测试
- 无新功能待测试（Phase 5 功能尚未开始实现）

---

## 项目当前阶段快照
- MVP 核心功能（登录/笔记/标签/AI对话/附件/音频转写）✅ 已完成
- Phase 5 benchmark PRD ✅ 已生成（8 P0 stories）
- Phase 5 P0 实施规格 ❌ 未开始
- git 状态（2026-04-30 10:35）：无新代码变更（最近10分钟仅 cron NEXT_STEP 定时更新）

## 8 个 P0 Stories 快速清单（Phase 5 benchmark）
1. `AUTH-04` 注册验证码防刷
2. `AUTH-05` 邮箱验证
3. `TAG-03` 常用标签快捷选择 + 自定义新增
4. `NOTE-07` 全局搜索
5. `NOTE-08` 组合筛选（标签+日期）
6. `NOTE-09` 置顶/收藏
7. `NOTE-10` 模板创建笔记
8. `CAL-02` 智能文件夹/保存筛选

## 参考文档
- Phase 5 benchmark: `PRD/phases/05-feature-benchmark-and-prd-expansion.md`
- Phase 5 index: `PRD/phases/00-index.md`
- P0 目录: `PRD/backend-python/p0/`（现有内容为旧版，新 Phase 5 P0 尚未填充）
- 最后更新：2026-04-30 10:35 (Asia/Shanghai)
