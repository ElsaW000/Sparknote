<!-- Spark_Vault_uniapp/src/pages/workspace/index.vue -->
<template>
  <scroll-view scroll-y class="sv-page">
    <view class="sv-header">
      <view>
        <text class="sv-kicker">REVIEW & ORGANIZE</text>
        <text class="sv-title">整理 <text class="sv-title-mark">. Studio</text></text>
      </view>
      <text class="sv-pill">已选 {{ selectedIds.length }}</text>
    </view>

    <text class="intro-copy">
      从碎片库里选几条记录，生成一份回顾、主题整理或提醒卡。
    </text>

    <view class="compile-form">
      <view class="field-block">
        <text class="form-label">选择整理方式</text>
        <view class="type-switch">
          <text
            v-for="type in reportTypes"
            :key="type.key"
            :class="['type-item', reportType === type.key ? 'active' : '']"
            @click="reportType = type.key"
          >
            {{ type.label }}
          </text>
        </view>
      </view>

      <view class="field-block">
        <text class="form-label">想重点看什么</text>
        <input
          class="sv-input"
          v-model="prompt"
          placeholder="例如：最近反复出现的问题、想整理的主题..."
        />
      </view>

      <view class="field-block">
        <view class="sv-between selector-head">
          <text class="form-label">选择要整理的记录</text>
          <text class="select-all" @click="toggleAll">
            {{ selectedIds.length === fragments.length && fragments.length ? '取消全选' : '全选' }}
          </text>
        </view>

        <view v-if="fragments.length === 0" class="sv-card empty-card">
          <text class="empty-title">还没有可整理的记录</text>
          <text class="sv-body">先去碎片库添加内容，再回到这里生成整理结果。</text>
        </view>

        <view
          v-for="fragment in fragments"
          :key="fragment.id"
          :class="['source-card', selectedIds.includes(fragment.id) ? 'active' : '']"
          @click="toggleSelect(fragment.id)"
        >
          <text class="checkbox">{{ selectedIds.includes(fragment.id) ? '✓' : '' }}</text>
          <view class="source-content">
            <view class="sv-between">
              <text class="sv-caption">{{ fragment.sourceType || fragment.subtype || 'Manual' }}</text>
              <text class="sv-caption">{{ formatDate(fragment.created_at || fragment.createdAt) }}</text>
            </view>
            <text class="source-title">{{ fragment.title || fragment.sourceTitle || '未命名碎片' }}</text>
            <text class="source-copy">{{ fragment.content || fragment.originalText }}</text>
          </view>
        </view>
      </view>

      <text v-if="errorText" class="error-text">{{ errorText }}</text>

      <button class="sv-primary compile-button" @click="generate">
        生成整理
      </button>
    </view>

    <view v-if="workspaceResult" class="result-block">
      <view class="sv-between">
        <text class="sv-section result-title">整理结果</text>
        <text class="select-all" @click="clearDraft">清空</text>
      </view>
      <view class="sv-card draft-card">
        <text class="draft-content">{{ workspaceResult.content }}</text>
        <button class="sv-secondary references-button" @click="openReport">查看报告详情</button>
      </view>
    </view>

    <view class="history-block">
      <text class="sv-section">历史整理</text>
      <view
        v-for="report in reports.slice(0, 3)"
        :key="report.id"
        class="sv-card report-card"
        @click="openReport(report.id)"
      >
        <view>
          <text class="report-month">{{ report.month || 'LOCAL' }}</text>
          <text class="report-title">{{ report.title }}</text>
        </view>
        <text class="report-arrow">查看</text>
      </view>
    </view>

    <view class="reflection-block">
      <view class="sv-between reflection-head">
        <text class="sv-section reflection-title">照见会话</text>
        <text class="select-all" @click="goSkills">{{ enabledMentors.length }} Skills</text>
      </view>

      <view class="mode-grid">
        <view
          v-for="mode in modes"
          :key="mode.id"
          class="mode-card"
          @click="startSession(mode.id)"
        >
          <text class="mode-icon">{{ mode.icon }}</text>
          <text class="mode-name">{{ mode.name }}</text>
        </view>
      </view>

      <view
        v-for="mentor in enabledMentors"
        :key="mentor.id"
        class="sv-card persona-card"
        @click="startSession('mentor', mentor)"
      >
        <view class="persona-icon">{{ mentor.emoji || '◇' }}</view>
        <view class="persona-copy">
          <text class="persona-title">{{ mentor.name }}</text>
          <text class="persona-start">开始 +</text>
        </view>
      </view>

      <view v-if="sessions.length === 0" class="sv-card empty-card">
        <text class="empty-title">暂无历史对话</text>
      </view>

      <view
        v-for="session in sessions.slice(0, 3)"
        :key="session.id"
        class="sv-card session-card"
        @click="goSession(session.id)"
      >
        <view class="session-main">
          <text class="session-title">{{ session.title || '照见会话' }}</text>
          <text class="session-last">{{ lastMessage(session) }}</text>
        </view>
        <text class="report-arrow">进入</text>
      </view>
    </view>
  </scroll-view>
