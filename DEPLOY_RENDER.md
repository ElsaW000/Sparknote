# Sparknote Render 部署说明

这套方案会把后端和已经构建好的 Flutter Web 前端一起部署到 Render，得到一个固定公网链接。

## 方案特点

- 一个 URL 同时提供前端页面和后端 API
- 使用 Render Persistent Disk 持久化保存：
  - `sqlite` 数据库
  - 上传文件
- 不依赖本地电脑持续开机

## 当前部署文件

- [Dockerfile](/d:/02-Projects/01-Sparknote/Dockerfile)
- [render.yaml](/d:/02-Projects/01-Sparknote/render.yaml)

## 部署步骤

1. 打开 Render 控制台
2. 选择 `New +`
3. 选择 `Blueprint`
4. 连接 GitHub 仓库 `ElsaW000/Sparknote`
5. 选择当前仓库后创建
6. 等待 Render 按 `render.yaml` 自动创建服务

## 部署后的环境

`render.yaml` 已经预设：

- `DATABASE_URL=sqlite:////data/sparknote.db`
- `UPLOADS_DIR=/data/uploads`
- 自动生成 `JWT_SECRET_KEY`
- 开启注册验证码

如果你要接真实 AI，再在 Render 后台补这些环境变量：

- `DASHSCOPE_API_KEY`
或
- `OPENAI_API_KEY`

## 首次上线后检查

部署完成后，打开：

- `/health`
- 首页
- 注册页
- 登录页
- 新建笔记
- 灵感工作台

## 注意事项

- 目前是单实例 SQLite 方案，适合 MVP 和个人长期使用，不适合高并发多副本扩容。
- 如果后续要更稳地长期运营，建议下一步迁移到 Postgres + 对象存储。
- 当前前端使用仓库里的 `mobile/build/web` 构建产物；如果你改了 Flutter 页面，需要重新构建后再部署。
