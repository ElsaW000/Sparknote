# NEXT STEP for Sparknote

## 当前判断
- 当前步骤：**AUTH-04 登录页验证码 UI** — ✅ 已完成并 commit (0571fd6)

## 下一步任务
- **CAL-02: 日历视图开发**
  - AUTH-05（注册页验证码）需先确认后端是否也改了注册流程 captcha，暂搁置
  - 日历视图是 Phase 6 独立任务，可以立即推进

## 阻塞点与补救
- 阻塞点：无。当前无阻塞任务。
- 补救动作：N/A

## 人工测试
- AUTH-04 完成后需手动测试：
  - 正常登录流程是否被验证码正确拦截
  - captcha 刷新按钮是否正常
  - `REQUIRE_LOGIN_CAPTCHA=0` 时是否跳过验证
  - 移动端 + 桌面端布局均正常

---

**进度**
- Phase 6 P0 清单(2026-05-15 22:50 更新):
  - [x] NOTE-07: 全文搜索(后端✅/前端已接)
  - [x] NOTE-09: pin/unpin(后端✅/前端已接)
  - [x] AUTH-04: 登录页验证码 ✅ (commit 0571fd6, build 通过)
  - [~] AUTH-05: 注册页验证码(待定，需确认后端注册流程 captcha 改造计划)
  - [ ] CAL-02: 日历视图(待定，**下一步**)
- Phase 7 规划(streaming AI / realtime recording / clipboard paste / Notion sync)
- cron review: 2026-05-15 22:59 CST
- 本次：状态稳定（上次 22:50 更新内容有效），仅更新时间戳
- 末次 commit：2026-05-15 22:49:52 CST (0571fd6)
- git push 失败（exit 1，无输出），commit 已在本地，需手动 `git push` 或检查网络
