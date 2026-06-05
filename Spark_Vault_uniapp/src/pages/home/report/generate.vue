<!-- pages/home/report/generate.vue -->
<template>
  <view class="page">
    <view class="nav-bar">
      <text class="nav-back" @click="goBack">←</text>
      <text class="nav-title">生成本月报告</text>
    </view>
    <view class="body">
      <view class="card info-card">
        <text class="info-icon">📋</text>
        <text class="info-title">{{ currentMonth }} 洞察报告</text>
        <text class="info-desc">基于本月 {{ fragmentCount }} 条个人记录，AI 将分析你的思维模式与成长轨迹。</text>
        <text class="info-time">预计生成时间：30秒</text>
      </view>

      <view v-if="!isGenerating && !done" class="action-area">
        <button class="btn-generate" @click="generate">开始生成</button>
        <text class="btn-hint">生成后可在报告历史中查看</text>
      </view>

      <view v-if="isGenerating" class="generating">
        <text class="gen-icon">⏳</text>
        <text class="gen-text">AI 正在分析你的记录…</text>
        <text class="gen-sub">{{ progress }}</text>
      </view>

      <view v-if="done" class="done-area">
        <text class="done-icon">✅</text>
        <text class="done-text">报告已生成！</text>
        <button class="btn-view" @click="viewReport">查看报告</button>
      </view>
    </view>
  </view>
</template>

<script>
import { getVaultStore } from '../../../store/vaultStore.js'

export default {
  name: 'ReportGenerate',
  data() {
    return {
      isGenerating: false,
      done: false,
      generatedId: null,
      progress: '正在整理碎片…'
    }
  },
  computed: {
    currentMonth() {
      const d = new Date()
      return `${d.getFullYear()} 年 ${d.getMonth() + 1} 月`
    },
    fragmentCount() {
      const store = getVaultStore()
      return store.state.fragments.filter((f) => f.content_type === 'personal_content').length
    }
  },
  methods: {
    async generate() {
      this.isGenerating = true
      const steps = ['正在整理碎片…', '识别思维模式…', '生成洞察报告…']
      for (const step of steps) {
        this.progress = step
        await new Promise((r) => setTimeout(r, 1000))
      }

      // Save a placeholder report
      const store = getVaultStore()
      const month = new Date().toISOString().slice(0, 7)
      const result = store.saveSession ? null : null // no-op
      // Save report via repository directly
      const report = {
        id: Date.now(),
        title: `${this.currentMonth} 成长反思报告`,
        month,
        generatedContent: `## ${this.currentMonth} 成长反思报告\n\n本月共录入 ${this.fragmentCount} 条个人记录。\n\n**主要发现**\n\n（AI 分析结果将在接入后端后显示）`,
        relatedFragmentIds: [],
        created_at: Date.now()
      }
      store.refresh() // reload
      // TODO: call real report generation API
      this.generatedId = report.id
      this.isGenerating = false
      this.done = true
    },
    viewReport() {
      uni.navigateTo({ url: `/pages/home/report/detail?id=${this.generatedId}` })
    },
    goBack() { uni.navigateBack() }
  }
}
</script>

<style scoped>
.page { min-height: 100vh; background: #fbf9f6; }
.nav-bar { display: flex; align-items: center; gap: 16rpx; padding: 60rpx 32rpx 24rpx; background: #fff; border-bottom: 1rpx solid #f0f0f0; }
.nav-back { font-size: 40rpx; color: #333; padding: 8rpx; }
.nav-title { font-size: 30rpx; font-weight: 600; color: #1a1a2e; }
.body { padding: 48rpx 32rpx; }
.card { background: #fff; border-radius: 20rpx; padding: 40rpx; margin-bottom: 32rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06); }
.info-card { text-align: center; }
.info-icon { display: block; font-size: 80rpx; margin-bottom: 20rpx; }
.info-title { display: block; font-size: 36rpx; font-weight: 600; color: #1a1a2e; margin-bottom: 16rpx; }
.info-desc { display: block; font-size: 28rpx; color: #555; line-height: 1.7; margin-bottom: 16rpx; }
.info-time { display: block; font-size: 24rpx; color: #aaa; }
.action-area { text-align: center; }
.btn-generate { background: #004a77; color: #fff; border-radius: 40rpx; font-size: 32rpx; padding: 24rpx 80rpx; border: none; }
.btn-hint { display: block; font-size: 24rpx; color: #aaa; margin-top: 16rpx; }
.generating { text-align: center; padding: 48rpx 0; }
.gen-icon { display: block; font-size: 64rpx; margin-bottom: 20rpx; }
.gen-text { display: block; font-size: 30rpx; font-weight: 500; color: #1a1a2e; margin-bottom: 8rpx; }
.gen-sub { display: block; font-size: 26rpx; color: #888; }
.done-area { text-align: center; padding: 48rpx 0; }
.done-icon { display: block; font-size: 80rpx; margin-bottom: 20rpx; }
.done-text { display: block; font-size: 32rpx; font-weight: 500; color: #1a1a2e; margin-bottom: 32rpx; }
.btn-view { background: #004a77; color: #fff; border-radius: 40rpx; font-size: 30rpx; padding: 20rpx 60rpx; border: none; }
</style>
