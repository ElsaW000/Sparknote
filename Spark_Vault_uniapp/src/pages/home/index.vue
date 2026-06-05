<!-- pages/home/index.vue -->
<template>
  <view class="page">
    <!-- Header -->
    <view class="header">
      <view>
        <text class="title">Home</text>
        <text class="subtitle">你的个人成长伙伴</text>
      </view>
    </view>

    <!-- Stats Row -->
    <view class="stats-row">
      <view class="stat-item">
        <text class="stat-num">{{ metrics.totalFragments }}</text>
        <text class="stat-label">碎片总数</text>
      </view>
      <view class="stat-item">
        <text class="stat-num">{{ metrics.weeklyFragments }}</text>
        <text class="stat-label">本周录入</text>
      </view>
      <view class="stat-item">
        <text class="stat-num">{{ metrics.chatCount }}</text>
        <text class="stat-label">对话次数</text>
      </view>
      <view class="stat-item">
        <text class="stat-num">{{ metrics.reportCount }}</text>
        <text class="stat-label">生成报告</text>
      </view>
    </view>

    <!-- AI Digest Card -->
    <view class="card digest-card">
      <view class="digest-header">
        <text class="digest-badge">✦ 本周 AI Digest · 自动生成</text>
      </view>
      <text class="digest-text">{{ weeklyDigest }}</text>
      <button class="btn-primary" @click="startChat('memory')">💬 开始纠偏对话</button>
    </view>

    <!-- Report History -->
    <view class="section-header">
      <text class="section-title">📋 报告历史</text>
      <text class="section-more" @click="goReports">全部 ›</text>
    </view>

    <view v-if="reports.length === 0" class="empty-state">
      <text class="empty-text">还没有报告。开始对话后可生成报告。</text>
    </view>

    <view v-else class="report-list">
      <view
        v-for="report in recentReports"
        :key="report.id"
        class="report-item card"
        @click="goReportDetail(report.id)"
      >
        <text class="report-icon">📋</text>
        <view class="report-info">
          <text class="report-title">{{ report.title }}</text>
          <text class="report-meta">{{ formatDate(report.created_at) }}</text>
        </view>
        <text class="arrow">›</text>
      </view>
    </view>
  </view>
</template>

<script>
import { getVaultStore } from '../../store/vaultStore.js'

export default {
  name: 'HomePage',
  data() {
    return {
      metrics: { totalFragments: 0, weeklyFragments: 0, chatCount: 0, reportCount: 0 },
      weeklyDigest: '',
      reports: []
    }
  },
  computed: {
    recentReports() {
      return this.reports.slice(0, 3)
    }
  },
  onShow() {
    this.loadData()
  },
  methods: {
    loadData() {
      const store = getVaultStore()
      store.refresh()
      this.metrics = store.state.metrics
      this.weeklyDigest = store.state.weeklyDigest
      this.reports = store.state.reports
    },
    startChat(mode) {
      uni.switchTab({ url: '/pages/chat/index' })
    },
    goReports() {
      uni.navigateTo({ url: '/pages/home/report/index' })
    },
    goReportDetail(id) {
      uni.navigateTo({ url: `/pages/home/report/detail?id=${id}` })
    },
    formatDate(ts) {
      if (!ts) return ''
      const d = new Date(ts)
      return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    }
  }
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  background: #fbf9f6;
  padding: 48rpx 32rpx 32rpx;
  box-sizing: border-box;
}
.header {
  margin-bottom: 40rpx;
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
.stats-row {
  display: flex;
  background: #fff;
  border-radius: 20rpx;
  padding: 32rpx 0;
  margin-bottom: 32rpx;
  box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06);
}
.stat-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.stat-num {
  font-size: 52rpx;
  font-weight: 700;
  color: #004a77;
}
.stat-label {
  font-size: 22rpx;
  color: #888;
  margin-top: 4rpx;
}
.card {
  background: #fff;
  border-radius: 20rpx;
  padding: 32rpx;
  margin-bottom: 24rpx;
  box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06);
}
.digest-card {
  background: #eaf4ff;
}
.digest-header {
  margin-bottom: 16rpx;
}
.digest-badge {
  font-size: 24rpx;
  font-weight: 600;
  color: #004a77;
}
.digest-text {
  display: block;
  font-size: 28rpx;
  color: #333;
  line-height: 1.6;
  margin-bottom: 24rpx;
}
.btn-primary {
  width: 100%;
  background: #004a77;
  color: #fff;
  border-radius: 12rpx;
  font-size: 28rpx;
  padding: 20rpx 0;
  border: none;
}
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16rpx;
}
.section-title {
  font-size: 32rpx;
  font-weight: 600;
  color: #1a1a2e;
}
.section-more {
  font-size: 26rpx;
  color: #004a77;
}
.empty-state {
  text-align: center;
  padding: 48rpx 0;
}
.empty-text {
  font-size: 26rpx;
  color: #aaa;
}
.report-list {}
.report-item {
  display: flex;
  align-items: center;
  gap: 20rpx;
}
.report-icon {
  font-size: 36rpx;
}
.report-info {
  flex: 1;
}
.report-title {
  display: block;
  font-size: 28rpx;
  font-weight: 500;
  color: #1a1a2e;
}
.report-meta {
  display: block;
  font-size: 22rpx;
  color: #aaa;
  margin-top: 4rpx;
}
.arrow {
  font-size: 32rpx;
  color: #ccc;
}
</style>
