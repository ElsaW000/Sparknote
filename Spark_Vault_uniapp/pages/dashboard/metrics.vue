<!-- Spark_Vault_uniapp/pages/dashboard/metrics.vue -->
<template>
  <view class="page">
    <text class="title">Metrics Detail</text>
    <text class="subtitle">Vault activity, source distribution, and tag coverage.</text>

    <view class="panel">
      <text class="row">Total Fragments: {{ metrics.totalFragments }}</text>
      <text class="row">Favorite Fragments: {{ metrics.favoriteFragments }}</text>
      <text class="row">Reports: {{ metrics.reportCount }}</text>
      <text class="row">Primary Source: {{ metrics.primarySource }}</text>
      <text class="row">Tag Count: {{ metrics.tagCount }}</text>
    </view>

    <view class="panel">
      <text class="section-title">Source Distribution</text>
      <text class="row" v-for="item in sourceRows" :key="item.name">{{ item.name }}: {{ item.count }}</text>
      <text class="row" v-if="!sourceRows.length">No source data yet.</text>
    </view>

    <view class="panel">
      <text class="section-title">Weekly Insight</text>
      <text class="digest">{{ weeklyDigest }}</text>
    </view>
  </view>
</template>

<script>
import { vaultStore } from '../../store/vaultStore.js'

export default {
  data() {
    return {
      metrics: vaultStore.state.metrics,
      sourceRows: [],
      weeklyDigest: ''
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
      this.sourceRows = Object.entries(this.metrics.sourceCounts || {}).map(([name, count]) => ({ name, count }))
    }
  }
}
</script>

<style scoped>
.page { padding: 24rpx; }
.title { font-size: 38rpx; font-weight: 700; display: block; color: #0f172a; }
.subtitle { font-size: 24rpx; color: #64748b; display: block; margin-top: 8rpx; }
.panel { margin-top: 18rpx; background: #f8fafc; border-radius: 12rpx; padding: 14rpx; }
.section-title { display: block; font-size: 28rpx; font-weight: 700; color: #0f172a; margin-bottom: 8rpx; }
.row { display: block; padding: 12rpx 0; border-bottom: 1px solid #e2e8f0; font-size: 26rpx; color: #334155; }
.row:last-child { border-bottom: 0; }
.digest { display: block; font-size: 24rpx; line-height: 1.6; color: #334155; white-space: pre-wrap; }
</style>
