<!-- Spark_Vault_uniapp/pages/archive/index.vue -->
<template>
  <view class="page">
    <text class="title">Archive</text>
    <text class="subtitle">Workspace report history and vault maintenance.</text>

    <view class="summary">
      <text class="summary-item">Fragments: {{ metrics.totalFragments }}</text>
      <text class="summary-item">Reports: {{ metrics.reportCount }}</text>
    </view>

    <view class="list" v-if="reports.length">
      <view class="item" v-for="report in reports" :key="report.id" @click="openReport(report.id)">
        <text class="item-title">{{ report.title }}</text>
        <text class="item-sub">{{ report.userPrompt || 'No prompt saved' }}</text>
      </view>
    </view>
    <view class="empty" v-else>
      <text>No workspace reports yet.</text>
      <button type="primary" @click="switchTab('/pages/workspace/index')">Open Workspace</button>
    </view>

    <view class="actions">
      <button @click="loadSeeds">Load Seeds</button>
      <button @click="clearAll">Clear Local Vault</button>
    </view>
  </view>
</template>

<script>
import { vaultStore } from '../../store/vaultStore.js'

export default {
  data() {
    return {
      reports: [],
      metrics: vaultStore.state.metrics
    }
  },
  onShow() {
    this.syncState()
  },
  methods: {
    syncState() {
      vaultStore.refresh()
      this.reports = vaultStore.state.reports
      this.metrics = vaultStore.state.metrics
    },
    openReport(id) {
      if (!Number.isInteger(Number(id))) return
      uni.navigateTo({ url: `/pages/archive/report-detail?id=${id}` })
    },
    switchTab(url) {
      if (!url) return
      uni.switchTab({ url })
    },
    loadSeeds() {
      vaultStore.loadCuratedSeeds()
      this.syncState()
      uni.showToast({ title: 'Seeds loaded', icon: 'success' })
    },
    clearAll() {
      vaultStore.clearAll()
      this.syncState()
      uni.showToast({ title: 'Vault cleared', icon: 'success' })
    }
  }
}
</script>

<style scoped>
.page { padding: 24rpx; }
.title { font-size: 40rpx; font-weight: 700; display: block; color: #0f172a; }
.subtitle { font-size: 24rpx; color: #64748b; display: block; margin-top: 8rpx; }
.summary { margin-top: 18rpx; display: flex; gap: 12rpx; }
.summary-item { background: #f1f5f9; border-radius: 10rpx; padding: 12rpx; font-size: 24rpx; color: #334155; }
.list { margin-top: 20rpx; display: flex; flex-direction: column; gap: 12rpx; }
.item { background: #fff; border-radius: 14rpx; padding: 18rpx; border: 1px solid #e2e8f0; }
.item-title { display: block; font-size: 30rpx; font-weight: 600; color: #0f172a; }
.item-sub { display: block; font-size: 22rpx; color: #64748b; margin-top: 6rpx; }
.empty { margin-top: 24rpx; display: flex; flex-direction: column; gap: 16rpx; color: #64748b; font-size: 26rpx; }
.actions { margin-top: 24rpx; display: flex; flex-direction: column; gap: 10rpx; }
</style>
