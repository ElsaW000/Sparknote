# Android 版使用指南

> 适用版本：P0 本地离线版（无需注册账号，需配置 DashScope API Key）  
> 运行环境：Android 8.0+（API 26+）

---

## 第一步：构建并安装 APK

### 前置条件
- Android Studio（Hedgehog 或更新版本）
- Android 手机，已开启**开发者选项 → USB 调试**

### 配置 API Key

在 `google_ai_studio_android/` 目录下创建或编辑 `.env` 文件：

```
DASHSCOPE_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
```

> API Key 在编译时通过 Gradle 注入到 BuildConfig，不会打包进 APK 明文。  
> 免费申请地址：https://dashscope.aliyun.com/

### 构建步骤

1. 用 Android Studio 打开 `google_ai_studio_android/` 目录
2. 等待 Gradle 同步完成
3. 顶部菜单 **Run → Run 'app'**（或按 `Shift+F10`）
4. 选择你的设备，点击 OK

如需生成 APK 文件：**Build → Build Bundle(s) / APK(s) → Build APK(s)**  
生成路径：`app/build/outputs/apk/debug/app-debug.apk`

---

## 第二步：首次启动

App 首次打开时会自动加载几条**示例片段**（种子数据），让你马上看到界面效果而不是空白。

底部有 5 个 Tab：

| Tab | 图标 | 功能 |
|---|---|---|
| Dashboard | 仪表盘 | 总览统计、快速入口 |
| Library | 书本 | 查看所有片段、搜索过滤 |
| Capture | 相机 | 录入新片段 |
| Workspace | 大脑 | AI 合成报告 |
| Archive | 设置 | 历史报告 + 周报 |

---

## 第三步：录入第一条片段（Capture Tab）

1. 点击底部 **Capture** Tab
2. 在文本框中粘贴或输入你想保存的文字（书摘、想法、网页内容等）
3. 选择来源类型（Book / Browser / E-book / Screenshot / Conversation / Other）
4. 可选填：来源标题、作者、页码、个人备注
5. 点击 **✨ Generate Tags & Summary**（需有效 API Key）
   - 自动生成 3-5 个语义标签
   - 自动生成一句摘要
6. 点击 **Save Fragment** 保存

> 没有 API Key 时，App 会使用本地兜底逻辑自动从文本提取关键词作为标签。

---

## 第四步：在 Library 中查找片段

1. 点击底部 **Library** Tab
2. 顶部搜索栏输入关键词（支持：正文、来源标题、作者、标签）
3. 点击来源类型标签（All / Book / Browser...）进行过滤
4. 点击标签名过滤特定主题
5. 勾选 **Favorites only** 只看收藏
6. 点击任意片段查看详情，点击 ⭐ 收藏/取消收藏

---

## 第五步：用 AI Workspace 生成报告

1. 点击底部 **Workspace** Tab
2. 在输入框中写下你的问题或主题（例如："帮我总结关于系统思维的要点"）
3. 选择报告类型（Outline / Essay / Bullets）
4. 点击 **Generate** 按钮
5. AI 会从你的 Library 中找相关片段，生成一篇综合报告
6. 报告下方会显示引用了哪些片段
7. 点击 **Save to Archive** 保存报告

> 如果 Library 中片段很少，AI 的结果会比较有限，建议先录入 10+ 条片段再使用。

---

## 第六步：查看 Archive（历史报告）

1. 点击底部 **Archive** Tab
2. 顶部可查看 **周报**（自动基于最近片段生成）
3. 下方列表是所有已保存的报告
4. 点击任意报告查看完整内容

---

## 常见问题

### AI 功能不工作，显示 "API key not configured"
- 确认 `.env` 文件中 `DASHSCOPE_API_KEY` 已填写真实 key
- 重新编译运行（key 在编译期注入）

### 报错 "Network error" / AI 请求失败
- 确认手机能访问外网
- DashScope 国内可用，无需 VPN
- 检查 key 是否有效（余额是否充足）

### OCR 功能没有真实相机扫描
- P0 版本的 OCR 是将图片转为 base64 发给 Qwen 视觉模型识别
- 需要从相册选择图片，不支持实时拍摄（P1 计划补充）

### 数据保存在哪里
- 全部存储在手机本地 Room 数据库（SQLite）
- 卸载 App 会清除所有数据
- P2 阶段会加入云端备份
