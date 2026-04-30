# P0 后端功能文档（Phase 5 — 可执行规格）

## Phase 5 P0 Stories（共 8 项，均已拆解为可执行规格）

| ID | 文件 | 状态 |
|----|------|------|
| AUTH-04 | [AUTH-04-captcha-register.md](AUTH-04-captcha-register.md) | ✅ 规格已输出 |
| AUTH-05 | [AUTH-05-email-verify.md](AUTH-05-email-verify.md) | ✅ 规格已输出 |
| TAG-03 | [TAG-03-frequent-tags.md](TAG-03-frequent-tags.md) | ✅ 规格已输出 |
| NOTE-07 | [NOTE-07-global-search.md](NOTE-07-global-search.md) | ✅ 规格已输出 |
| NOTE-08 | [NOTE-08-filter-combination.md](NOTE-08-filter-combination.md) | ✅ 规格已输出 |
| NOTE-09 | [NOTE-09-pin-favorite.md](NOTE-09-pin-favorite.md) | ✅ 规格已输出 |
| NOTE-10 | [NOTE-10-template-notes.md](NOTE-10-template-notes.md) | ✅ 规格已输出 |
| CAL-02 | [CAL-02-smart-folder.md](CAL-02-smart-folder.md) | ✅ 规格已输出 |

## 实现建议顺序
推荐从 `AUTH-04` 或 `NOTE-07` 开始（均无复杂依赖，可独立实现）。

## 对应代码
- Backend entry: `backend/main.py`
- Tests: `backend/tests/test_api.py`
