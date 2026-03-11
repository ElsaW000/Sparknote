# P0 后端功能文档（必须先做）

## 目标
先保证可用性闭环：注册登录、笔记可写可读、标签可用、回顾可见。

## 功能清单
- `AUTH-04` 注册验证码（已实现基础版）
- `AUTH-02` 登录鉴权
- `CAP-01` 新建笔记
- `TAG-02` hashtag 自动提取
- `CAL-01` 日历/热力图数据基础

## 对应分形文档
- [L1-01 输入与记录](/d:/02-Projects/01-Sparknote/PRD/backend-python/fractal/L1-01-input-and-capture.md)
- [L1-02 组织与分类](/d:/02-Projects/01-Sparknote/PRD/backend-python/fractal/L1-02-organization-and-tagging.md)
- [L1-04 回顾与可视化](/d:/02-Projects/01-Sparknote/PRD/backend-python/fractal/L1-04-review-and-visualization.md)

## 对应代码
- [main.py](/d:/02-Projects/01-Sparknote/backend/main.py)
- [test_api.py](/d:/02-Projects/01-Sparknote/backend/tests/test_api.py)
