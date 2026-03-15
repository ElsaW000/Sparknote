# Debug Tools

保留在仓库里的调试工具只留下可复用、低风险的两类：

- `tools/debug/smoke_http_flow.py`
  - 启动临时后端实例，走一遍真实 HTTP 流程：注册 -> 登录 -> 新建笔记 -> AI 会话 -> 关闭会话。
  - 不污染本地正式数据库，脚本会创建并清理临时 sqlite 文件。
- `tools/debug/inspect_users.py`
  - 只读查看某个 sqlite 数据库里的用户列表。

已清理的根目录临时脚本：

- `check_db.py`
- `check_user.py`
- `debug_login.py`
- `debug_login2.py`
- `fix_user.py`
- `reset_user.py`
- `test_login.py`

这些脚本的问题：

- 路径写死在个人机器目录
- 多个脚本功能重复
- 有的会直接修改或删除用户数据
- 没有说明适用场景，容易误用

推荐命令：

```bash
.venv\Scripts\python tools\debug\smoke_http_flow.py
.venv\Scripts\python tools\debug\inspect_users.py
```
