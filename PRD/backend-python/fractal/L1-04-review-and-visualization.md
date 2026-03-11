# L1-04 回顾与可视化（Review & Visualization）

## 1. 目标与边界

目标：让用户形成“记录 -> 回顾 -> 再记录”的习惯闭环。
边界：本阶段先做热力图与每日回顾，不做复杂 BI。

## 2. 能力清单（Feature IDs）

- `CAL-01` 日历热力图（新增）
- `REV-01` 每日回顾卡片（新增）
- `REV-02` 历史随机回顾/同日回顾
- `STAT-01` 记录量趋势

## 3. 闭环流程（事件流）

`写入笔记 -> 聚合日维度数据 -> 热力图渲染 -> 回顾触发 -> 新输入`

## 4. 状态与数据模型

- `DailyNoteStat`: date/count/tags
- `ReviewTask`: type/target_date/note_ids/status

## 5. 接口契约（API）

- `API-CAL-01`: `GET /stats/heatmap`（待加）
- `API-REV-01`: `GET /review/daily`（待加）

## 6. 规则清单（Rules）

- `R-CAL-01`: 热力颜色仅按计数映射，不夹带主观评分
- `R-REV-01`: 回顾结果可追溯到原始笔记 ID

## 7. 代码映射（Code Mapping）

- `MAP-CAL-01`: [notes.dart](/d:/02-Projects/01-Sparknote/mobile/lib/pages/notes.dart)
  - 当前 `openCalendarView` 为临时实现，后续替换为热力图组件
- `MAP-CAL-02`: [main.py](/d:/02-Projects/01-Sparknote/backend/main.py)
  - 新增聚合统计接口

## 8. 指标与告警

- 每周回顾触达率
- 热力图打开率
- 回顾后新增笔记转化率

## 9. 验收标准

- 热力图可展示近 N 周记录强度
- 点击任意日期可查看当日笔记列表
- 每日回顾可返回可读卡片