</template>

<script>
import { getVaultStore } from '../../store/vaultStore.js'
import { CHAT_MODES } from '../../services/vaultLogic.js'
import { getEnabledMentors } from '../../services/skillsService.js'

export default {
  name: 'WorkspacePage',
  data() {
    return {
      prompt: '',
      reportType: 'weekly',
      selectedIds: [],
      fragments: [],
      reports: [],
      sessions: [],
      modes: CHAT_MODES,
      enabledMentors: [],
      workspaceResult: null,
      errorText: '',
      reportTypes: [
        { key: 'weekly', label: '阶段回顾' },
        { key: 'topic', label: '主题整理' },
        { key: 'reflection', label: '提醒卡' }
      ]
    }
  },
  onShow() {
    this.loadData()
  },
  methods: {
    loadData() {
      const store = getVaultStore()
      store.refresh()
      this.fragments = store.state.fragments
      this.reports = store.state.reports
      this.sessions = store.state.sessions
      this.enabledMentors = getEnabledMentors()
      this.workspaceResult = store.state.workspaceResult
      this.selectedIds = this.selectedIds.filter((id) => this.fragments.some((f) => f.id === id))
    },
    toggleSelect(id) {
      if (!Number.isInteger(Number(id))) return
      if (this.selectedIds.includes(id)) {
        this.selectedIds = this.selectedIds.filter((item) => item !== id)
      } else {
        this.selectedIds = [...this.selectedIds, id]
      }
      this.errorText = ''
    },
    toggleAll() {
      if (this.selectedIds.length === this.fragments.length && this.fragments.length) {
        this.selectedIds = []
      } else {
        this.selectedIds = this.fragments.map((f) => f.id)
      }
      this.errorText = ''
    },
    generate() {
      if (!this.selectedIds.length) {
        this.errorText = '请至少选择一条记录。'
        return
      }
      const selectedFragments = this.fragments.filter((f) => this.selectedIds.includes(f.id))
      const store = getVaultStore()
      const result = store.generateWorkspaceReport({
        prompt: this.prompt || selectedFragments.map((f) => f.title || f.content || '').join(' '),
        reportType: this.reportLabel()
      })
      if (!result.ok) {
        uni.showToast({ title: result.error || '生成失败', icon: 'none' })
        return
      }
      this.workspaceResult = {
        ...result.workspaceResult,
        content: result.report?.generatedContent || result.report?.content || ''
      }
      store.state.workspaceResult = this.workspaceResult
      this.reports = store.state.reports
      uni.showToast({ title: '整理已生成', icon: 'success' })
    },
    reportLabel() {
      const found = this.reportTypes.find((type) => type.key === this.reportType)
      return found ? found.label : '阶段回顾'
    },
    clearDraft() {
      this.workspaceResult = null
      const store = getVaultStore()
      store.state.workspaceResult = null
    },
    openReport(id) {
      const targetId = id || this.workspaceResult?.reportId
      if (!Number.isInteger(Number(targetId))) return
      uni.navigateTo({ url: `/pages/home/report/detail?id=${targetId}` })
    },
    startSession(modeId, mentor = null) {
      const store = getVaultStore()
      const result = store.saveSession({
        mode: modeId,
        title: mentor ? `${mentor.name} · 新会话` : undefined
      })
      if (!result.ok) {
        uni.showToast({ title: result.error || '创建会话失败', icon: 'none' })
        return
      }
      uni.navigateTo({ url: `/pages/chat/session?id=${result.session.id}` })
    },
    goSession(id) {
      if (!Number.isInteger(Number(id))) return
      uni.navigateTo({ url: `/pages/chat/session?id=${id}` })
    },
    goSkills() {
      uni.navigateTo({ url: '/pages/me/skills' })
    },
    lastMessage(session) {
      const messages = Array.isArray(session.messages) ? session.messages : []
      const last = messages[messages.length - 1]
      if (!last) return ''
      const text = last.content || last.text || ''
      return text.length > 34 ? `${text.slice(0, 34)}...` : text
    },
    formatDate(ts) {
      if (!ts) return ''
      const d = new Date(ts)
      return `${d.getMonth() + 1}/${d.getDate()}`
    }
  }
}
</script>

<style scoped>
.intro-copy {
  display: block;
  margin: -8rpx 0 26rpx;
  color: rgba(26, 26, 26, 0.68);
  font-size: 23rpx;
  line-height: 1.56;
}

.compile-form {
  display: flex;
  flex-direction: column;
  gap: 28rpx;
}

.field-block {
  display: flex;
  flex-direction: column;
  gap: 14rpx;
}

.form-label {
  display: block;
  color: rgba(26, 26, 26, 0.5);
  font-family: "Courier New", monospace;
  font-size: 18rpx;
  font-weight: 900;
  letter-spacing: 2rpx;
}

