<!-- pages/chat/index.vue -->
<template>
  <view class="page">
    <!-- Header -->
    <view class="header">
      <view>
        <text class="title">Chat</text>
        <text class="subtitle">对话会话</text>
      </view>
      <button class="btn-new" @click="showModeSheet = true">＋ 新建会话</button>
    </view>

    <!-- Mode Picker Card -->
    <view class="card mode-card">
      <text class="mode-prompt">选择一种对话方式开始 →</text>
      <view class="mode-list">
        <view
          v-for="mode in modes"
          :key="mode.id"
          class="mode-item"
          @click="startSession(mode.id)"
        >
          <text class="mode-icon">{{ mode.icon }}</text>
          <view class="mode-info">
            <text class="mode-name">{{ mode.name }}</text>
            <text class="mode-desc">{{ mode.desc }}</text>
          </view>
          <text class="arrow">›</text>
        </view>
      </view>
      <text class="mode-hint">点击任意一项 → 进入全屏对话页</text>
    </view>

    <!-- Session History -->
    <text class="section-title">历史会话</text>

    <view v-if="sessions.length === 0" class="empty-state">
      <text class="empty-text">还没有对话记录。选择上方模式开始第一次对话。</text>
    </view>

    <view class="session-list">
      <view
        v-for="s in sessions"
        :key="s.id"
        class="session-item card"
        @click="goSession(s.id)"
      >
        <text class="session-icon">{{ getModeIcon(s.mode) }}</text>
        <view class="session-info">
          <text class="session-title">{{ s.title }}</text>
          <text class="session-last">{{ lastMessage(s) }}</text>
        </view>
        <text class="session-date">{{ timeAgo(s.updated_at || s.created_at) }}</text>
      </view>
    </view>

    <!-- Mode selection bottom sheet -->
    <view v-if="showModeSheet" class="overlay" @click="showModeSheet = false">
      <view class="sheet" @click.stop>
        <text class="sheet-title">选择对话模式</text>
        <view
          v-for="mode in modes"
          :key="mode.id"
          class="sheet-item"
          @click="startSession(mode.id)"
        >
          <text class="mode-icon">{{ mode.icon }}</text>
          <view class="mode-info">
            <text class="mode-name">{{ mode.name }}</text>
            <text class="mode-desc">{{ mode.desc }}</text>
          </view>
        </view>
        <button class="btn-cancel" @click="showModeSheet = false">取消</button>
      </view>
    </view>
  </view>
</template>

<script>
import { getVaultStore } from '../../store/vaultStore.js'
import { CHAT_MODES } from '../../services/vaultLogic.js'

export default {
  name: 'ChatPage',
  data() {
    return {
      sessions: [],
      modes: CHAT_MODES,
      showModeSheet: false
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
    },
    startSession(modeId) {
      this.showModeSheet = false
      const store = getVaultStore()
      const result = store.saveSession({ mode: modeId })
      if (result.ok) {
        uni.navigateTo({ url: `/pages/chat/session?id=${result.session.id}` })
      }
    },
    goSession(id) {
      uni.navigateTo({ url: `/pages/chat/session?id=${id}` })
    },
    getModeIcon(modeId) {
      return CHAT_MODES.find((m) => m.id === modeId)?.icon || '💬'
    },
    lastMessage(session) {
      const msgs = session.messages || []
      const last = msgs[msgs.length - 1]
      if (!last) return '新会话'
      const prefix = last.role === 'user' ? '你: ' : 'AI: '
      const text = last.content || ''
      return prefix + (text.length > 30 ? text.slice(0, 30) + '...' : text)
    },
    timeAgo(ts) {
      if (!ts) return ''
      const diff = Date.now() - ts
      const days = Math.floor(diff / 86400000)
      if (days === 0) return '今天'
      if (days === 1) return '昨天'
      if (days < 7) return `${days}天前`
      const d = new Date(ts)
      return `${d.getMonth() + 1}/${d.getDate()}`
    }
  }
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  background: #fbf9f6;
  padding: 48rpx 32rpx 120rpx;
  box-sizing: border-box;
}
.header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 32rpx;
  padding-top: 20rpx;
}
.title {
  display: block;
  font-size: 52rpx;
  font-weight: 700;
  color: #1a1a2e;
}
.subtitle {
  display: block;
  font-size: 26rpx;
  color: #888;
  margin-top: 4rpx;
}
.btn-new {
  background: #004a77;
  color: #fff;
  border-radius: 40rpx;
  font-size: 26rpx;
  padding: 16rpx 32rpx;
  border: none;
  white-space: nowrap;
  margin-top: 8rpx;
}
.card {
  background: #fff;
  border-radius: 20rpx;
  padding: 32rpx;
  margin-bottom: 24rpx;
  box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06);
}
.mode-card {}
.mode-prompt {
  display: block;
  font-size: 28rpx;
  font-weight: 600;
  color: #004a77;
  margin-bottom: 24rpx;
}
.mode-list {
  display: flex;
  flex-direction: column;
  gap: 0;
}
.mode-item {
  display: flex;
  align-items: center;
  gap: 20rpx;
  padding: 24rpx 0;
  border-bottom: 1rpx solid #f0f0f0;
}
.mode-item:last-child { border-bottom: none; }
.mode-icon {
  font-size: 40rpx;
  width: 56rpx;
  text-align: center;
}
.mode-info { flex: 1; }
.mode-name {
  display: block;
  font-size: 30rpx;
  font-weight: 600;
  color: #1a1a2e;
}
.mode-desc {
  display: block;
  font-size: 24rpx;
  color: #888;
  margin-top: 4rpx;
}
.arrow {
  font-size: 32rpx;
  color: #ccc;
}
.mode-hint {
  display: block;
  font-size: 22rpx;
  color: #aaa;
  margin-top: 20rpx;
  text-align: center;
}
.section-title {
  display: block;
  font-size: 32rpx;
  font-weight: 600;
  color: #1a1a2e;
  margin-bottom: 16rpx;
}
.empty-state {
  text-align: center;
  padding: 48rpx 0;
}
.empty-text {
  font-size: 26rpx;
  color: #aaa;
}
.session-item {
  display: flex;
  align-items: center;
  gap: 20rpx;
  margin-bottom: 16rpx;
}
.session-icon {
  font-size: 36rpx;
}
.session-info { flex: 1; }
.session-title {
  display: block;
  font-size: 28rpx;
  font-weight: 500;
  color: #1a1a2e;
}
.session-last {
  display: block;
  font-size: 22rpx;
  color: #aaa;
  margin-top: 4rpx;
}
.session-date {
  font-size: 22rpx;
  color: #aaa;
  white-space: nowrap;
}
/* Bottom sheet */
.overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.4);
  z-index: 100;
  display: flex;
  align-items: flex-end;
}
.sheet {
  background: #fff;
  border-radius: 24rpx 24rpx 0 0;
  padding: 40rpx 32rpx 60rpx;
  width: 100%;
  box-sizing: border-box;
}
.sheet-title {
  display: block;
  font-size: 30rpx;
  font-weight: 600;
  color: #1a1a2e;
  margin-bottom: 24rpx;
  text-align: center;
}
.sheet-item {
  display: flex;
  align-items: center;
  gap: 20rpx;
  padding: 24rpx 0;
  border-bottom: 1rpx solid #f0f0f0;
}
.btn-cancel {
  width: 100%;
  background: #f5f5f5;
  color: #555;
  border-radius: 12rpx;
  font-size: 28rpx;
  padding: 20rpx 0;
  border: none;
  margin-top: 24rpx;
}
</style>
