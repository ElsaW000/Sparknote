<!-- pages/home/report/generate.vue -->
<template>
  <view class="page">
    <view class="nav-bar">
      <text class="nav-back" @click="goBack">返回</text>
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
      if (this.isGenerating) return
      this.isGenerating = true
      this.done = false
      const steps = ['正在整理碎片…', '识别思维模式…', '生成洞察报告…']
      for (const step of steps) {
        this.progress = step
        await new Promise((r) => setTimeout(r, 1000))
      }

      const store = getVaultStore()
      store.refresh()
      const month = new Date().toISOString().slice(0, 7)
      const fragments = store.state.fragments.filter((f) => f.content_type === 'personal_content')
      const fragmentLines = fragments.length
        ? fragments.slice(0, 8).map((f, index) => `${index + 1}. ${f.title || f.sourceTitle || '未命名'}：${(f.content || f.originalText || '').slice(0, 120)}`).join('\n')
        : '本月还没有个人记录。请先在碎片库或采集页保存内容。'
      const result = store.saveReport({
        title: `${this.currentMonth} 成长反思报告`,
        month,
        generatedContent: [
          `## ${this.currentMonth} 成长反思报告`,
          '',
          `本月共录入 ${fragments.length} 条个人记录。`,
          '',
          '**主要记录**',
          fragmentLines,
          '',
          '**建议行动**',
          '- 选择一条最重要的记录，补充它触发你的真实原因。',
          '- 将相似主题的记录合并成一个可复盘的问题。',
          '- 下次记录时同时写下场景、感受和下一步动作。'
        ].join('\n'),
        relatedFragmentIds: fragments.map((f) => f.id).filter(Number.isInteger),
        created_at: Date.now()
      })
      if (!result.ok) {
        this.isGenerating = false
        uni.showToast({ title: result.error || '生成失败', icon: 'none' })
        return
      }
      this.generatedId = result.report.id
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
.nav-back {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 84rpx;
  height: 52rpx;
  padding: 0 18rpx;
  border: 1rpx solid #dedacf;
  border-radius: 999rpx;
  background: #f8f7f2;
  color: #1a2b48;
  font-size: 24rpx;
  font-weight: 800;
  box-sizing: border-box;
}
.nav-title { font-size: 34rpx; font-weight: 800; color: #1a1a2e; }
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
