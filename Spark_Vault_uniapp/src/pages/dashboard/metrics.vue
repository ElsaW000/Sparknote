<!-- Spark_Vault_uniapp/pages/dashboard/metrics.vue -->
<template>
  <scroll-view class="iv-page metrics-page" scroll-y>
    <text class="iv-title">Metrics Detail</text>
    <text class="iv-subtitle">Vault activity, source distribution, and tag coverage.</text>

    <view class="iv-card iv-card-padded panel">
      <text class="row">Total Fragments: {{ metrics.totalFragments }}</text>
      <text class="row">Favorite Fragments: {{ metrics.favoriteFragments }}</text>
      <text class="row">Reports: {{ metrics.reportCount }}</text>
      <text class="row">Primary Source: {{ metrics.primarySource }}</text>
      <text class="row">Tag Count: {{ metrics.tagCount }}</text>
    </view>

    <view class="iv-card iv-card-padded panel">
      <text class="section-title">Source Distribution</text>
      <text class="row" v-for="item in sourceRows" :key="item.name">{{ item.name }}: {{ item.count }}</text>
      <text class="row" v-if="!sourceRows.length">No source data yet.</text>
    </view>

    <view class="iv-soft-card panel digest-panel">
      <text class="section-title">Weekly Insight</text>
      <text class="digest">{{ weeklyDigest }}</text>
    </view>
  </scroll-view>
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
.metrics-page { padding-bottom: 56rpx; }
.panel { margin-top: 20rpx; border-radius: 24rpx; }
.section-title { display: block; font-size: 28rpx; font-weight: 800; color: #004a77; margin-bottom: 8rpx; }
.row { display: block; padding: 14rpx 0; border-bottom: 1rpx solid #e6e1e5; font-size: 26rpx; color: #49454f; }
.row:last-child { border-bottom: 0; }
.digest-panel { margin-bottom: 32rpx; }
.digest { display: block; font-size: 24rpx; line-height: 1.6; color: #001d35; white-space: pre-wrap; }
</style>
