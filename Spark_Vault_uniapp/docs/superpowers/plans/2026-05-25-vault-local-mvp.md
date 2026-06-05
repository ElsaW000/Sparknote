# Vault 本地 MVP 实施计划

> **给自动执行的工作流说明：** 实施本计划时，优先使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 按任务逐步推进。所有步骤均使用复选框（`- [ ]`）进行跟踪。

**目标：** 构建一个本地、多运行时的 uni-app MVP，把安卓端的 Vault 数据流迁移为可复用的 JavaScript 逻辑。

**架构：** 保持页面组件尽量轻量。把片段/报告规则放在纯 JS service 中，把持久化放到 repository 层，把共享页面状态放到一个小型 store 中；运行时优先使用 `uni` 存储，测试环境使用内存存储。

**技术栈：** uni-app Vue 3 Options API、纯 JavaScript ES modules、Node 内置 `assert` 做逻辑测试。

---

### 任务 1：纯 Vault 逻辑

**文件：**
- 新建：`Spark_Vault_uniapp/services/vaultLogic.js`
- 测试：`Spark_Vault_uniapp/tests/test_vault_logic.mjs`

- [ ] 为片段创建、过滤、兜底标签、合并行为、本地报告生成编写测试。
- [ ] 运行 `node tests/test_vault_logic.mjs`，确认由于 `services/vaultLogic.js` 不存在而失败。
- [ ] 实现纯函数，加入空值检查和确定性的兜底行为。
- [ ] 再次运行 `node tests/test_vault_logic.mjs`，确认通过。

### 任务 2：仓储与状态

**文件：**
- 新建：`Spark_Vault_uniapp/services/vaultRepository.js`
- 新建：`Spark_Vault_uniapp/store/vaultStore.js`
- 修改：`Spark_Vault_uniapp/tests/test_vault_logic.mjs`

- [ ] 增加仓储的保存/更新/删除测试，以及 store 的采集/报告动作测试。
- [ ] 先运行测试，确认在实现前失败。
- [ ] 实现 repository：优先使用 `uni.getStorageSync` / `uni.setStorageSync`，并提供内存回退。
- [ ] 实现 store 动作：对用户友好地提示错误信息，空输入时不崩溃。
- [ ] 再次运行测试，确认通过。

### 任务 3：页面集成

**文件：**
- 修改：`Spark_Vault_uniapp/pages/dashboard/index.vue`
- 修改：`Spark_Vault_uniapp/pages/library/index.vue`
- 修改：`Spark_Vault_uniapp/pages/library/detail.vue`
- 修改：`Spark_Vault_uniapp/pages/capture/index.vue`
- 修改：`Spark_Vault_uniapp/pages/workspace/index.vue`
- 修改：`Spark_Vault_uniapp/pages/workspace/result.vue`
- 修改：`Spark_Vault_uniapp/pages/workspace/references.vue`
- 修改：`Spark_Vault_uniapp/pages/archive/index.vue`
- 修改：`Spark_Vault_uniapp/pages/archive/report-detail.vue`

- [ ] 在需要数据的页面中引入 store。
- [ ] 对 tabBar 路由使用 `uni.switchTab`，对子页面使用 `uni.navigateTo`。
- [ ] 表单使用 `v-model` 绑定，校验空输入，并通过 `uni.showToast` 提示错误。
- [ ] 在详情页、结果页、报告页的 query string 中传递 ID。

### 任务 4：验证

**文件：**
- 验证所有新建和修改过的 JS/Vue 文件。

- [ ] 运行 `node tests/test_vault_logic.mjs`。
- [ ] 对新建的 service/store/test JS 文件运行 `node --check`。
- [ ] 阅读主要变更页面，检查是否存在缺失导入、空处理器和 tab 路由误用。
