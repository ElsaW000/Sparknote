<!-- pages/home/index.vue — Home Tab：成长概览 -->
<template>
  <scroll-view class="page" scroll-y>
    <!-- Header -->
    <view class="header">
      <view>
        <text class="title">Home</text>
        <text class="subtitle">你的个人成长伙伴</text>
      </view>
    </view>

    <!-- Empty state -->
    <view v-if="metrics.totalFragments === 0" class="empty-state">
      <text class="empty-icon">✦</text>
      <text class="empty-title">还没有记录</text>
      <text class="empty-desc">去写下今天的第一个想法吧</text>
      <button class="iv-button" @click="switchTab('/pages/library/index')">去 Library 记录 →</button>
    </view>

    <!-- Stats grid -->
    <view v-else>
      <view class="stat-grid">
        <view class="stat-card">
          <text class="stat-num">{{ metrics.totalFragments }}</text>
          <text class="stat-label">碎片总数</text>
        </view>
        <view class="stat-card">
          <text class="stat-num">{{ metrics.weeklyFragments }}</text>
          <text class="stat-label">本周录入</text>
        </view>
        <view class="stat-card">
          <text class="stat-num">{{ metrics.chatCount }}</text>
          <text class="stat-label">对话次数</text>
        </view>
        <view class="stat-card">
          <text class="stat-num">{{ metrics.reportCount }}</text>
          <text class="stat-label">生成报告</text>
        </view>
      </view>

      <!-- AI Digest -->
      <view class="digest-card">
        <view class="digest-header">
          <text class="digest-title">✦ 本周 AI Digest</text>
          <text class="digest-badge">自动生成</text>
        </view>
        <text class="digest-body">{{ weeklyDigest }}</text>
        <button class="digest-action" @click="startChat('memory')">💬 开始纠偏对话</button>
      </view>

      <!-- Reports section -->
      <view class="section">
        <view class="section-head">
          <text class="section-title">📋 报告历史</text>
          <text class="section-more" @click="navigate('/pages/report/list')">查看全部 ›</text>
        </view>
        <view v-if="recentReports.length">
          <view
            class="report-row"
            v-for="report in recentReports"
            :key="report.id"
            @click="navigate(`/pages/report/detail?id=${report.id}`)"
          >
            <view class="report-left">
              <text class="report-icon">📋</text>
              <view>
                <text class="report-name">{{ report.title }}</text>
                <text class="report-meta">{{ formatDate(report.created_at) }} · {{ report.month || '' }}</text>
              </view>
            </view>
            <text class="report-arrow">›</text>
          </view>
        </view>
        <view v-else class="no-reports">
          <text>还没有生成报告</text>
          <button class="outline-btn" @click="startChat('report')">生成第一份报告 →</button>
        </view>
      </view>
    </view>
  </scroll-view>
</template>

<script>
import { getVaultStore } from '@/store/vaultStore.js'

const store = getVaultStore()

export default {
  data() {
    return {
      metrics: { totalFragments: 0, weeklyFragments: 0, chatCount: 0, reportCount: 0 },
      weeklyDigest: '',
      recentReports: []
    }
  },
  onShow() {
    this.syncState()
  },
  methods: {
    syncState() {
      store.refresh()
      this.metrics = { ...store.state.metrics }
      this.weeklyDigest = store.state.weeklyDigest || '本周还没有足够的记录生成摘要。'
      this.recentReports = (store.state.reports || [])
        .slice()
        .sort((a, b) => (b.created_at || 0) - (a.created_at || 0))
        .slice(0, 3)
    },
    formatDate(ts) {
      if (!ts) return ''
      const d = new Date(ts)
      return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    },
    startChat(mode) {
      uni.switchTab({ url: '/pages/chat/index' })
      // Pass mode via storage so Chat tab can auto-open
      try { uni.setStorageSync('pending_chat_mode', mode) } catch (_) {}
    },
    navigate(url) {
      if (!url) return
      uni.navigateTo({ url })
    },
    switchTab(url) {
      uni.switchTab({ url })
    }
  }
}
</script>

<style scoped>
.page { background: #fbf9f6; padding: 24rpx; }
.header { margin-bottom: 28rpx; }
.title { display: block; font-size: 48rpx; font-weight: 800; color: #1c1b1f; }
.subtitle { display: block; font-size: 26rpx; color: #49454f; margin-top: 6rpx; }

/* Empty state */
.empty-state { display: flex; flex-direction: column; align-items: center; gap: 16rpx; margin-top: 80rpx; padding: 40rpx; }
.empty-icon { font-size: 64rpx; }
.empty-title { font-size: 36rpx; font-weight: 700; color: #1c1b1f; }
.empty-desc { font-size: 26rpx; color: #49454f; }
.iv-button { background: #004a77; color: #fff; border-radius: 24rpx; padding: 20rpx 40rpx; font-size: 28rpx; border: none; }

/* Stats */
.stat-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16rpx; margin-bottom: 24rpx; }
.stat-card { background: #ffffff; border-radius: 24rpx; padding: 24rpx; }
.stat-num { display: block; font-size: 52rpx; font-weight: 800; color: #004a77; }
.stat-label { display: block; font-size: 24rpx; color: #49454f; margin-top: 6rpx; }

/* Digest */
.digest-card { background: #004a77; border-radius: 24rpx; padding: 28rpx; margin-bottom: 28rpx; }
.digest-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16rpx; }
.digest-title { font-size: 30rpx; font-weight: 700; color: #ffffff; }
.digest-badge { font-size: 20rpx; color: rgba(255,255,255,0.7); background: rgba(255,255,255,0.15); padding: 4rpx 12rpx; border-radius: 20rpx; }
.digest-body { display: block; font-size: 26rpx; line-height: 1.7; color: rgba(255,255,255,0.9); margin-bottom: 20rpx; }
.digest-action { background: rgba(255,255,255,0.15); color: #ffffff; border: 1px solid rgba(255,255,255,0.3); border-radius: 20rpx; font-size: 26rpx; padding: 14rpx 24rpx; width: auto; }

/* Section */
.section { margin-bottom: 28rpx; }
.section-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16rpx; }
.section-title { font-size: 30rpx; font-weight: 700; color: #1c1b1f; }
.section-more { font-size: 26rpx; color: #004a77; }
.report-row { background: #ffffff; border-radius: 20rpx; padding: 20rpx 24rpx; margin-bottom: 12rpx; display: flex; justify-content: space-between; align-items: center; }
.report-left { display: flex; align-items: center; gap: 16rpx; flex: 1; }
.report-icon { font-size: 36rpx; }
.report-name { display: block; font-size: 28rpx; font-weight: 600; color: #1c1b1f; }
.report-meta { display: block; font-size: 22rpx; color: #49454f; margin-top: 4rpx; }
.report-arrow { font-size: 30rpx; color: #49454f; }
.no-reports { text-align: center; color: #49454f; font-size: 26rpx; padding: 30rpx; display: flex; flex-direction: column; align-items: center; gap: 16rpx; }
.outline-btn { background: transparent; color: #004a77; border: 2rpx solid #004a77; border-radius: 20rpx; font-size: 26rpx; padding: 14rpx 24rpx; }
</style>
