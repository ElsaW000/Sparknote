<!-- pages/report/detail.vue — 报告详情 -->
<template>
  <scroll-view class="page" scroll-y>
    <!-- Nav -->
    <view class="nav">
      <text class="nav-back" @click="back">←</text>
      <text class="nav-title">{{ report ? report.title || '成长报告' : '报告' }}</text>
      <view style="width: 60rpx;" />
    </view>

    <!-- Report content -->
    <view v-if="report" class="content-area">
      <!-- Meta -->
      <view class="meta-row">
        <text class="meta-date">{{ formatDate(report.created_at) }}</text>
        <view class="type-chip">
          <text class="type-text">{{ typeName(report.type) }}</text>
        </view>
      </view>

      <!-- Content -->
      <view class="report-body">
        <text class="report-text">{{ report.content }}</text>
      </view>

      <!-- Feedback section -->
      <view class="feedback-section">
        <text class="feedback-title">这份报告准确吗？</text>
        <text class="feedback-sub">你的反馈帮助 AI 更准确地理解你</text>

        <view class="feedback-options">
          <view
            :class="['feedback-btn', selectedFeedback === 'accurate' && 'selected-green']"
            @click="selectFeedback('accurate')"
          >
            <text class="feedback-icon">✅</text>
            <text class="feedback-label">基本准确</text>
          </view>
          <view
            :class="['feedback-btn', selectedFeedback === 'partial' && 'selected-yellow']"
            @click="selectFeedback('partial')"
          >
            <text class="feedback-icon">⚠️</text>
            <text class="feedback-label">不完全对</text>
          </view>
          <view
            :class="['feedback-btn', selectedFeedback === 'wrong' && 'selected-red']"
            @click="selectFeedback('wrong')"
          >
            <text class="feedback-icon">🙅</text>
            <text class="feedback-label">没这么严重</text>
          </view>
        </view>

        <!-- Supplement input -->
        <view v-if="selectedFeedback && selectedFeedback !== 'accurate'" class="supplement-area">
          <text class="supplement-label">补充说明（可选）</text>
          <textarea
            class="supplement-input"
            v-model="supplement"
            placeholder="哪里不准确？说说你的实际感受…"
            :maxlength="300"
          />
        </view>

        <view
          v-if="selectedFeedback"
          :class="['submit-btn', feedbackSaved && 'submitted']"
          @click="submitFeedback"
        >
          <text class="submit-text">{{ feedbackSaved ? '✓ 已记录' : '提交反馈' }}</text>
        </view>
      </view>
    </view>

    <!-- Not found -->
    <view v-else class="not-found">
      <text class="nf-icon">🔍</text>
      <text class="nf-text">报告不存在或已删除</text>
      <view class="nf-back-btn" @click="back">
        <text class="nf-back-text">返回列表</text>
      </view>
    </view>

    <view style="height: 60rpx;" />
  </scroll-view>
</template>

<script>
import { getVaultStore } from '@/store/vaultStore.js'

const store = getVaultStore()

const TYPE_NAMES = { weekly: '周报', reflection: '反思报告', report: 'AI 报告' }

export default {
  data() {
    return {
      report: null,
      selectedFeedback: null,
      supplement: '',
      feedbackSaved: false
    }
  },
  onLoad(options) {
    store.refresh()
    if (options.id) {
      this.report = store.getReportById(Number(options.id)) || null
    }
  },
  methods: {
    back() {
      uni.navigateBack()
    },
    typeName(type) {
      return TYPE_NAMES[type] || 'AI 报告'
    },
    formatDate(ts) {
      if (!ts) return ''
      const d = new Date(ts)
      return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`
    },
    selectFeedback(val) {
      this.selectedFeedback = val
      this.feedbackSaved = false
    },
    submitFeedback() {
      if (this.feedbackSaved) return
      // Save feedback alongside report (could be extended to backend later)
      const feedback = {
        rating: this.selectedFeedback,
        supplement: this.supplement
      }
      if (this.report) {
        store.updateSession && null // reports don't have updateReport yet – store locally
        const key = `feedback_${this.report.id}`
        uni.setStorageSync(key, feedback)
      }
      this.feedbackSaved = true
      uni.showToast({ title: '反馈已记录', icon: 'success', duration: 1200 })
    }
  }
}
</script>

<style scoped>
.page { background: #fbf9f6; }

/* Nav */
.nav { display: flex; align-items: center; padding: 20rpx 28rpx; background: #ffffff; border-bottom: 2rpx solid #f0ece6; }
.nav-back { font-size: 36rpx; color: #1c1b1f; padding: 4rpx 16rpx 4rpx 0; }
.nav-title { flex: 1; font-size: 30rpx; font-weight: 700; color: #1c1b1f; text-align: center; }

/* Content */
.content-area { padding: 24rpx; }
.meta-row { display: flex; align-items: center; gap: 16rpx; margin-bottom: 20rpx; }
.meta-date { font-size: 24rpx; color: #49454f; flex: 1; }
.type-chip { background: #e8f0f8; border-radius: 12rpx; padding: 6rpx 14rpx; }
.type-text { font-size: 20rpx; color: #004a77; font-weight: 600; }

.report-body { background: #ffffff; border-radius: 24rpx; padding: 28rpx; margin-bottom: 28rpx; min-height: 200rpx; }
.report-text { font-size: 28rpx; color: #1c1b1f; line-height: 1.8; white-space: pre-wrap; display: block; }

/* Feedback */
.feedback-section { background: #ffffff; border-radius: 24rpx; padding: 28rpx; }
.feedback-title { display: block; font-size: 30rpx; font-weight: 700; color: #1c1b1f; margin-bottom: 8rpx; }
.feedback-sub { display: block; font-size: 24rpx; color: #49454f; margin-bottom: 24rpx; }

.feedback-options { display: flex; gap: 16rpx; margin-bottom: 20rpx; }
.feedback-btn { flex: 1; text-align: center; background: #f5f2ee; border-radius: 20rpx; padding: 18rpx 8rpx; border: 2rpx solid transparent; }
.selected-green { background: #e6f4e6; border-color: #4caf50; }
.selected-yellow { background: #fff8e1; border-color: #ffc107; }
.selected-red { background: #fdecea; border-color: #f44336; }
.feedback-icon { display: block; font-size: 36rpx; margin-bottom: 6rpx; }
.feedback-label { display: block; font-size: 22rpx; color: #1c1b1f; }

.supplement-area { margin-bottom: 20rpx; }
.supplement-label { display: block; font-size: 24rpx; color: #49454f; margin-bottom: 10rpx; }
.supplement-input { width: 100%; font-size: 26rpx; color: #1c1b1f; background: #f5f2ee; border-radius: 14rpx; padding: 14rpx 16rpx; min-height: 120rpx; line-height: 1.6; }

.submit-btn { background: #004a77; border-radius: 20rpx; padding: 20rpx; text-align: center; }
.submit-btn.submitted { background: #4caf50; }
.submit-text { font-size: 28rpx; color: #ffffff; font-weight: 600; }

/* Not found */
.not-found { text-align: center; padding: 120rpx 40rpx; }
.nf-icon { display: block; font-size: 80rpx; margin-bottom: 20rpx; }
.nf-text { display: block; font-size: 30rpx; color: #49454f; margin-bottom: 32rpx; }
.nf-back-btn { background: #004a77; border-radius: 20rpx; padding: 18rpx 40rpx; display: inline-block; }
.nf-back-text { font-size: 28rpx; color: #ffffff; }
</style>