.type-switch {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8rpx;
  padding: 8rpx;
  border-radius: 20rpx;
  border: 1rpx solid rgba(222, 218, 207, 0.65);
  background: rgba(234, 230, 219, 0.5);
}

.type-item {
  min-height: 62rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 14rpx;
  color: rgba(26, 26, 26, 0.56);
  font-size: 20rpx;
  font-weight: 900;
}

.type-item.active {
  background: #c4a052;
  color: #1a2b48;
}

.selector-head {
  align-items: flex-end;
}

.select-all {
  color: #1a2b48;
  font-size: 20rpx;
  font-weight: 900;
}

.source-card {
  display: flex;
  align-items: flex-start;
  gap: 16rpx;
  padding: 20rpx;
  margin-bottom: 14rpx;
  border: 1rpx solid #dedacf;
  border-radius: 18rpx;
  background: #ffffff;
  box-sizing: border-box;
}

.source-card.active {
  background: #f8f7f2;
  border-color: #c4a052;
}

.checkbox {
  width: 30rpx;
  height: 30rpx;
  margin-top: 4rpx;
  border-radius: 8rpx;
  border: 2rpx solid #c4a052;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #1a2b48;
  font-size: 20rpx;
  font-weight: 900;
  flex-shrink: 0;
}

.source-content {
  flex: 1;
  min-width: 0;
}

.source-title {
  display: block;
  margin-top: 8rpx;
  color: #1a2b48;
  font-size: 23rpx;
  font-weight: 900;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.source-copy {
  display: block;
  margin-top: 7rpx;
  color: rgba(26, 26, 26, 0.66);
  font-size: 20rpx;
  line-height: 1.45;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.error-text {
  color: #b45309;
  font-size: 21rpx;
  font-weight: 800;
}

.compile-button {
  margin-top: 2rpx;
}

.result-block {
  margin-top: 30rpx;
}

.result-title {
  margin: 0 0 14rpx;
}

.draft-card {
  margin-top: 14rpx;
}

.draft-content {
  display: block;
  white-space: pre-wrap;
  color: rgba(26, 26, 26, 0.78);
  font-size: 23rpx;
  line-height: 1.62;
}

.references-button {
  margin-top: 22rpx;
}

.history-block {
  margin-top: 26rpx;
}

.report-card {
  margin-bottom: 14rpx;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16rpx;
}

.report-month {
  display: inline-flex;
  padding: 5rpx 12rpx;
  border-radius: 8rpx;
  background: #f2f0e9;
  border: 1rpx solid #dedacf;
  color: #1a2b48;
  font-family: "Courier New", monospace;
  font-size: 16rpx;
  font-weight: 900;
}

.report-title {
  display: block;
  margin-top: 10rpx;
  color: #1a2b48;
  font-size: 23rpx;
  line-height: 1.35;
  font-weight: 900;
}

.report-arrow {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 72rpx;
  height: 44rpx;
  padding: 0 16rpx;
  border: 1rpx solid #dedacf;
  border-radius: 999rpx;
  color: #1a2b48;
  background: #f8f7f2;
  font-size: 21rpx;
  font-weight: 900;
  box-sizing: border-box;
}

.empty-card {
  border-style: dashed;
}

.empty-title {
  display: block;
  color: #1a2b48;
  font-size: 24rpx;
  font-weight: 900;
  margin-bottom: 8rpx;
}

.reflection-block {
  margin-top: 30rpx;
  padding-bottom: 18rpx;
}

.reflection-head {
  align-items: center;
}

.reflection-title {
  margin-bottom: 0;
}

.mode-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14rpx;
  margin: 16rpx 0;
}

.mode-card {
  min-height: 94rpx;
  padding: 18rpx;
  border-radius: 18rpx;
  border: 1rpx solid #dedacf;
  background: #ffffff;
  box-sizing: border-box;
}

.mode-icon {
  display: block;
  color: #c4a052;
  font-size: 26rpx;
  line-height: 1;
}

.mode-name {
  display: block;
  margin-top: 8rpx;
  color: #1a2b48;
  font-size: 22rpx;
  font-weight: 900;
}

.persona-card,
.session-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16rpx;
  margin-bottom: 14rpx;
}

.persona-icon {
  width: 58rpx;
  height: 58rpx;
  border-radius: 16rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1rpx solid #dedacf;
  background: #f8f7f2;
  color: #c4a052;
  font-size: 26rpx;
}

.persona-copy,
.session-main {
  flex: 1;
  min-width: 0;
}

.persona-title,
.session-title {
  display: block;
  color: #1a2b48;
  font-size: 23rpx;
  font-weight: 900;
}

.persona-start {
  display: block;
  margin-top: 6rpx;
  color: #c4a052;
  font-size: 20rpx;
  font-weight: 900;
}

.session-last {
  display: block;
  margin-top: 6rpx;
  color: rgba(26, 26, 26, 0.56);
  font-size: 20rpx;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
