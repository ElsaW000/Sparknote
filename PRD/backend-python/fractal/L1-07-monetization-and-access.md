# L1-07 商业化与权限分层（Monetization & Access）

## 1. 目标与边界

目标：建立清晰的免费/Pro/Max 权限边界，避免“付费点模糊”。
边界：本阶段先做功能开关，不做复杂计费系统。

## 2. 能力清单（Feature IDs）

- `BIZ-01` 版本功能矩阵（Free/Pro/Max）
- `BIZ-02` 容量配额（500M/20G/500G）
- `BIZ-03` AI 高级能力按层级开放
- `BIZ-04` 转化漏斗埋点

## 3. 闭环流程（事件流）

`用户触发高级功能 -> 权限校验 -> 引导升级 -> 开通后回流功能页`

## 4. 状态与数据模型

- `Subscription`: user_id/plan/status/expire_at
- `QuotaUsage`: user_id/storage_used/insight_runs

## 5. 接口契约（API）

- `API-BIZ-01`: `GET /me/subscription`（待加）
- `API-BIZ-02`: `POST /billing/checkout`（待加）

## 6. 规则清单（Rules）

- `R-BIZ-01`: 权限不足时返回 `403 + 可读提示`
- `R-BIZ-02`: 升级成功后 5s 内权限生效

## 7. 代码映射（Code Mapping）

- `MAP-BIZ-01`: [main.py](/d:/02-Projects/01-Sparknote/backend/main.py)
  - 新增 plan gate middleware（待加）
- `MAP-BIZ-02`: （待建）`mobile/lib/pages/paywall.dart`

## 8. 指标与告警

- 试用到付费转化率
- 权限拦截命中率
- 升级后功能使用率

## 9. 验收标准

- 同一功能在不同套餐下行为符合矩阵
- 权限拦截与引导链路可完整跑通
