<!-- Spark_Vault_uniapp/src/pages/chat/index.vue -->
<template>
  <scroll-view scroll-y class="sv-page">
    <view class="sv-header">
      <view>
        <text class="sv-kicker">SELF REFLECTION & DIALOGUE</text>
        <text class="sv-title">照见 <text class="sv-title-mark">. Salon</text></text>
      </view>
      <text class="sv-pill" @click="goSkills">{{ enabledMentors.length }} SKILLS</text>
    </view>

    <text class="intro-copy">
      选择一个思考视角，通过对话或引用记录，重新看见你收集起来的想法。
    </text>

    <text class="sv-section">THINKING PERSONAS</text>
    <view v-if="enabledMentors.length === 0" class="sv-card empty-card">
      <text class="empty-title">没有启用的 AI 对话角色</text>
      <text class="sv-body">去 Skills 页面打开一个内置导师，或创建自定义思考框架。</text>
    </view>

    <view
      v-for="mentor in enabledMentors"
      :key="mentor.id"
      class="sv-card persona-card"
      @click="startSession('mentor', mentor)"
    >
      <view class="persona-icon">{{ mentor.emoji || '◇' }}</view>
      <view class="persona-copy">
        <view class="sv-between">
          <text class="persona-title">{{ mentor.name }}</text>
          <text class="persona-start">开始 ＋</text>
        </view>
        <text class="persona-desc">{{ mentor.desc || '使用这套思维框架展开对话。' }}</text>
      </view>
    </view>

    <text class="sv-section">MODE SHORTCUTS</text>
    <view class="mode-grid">
      <view
        v-for="mode in modes"
        :key="mode.id"
        class="mode-card"
        @click="startSession(mode.id)"
      >
        <text class="mode-icon">{{ mode.icon }}</text>
        <text class="mode-name">{{ mode.name }}</text>
        <text class="mode-desc">{{ mode.desc }}</text>
      </view>
    </view>

    <view class="sv-between history-head">
      <text class="sv-section history-section">HISTORICAL DIALOGUES</text>
      <text class="sv-caption">{{ sessions.length }} sessions</text>
    </view>

    <view v-if="sessions.length === 0" class="sv-card empty-card">
      <text class="empty-title">暂无历史对话</text>
      <text class="sv-body">先选择上方的模式，开始一次自我照见。</text>
    </view>

    <view
      v-for="session in sessions"
      :key="session.id"
      class="sv-card session-card"
      @click="goSession(session.id)"
    >
      <view class="session-main">
        <view class="sv-row">
          <text class="mode-badge">{{ modeLabel(session.mode) }}</text>
          <text class="sv-caption">{{ formatDate(session.updated_at || session.created_at) }}</text>
        </view>
        <text class="session-title">{{ session.title || '照见会话' }}</text>
        <text class="session-last">{{ lastMessage(session) }}</text>
      </view>
      <text class="session-arrow">进入</text>
    </view>
  </scroll-view>
</template>

<script>
import { getVaultStore } from '../../store/vaultStore.js'
import { CHAT_MODES } from '../../services/vaultLogic.js'
import { getEnabledMentors } from '../../services/skillsService.js'

export default {
  name: 'ChatPage',
  data() {
    return {
      sessions: [],
      modes: CHAT_MODES,
      enabledMentors: []
    }
  },
  onShow() {
    this.loadData()
  },
  methods: {
    loadData() {
      const store = getVaultStore()
      store.refresh()
      this.sessions = store.state.sessions
      this.enabledMentors = getEnabledMentors()
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
    modeLabel(modeId) {
      const found = CHAT_MODES.find((mode) => mode.id === modeId)
      return found ? found.name : '对话'
    },
    lastMessage(session) {
      const messages = Array.isArray(session.messages) ? session.messages : []
      const last = messages[messages.length - 1]
      if (!last) return '暂无谈论记录...'
      const text = last.content || last.text || ''
      return text.length > 34 ? `${text.slice(0, 34)}...` : text
    },
    formatDate(ts) {
      if (!ts) return ''
      const d = new Date(ts)
      return `${d.getMonth() + 1}/${d.getDate()} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
    }
  }
}
</script>

<style scoped>
.intro-copy {
  display: block;
  margin: -8rpx 0 22rpx;
  color: rgba(26, 26, 26, 0.68);
  font-size: 23rpx;
  line-height: 1.56;
}

.persona-card {
  display: flex;
  gap: 20rpx;
  margin-bottom: 22rpx;
}

.persona-icon {
  width: 72rpx;
  height: 72rpx;
  border-radius: 20rpx;
  border: 1rpx solid #dedacf;
  background: #f8f7f2;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #c4a052;
  font-size: 32rpx;
  flex-shrink: 0;
}

.persona-copy {
  flex: 1;
  min-width: 0;
}

.persona-title {
  color: #1a2b48;
  font-size: 24rpx;
  line-height: 1.35;
  font-weight: 900;
}

.persona-start {
  color: #c4a052;
  font-size: 18rpx;
  font-weight: 900;
}

.persona-desc {
  display: block;
  margin-top: 8rpx;
  color: rgba(26, 26, 26, 0.68);
  font-size: 21rpx;
  line-height: 1.45;
}

.mode-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 28rpx;
}

.mode-card {
  min-height: 172rpx;
  padding: 28rpx;
  border-radius: 18rpx;
  border: 1rpx solid #dedacf;
  background: #ffffff;
  box-sizing: border-box;
  overflow: hidden;
}

.mode-icon {
  display: block;
  color: #c4a052;
  font-size: 34rpx;
}

.mode-name {
  display: block;
  margin-top: 12rpx;
  color: #1a2b48;
  font-size: 23rpx;
  font-weight: 900;
}

.mode-desc {
  display: block;
  margin-top: 6rpx;
  color: rgba(26, 26, 26, 0.55);
  font-size: 19rpx;
  line-height: 1.38;
}

.history-head {
  align-items: flex-end;
  margin-top: 8rpx;
}

.history-section {
  margin-bottom: 0;
}

.empty-card {
  margin-bottom: 16rpx;
  border-style: dashed;
}

.empty-title {
  display: block;
  color: #1a2b48;
  font-size: 24rpx;
  font-weight: 900;
  margin-bottom: 8rpx;
}

.session-card {
  display: flex;
  align-items: center;
  gap: 18rpx;
  margin-top: 18rpx;
}

.session-main {
  flex: 1;
  min-width: 0;
}

.mode-badge {
  display: inline-flex;
  padding: 5rpx 12rpx;
  border-radius: 9rpx;
  border: 1rpx solid #f1d9a8;
  background: #fff8e8;
  color: #8a5e13;
  font-family: "Courier New", monospace;
  font-size: 16rpx;
  font-weight: 900;
}

.session-title {
  display: block;
  margin-top: 10rpx;
  color: #1a2b48;
  font-size: 24rpx;
  line-height: 1.35;
  font-weight: 900;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.session-last {
  display: block;
  margin-top: 6rpx;
  color: rgba(26, 26, 26, 0.55);
  font-size: 20rpx;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.session-arrow {
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

@media screen and (min-width: 960px) {
  .intro-copy {
    max-width: 760px;
  }

  .persona-card {
    margin-bottom: 16px;
    padding: 18px;
  }

  .mode-grid {
    gap: 20px;
  }

  .mode-card {
    min-height: 118px;
    padding: 22px;
    border-radius: 14px;
  }
}
</style>
