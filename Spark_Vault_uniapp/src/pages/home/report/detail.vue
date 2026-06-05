<!-- pages/home/report/detail.vue -->
<template>
  <view class="page">
    <view class="nav-bar">
      <text class="nav-back" @click="goBack">←</text>
      <text class="nav-title">{{ report.title || '报告详情' }}</text>
    </view>
    <scroll-view scroll-y class="body">
      <view v-if="!report.id" class="empty-state">
        <text class="empty-text">报告不存在或已删除</text>
      </view>
      <view v-else>
        <view class="meta-row">
          <text class="meta-date">{{ formatDate(report.created_at) }}</text>
          <text class="meta-month">{{ report.month }}</text>
        </view>
        <view class="content-card">
          <text class="content-text">{{ report.generatedContent || '（报告内容待生成）' }}</text>
        </view>
        <view class="feedback-row">
          <text class="feedback-label">这份报告对你有帮助吗？</text>
          <view class="feedback-btns">
            <text
              :class="['feedback-btn', feedback === 'up' ? 'active' : '']"
              @click="setFeedback('up')"
            >👍</text>
            <text
              :class="['feedback-btn', feedback === 'down' ? 'active' : '']"
              @click="setFeedback('down')"
            >👎</text>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script>
import { getVaultStore } from '../../../store/vaultStore.js'

export default {
  name: 'ReportDetail',
  data() {
    return {
      report: {},
      feedback: null
    }
  },
  onLoad(options) {
    if (options.id) {
      const store = getVaultStore()
      const r = store.getReportById ? store.getReportById(Number(options.id)) : null
      if (r) this.report = r
    }
  },
  methods: {
    setFeedback(type) {
      this.feedback = type
      uni.showToast({ title: type === 'up' ? '感谢反馈！' : '收到，我们会改进', icon: 'none', duration: 1500 })
    },
    goBack() { uni.navigateBack() },
    formatDate(ts) {
      if (!ts) return ''
      const d = new Date(ts)
      return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`
    }
  }
}
</script>

<style scoped>
.page { min-height: 100vh; background: #fbf9f6; }
.nav-bar { display: flex; align-items: center; gap: 16rpx; padding: 60rpx 32rpx 24rpx; background: #fff; border-bottom: 1rpx solid #f0f0f0; }
.nav-back { font-size: 40rpx; color: #333; padding: 8rpx; }
.nav-title { font-size: 30rpx; font-weight: 600; color: #1a1a2e; }
.body { padding: 32rpx; }
.empty-state { text-align: center; padding: 80rpx 0; }
.empty-text { font-size: 28rpx; color: #aaa; }
.meta-row { display: flex; align-items: center; gap: 16rpx; margin-bottom: 20rpx; }
.meta-date { font-size: 24rpx; color: #aaa; }
.meta-month { font-size: 24rpx; color: #888; background: #f0f0f0; padding: 4rpx 16rpx; border-radius: 20rpx; }
.content-card { background: #fff; border-radius: 20rpx; padding: 36rpx; margin-bottom: 32rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06); }
.content-text { font-size: 28rpx; color: #1a1a2e; line-height: 1.8; white-space: pre-wrap; }
.feedback-row { background: #fff; border-radius: 20rpx; padding: 28rpx 32rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06); text-align: center; }
.feedback-label { display: block; font-size: 26rpx; color: #555; margin-bottom: 20rpx; }
.feedback-btns { display: flex; justify-content: center; gap: 40rpx; }
.feedback-btn { font-size: 48rpx; padding: 12rpx; opacity: 0.5; }
.feedback-btn.active { opacity: 1; }
</style>
