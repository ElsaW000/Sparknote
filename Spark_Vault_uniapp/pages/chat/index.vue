<!-- pages/chat/index.vue — Chat Tab：Session 发起入口 -->
<template>
  <scroll-view class="page" scroll-y>
    <!-- Header -->
    <view class="header">
      <text class="title">Chat</text>
      <text class="subtitle">对话会话</text>
    </view>

    <!-- Mode cards -->
    <view class="modes-section">
      <text class="section-label">选择一种对话方式开始 →</text>
      <view class="modes-list">
        <view
          class="mode-card"
          v-for="mode in chatModes"
          :key="mode.id"
          @click="startSession(mode.id)"
        >
          <view class="mode-left">
            <text class="mode-icon">{{ mode.icon }}</text>
            <view>
              <text class="mode-name">{{ mode.name }}</text>
              <text class="mode-desc">{{ mode.desc }}</text>
            </view>
          </view>
          <text class="mode-arrow">›</text>
        </view>
      </view>
    </view>

    <!-- History sessions -->
    <view class="history-section" v-if="sessions.length">
      <text class="section-label">历史会话</text>
      <view
        class="session-row"
        v-for="s in sessions"
        :key="s.id"
        @click="resumeSession(s.id)"
      >
        <text class="session-icon">{{ modeIcon(s.mode) }}</text>
        <view class="session-info">
          <text class="session-title">{{ s.title }}</text>
          <text class="session-preview">{{ lastMessage(s) }}</text>
        </view>
        <text class="session-time">{{ relativeTime(s.updated_at || s.created_at) }}</text>
      </view>
    </view>

    <view v-else class="history-empty">
      <text>开始你的第一次 AI 对话吧</text>
    </view>
  </scroll-view>
</template>

<script>
import { getVaultStore } from '@/store/vaultStore.js'
import { CHAT_MODES } from '@/services/vaultLogic.js'

const store = getVaultStore()

export default {
  data() {
    return {
      chatModes: CHAT_MODES,
      sessions: []
    }
  },
  onShow() {
    this.syncState()
    // Handle pending mode from Home tab
    try {
      const pendingMode = uni.getStorageSync('pending_chat_mode')
      if (pendingMode) {
        uni.removeStorageSync('pending_chat_mode')
        this.$nextTick(() => this.startSession(pendingMode))
      }
    } catch (_) {}
  },
  methods: {
    syncState() {
      store.refresh()
      this.sessions = (store.state.sessions || [])
        .slice()
        .sort((a, b) => (b.updated_at || b.created_at || 0) - (a.updated_at || a.created_at || 0))
    },
    modeIcon(modeId) {
      const m = CHAT_MODES.find((c) => c.id === modeId)
      return m ? m.icon : '💬'
    },
    lastMessage(session) {
      const msgs = session.messages || []
      if (!msgs.length) return '（还没有消息）'
      const last = msgs[msgs.length - 1]
      return (last.content || '').slice(0, 50)
    },
    relativeTime(ts) {
      if (!ts) return ''
      const diff = Date.now() - ts
      if (diff < 60000) return '刚刚'
      if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
      if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`
      if (diff < 7 * 86400000) return `${Math.floor(diff / 86400000)}天前`
      const d = new Date(ts)
      return `${d.getMonth() + 1}/${d.getDate()}`
    },
    startSession(modeId) {
      uni.navigateTo({ url: `/pages/chat/session?mode=${modeId}` })
    },
    resumeSession(sessionId) {
      uni.navigateTo({ url: `/pages/chat/session?sessionId=${sessionId}` })
    }
  }
}
</script>

<style scoped>
.page { background: #fbf9f6; padding: 24rpx; }
.header { margin-bottom: 28rpx; }
.title { display: block; font-size: 48rpx; font-weight: 800; color: #1c1b1f; }
.subtitle { display: block; font-size: 26rpx; color: #49454f; margin-top: 4rpx; }

.section-label { display: block; font-size: 26rpx; color: #49454f; margin-bottom: 16rpx; }

/* Mode cards */
.modes-section { margin-bottom: 36rpx; }
.modes-list { background: #ffffff; border-radius: 24rpx; overflow: hidden; }
.mode-card { display: flex; align-items: center; justify-content: space-between; padding: 24rpx 28rpx; border-bottom: 2rpx solid #f5f2ee; }
.mode-card:last-child { border-bottom: none; }
.mode-left { display: flex; align-items: flex-start; gap: 20rpx; flex: 1; }
.mode-icon { font-size: 40rpx; width: 50rpx; }
.mode-name { display: block; font-size: 30rpx; font-weight: 700; color: #1c1b1f; }
.mode-desc { display: block; font-size: 24rpx; color: #49454f; margin-top: 4rpx; }
.mode-arrow { font-size: 32rpx; color: #a39e97; }

/* History */
.history-section {}
.session-row { display: flex; align-items: center; gap: 16rpx; background: #ffffff; border-radius: 20rpx; padding: 20rpx 24rpx; margin-bottom: 12rpx; }
.session-icon { font-size: 36rpx; width: 46rpx; }
.session-info { flex: 1; min-width: 0; }
.session-title { display: block; font-size: 28rpx; font-weight: 600; color: #1c1b1f; }
.session-preview { display: block; font-size: 24rpx; color: #49454f; margin-top: 4rpx; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.session-time { font-size: 22rpx; color: #a39e97; white-space: nowrap; }

.history-empty { text-align: center; color: #a39e97; font-size: 26rpx; padding: 40rpx; }
</style>
