<!-- Spark_Vault_uniapp/src/pages/index/index.vue -->
<template>
  <scroll-view scroll-y class="iv-page dashboard">
    <view class="iv-header">
      <view>
        <text class="iv-brand">InspireVault</text>
        <text class="iv-kicker">THINKING STUDIO</text>
      </view>
      <view class="iv-row">
        <view class="iv-icon-circle" @click="switchTab('/pages/capture/index')">⌕</view>
        <view class="iv-icon-circle iv-muted-circle">◎</view>
      </view>
    </view>

    <text class="iv-section-title">Vault Metrics</text>
    <view class="iv-grid">
      <view class="iv-card iv-stat">
        <text class="iv-stat-icon">□</text>
        <text class="iv-label">Total Notes</text>
        <text class="iv-value">{{ metrics.totalFragments }}</text>
      </view>
      <view class="iv-card iv-stat">
        <text class="iv-stat-icon">★</text>
        <text class="iv-label">Starred Excerpts</text>
        <text class="iv-value">{{ metrics.favoriteFragments }}</text>
      </view>
      <view class="iv-card iv-stat">
        <text class="iv-stat-icon">◇</text>
        <text class="iv-label">Primary Source</text>
        <text class="iv-value compact">{{ metrics.primarySource }}</text>
      </view>
      <view class="iv-card iv-stat">
        <text class="iv-stat-icon">#</text>
        <text class="iv-label">Semantic Tags</text>
        <text class="iv-value">{{ metrics.tagCount }}</text>
      </view>
    </view>

    <text class="iv-section-title">Quick Study Tools</text>
    <view class="tool-row">
      <button class="iv-button tool-button" @click="switchTab('/pages/capture/index')">＋ New Capture</button>
      <button class="iv-outline-button tool-button" @click="switchTab('/pages/ai/index')">◎ AI Research</button>
    </view>
    <view class="tool-row" style="margin-top:16rpx;">
      <button class="iv-outline-button tool-button" @click="navigate('/pages/workspace/index')">⚙ Workspace</button>
      <button class="iv-outline-button tool-button" @click="navigate('/pages/archive/index')">▤ Archive</button>
    </view>

    <view class="iv-soft-card insight">
      <view class="iv-between">
        <view class="iv-row">
          <text class="spark">✦</text>
          <text class="insight-label">AI WEEKLY INSIGHT</text>
        </view>
        <text class="insight-time">Today</text>
      </view>
      <text class="insight-copy">{{ weeklyDigest }}</text>
      <view class="insight-actions">
        <button class="insight-primary" @click="syncState">↻ Re-analyze Studio</button>
        <button class="insight-secondary" @click="switchTab('/pages/ai/index')">View Map</button>
      </view>
    </view>
  </scroll-view>
</template>

<script>
import { vaultStore } from '../../store/vaultStore.js'

export default {
  data() {
    return {
      metrics: vaultStore.state.metrics,
      weeklyDigest: vaultStore.state.weeklyDigest
    }
  },
  onShow() {
    this.syncState()
  },
  methods: {
    syncState() {
      vaultStore.refresh()
      this.metrics = vaultStore.state.metrics
      this.weeklyDigest = vaultStore.state.weeklyDigest
    },
    switchTab(url) {
      if (!url) return
      uni.switchTab({ url })
    },
    navigate(url) {
      if (!url) return
      uni.navigateTo({ url })
    }
  }
}
</script>

<style scoped>
.dashboard {
  height: 100vh;
}

.compact {
  font-size: 27rpx;
}

.tool-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20rpx;
}

.tool-button {
  margin: 0;
  padding: 0 10rpx;
  line-height: 1.2;
  display: flex;
  align-items: center;
  justify-content: center;
}

.insight {
  margin-top: 36rpx;
  color: #001d35;
}

.spark {
  font-size: 34rpx;
  color: #004a77;
}

.insight-label {
  font-size: 22rpx;
  font-weight: 900;
  letter-spacing: 3rpx;
  color: #001d35;
}

.insight-time {
  font-size: 20rpx;
  font-weight: 600;
  color: rgba(0, 29, 53, 0.72);
}

.insight-copy {
  display: block;
  margin-top: 24rpx;
  font-size: 26rpx;
  line-height: 1.58;
  font-weight: 600;
  color: #001d35;
  white-space: pre-wrap;
}

.insight-actions {
  margin-top: 28rpx;
  display: flex;
  gap: 16rpx;
  flex-wrap: wrap;
}

.insight-primary,
.insight-secondary {
  min-height: 72rpx;
  border-radius: 999rpx;
  padding: 0 28rpx;
  margin: 0;
  font-size: 23rpx;
  font-weight: 800;
}

.insight-primary {
  background: #004a77;
  color: #ffffff;
}

.insight-secondary {
  background: transparent;
  color: #004a77;
  border: 1rpx solid #004a77;
}
</style>
