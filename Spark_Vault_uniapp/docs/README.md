# Spark Vault 文档总览

本目录用于支持 Spark Vault 的长期迭代，目标是让需求、架构、实现、验证、决策可以持续追踪。

## 文档结构
- fundamentals/: 基础设计文档（必须先对齐）
- superpowers/plans/: 实施计划与执行步骤
- decisions/: 架构决策记录（ADR）
- **guides/**: 使用指南（Android 安装、uni-app 启动等）
- roadmap.md: 全项目阶段路线图（P0 Android → P1 uni-app → P2 云端 → P3 协作）
- route_audit.md: 路由对账报告（src/ 基准）
- execution_board.md: 执行看板（Todo / In Progress / Done）
- android_to_uniapp_migration_checklist.md: 安卓到 uni-app 的映射与迁移检查

## 建议阅读顺序
1. roadmap.md（先看大图）
2. fundamentals/01_product_scope.md
3. fundamentals/02_system_architecture.md
4. fundamentals/03_data_contracts.md
5. fundamentals/04_delivery_rhythm.md
6. fundamentals/05_quality_and_testing.md
7. execution_board.md（当前任务进度）
8. superpowers/plans/2026-05-25-vault-local-mvp.md

## 文档维护规则
- 新功能上线前，先更新 scope 和 data contracts。
- 涉及架构变更时，新增或更新 decisions/ADR。
- 每次开发批次结束后，更新 migration checklist 与 delivery rhythm。
- 文档状态使用 Draft / Active / Deprecated 标记。
