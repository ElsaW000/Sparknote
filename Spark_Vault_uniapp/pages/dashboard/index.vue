<!-- Spark_Vault_uniapp/pages/dashboard/index.vue -->
<template>
  <view class="page">
    <view class="hero">
      <text class="title">Spark Vault</text>
      <text class="subtitle">Thinking studio for captured fragments, reports, and synthesis.</text>
    </view>

    <view class="card-grid">
      <view class="card">
        <text class="label">Total Notes</text>
        <text class="value">{{ metrics.totalFragments }}</text>
      </view>
      <view class="card">
        <text class="label">Starred</text>
        <text class="value">{{ metrics.favoriteFragments }}</text>
      </view>
      <view class="card">
        <text class="label">Primary Source</text>
        <text class="value">{{ metrics.primarySource }}</text>
      </view>
      <view class="card">
        <text class="label">Tags</text>
        <text class="value">{{ metrics.tagCount }}</text>
      </view>
    </view>

    <view class="digest">
      <text class="section-title">Weekly Digest</text>
      <text class="digest-text">{{ weeklyDigest }}</text>
    </view>

    <view class="actions">
      <button type="primary" @click="switchTab('/pages/capture/index')">New Capture</button>
      <button @click="switchTab('/pages/workspace/index')">Open Workspace</button>
      <button @click="navigate('/pages/dashboard/metrics')">Metrics Detail</button>
    </view>
  </view>
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
    navigate(url) {
      if (!url) return
      uni.navigateTo({ url })
    },
    switchTab(url) {
      if (!url) return
      uni.switchTab({ url })
    }
  }
}
</script>

<style scoped>
.page { padding: 24rpx; }
.hero { margin-bottom: 24rpx; }
.title { font-size: 44rpx; font-weight: 700; display: block; color: #0f172a; }
.subtitle { font-size: 24rpx; color: #64748b; display: block; margin-top: 8rpx; }
.card-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16rpx; }
.card { background: #f4f7fb; border-radius: 16rpx; padding: 20rpx; min-height: 120rpx; }
.label { color: #64748b; font-size: 22rpx; display: block; }
.value { font-size: 30rpx; font-weight: 700; margin-top: 8rpx; display: block; color: #0f172a; word-break: break-word; }
.digest { margin-top: 24rpx; background: #e0f2fe; border-radius: 16rpx; padding: 20rpx; }
.section-title { display: block; font-size: 28rpx; font-weight: 700; color: #0f172a; margin-bottom: 10rpx; }
.digest-text { display: block; font-size: 24rpx; line-height: 1.6; color: #1e293b; white-space: pre-wrap; }
.actions { margin-top: 24rpx; display: flex; flex-direction: column; gap: 12rpx; }
</style>
