<!-- Spark_Vault_uniapp/src/pages/home/index.vue -->
<template>
  <scroll-view scroll-y class="sv-page">
    <view class="sv-header">
      <view>
        <text class="sv-kicker">{{ todayLabel }} / GMT+8</text>
        <text class="sv-title">首页概览 <text class="sv-title-mark">. Today</text></text>
      </view>
      <text class="sv-pill">记录中</text>
    </view>

    <view class="sv-grid-2">
      <view class="sv-cream-card metric-card">
        <view class="sv-between">
          <text class="sv-label">全部记录</text>
          <text class="metric-icon">□</text>
        </view>
        <text class="sv-value">{{ metrics.totalFragments }}</text>
        <view class="sv-progress">
          <view class="sv-progress-fill" :style="{ width: fragmentProgress + '%' }" />
        </view>
      </view>

      <view class="sv-cream-card metric-card">
        <view class="sv-between">
          <text class="sv-label">收藏</text>
          <text class="metric-icon">☆</text>
        </view>
        <text class="sv-value">{{ metrics.favoriteFragments }}</text>
        <view class="sv-progress">
          <view class="sv-progress-fill navy-fill" :style="{ width: favoriteProgress + '%' }" />
        </view>
      </view>

      <view class="sv-cream-card metric-card">
        <view class="sv-between">
          <text class="sv-label">标签</text>
          <text class="metric-icon">#</text>
        </view>
        <text class="sv-value">{{ metrics.tagCount }}</text>
      </view>

      <view class="sv-cream-card metric-card">
        <view class="sv-between">
          <text class="sv-label">主要来源</text>
          <text class="metric-icon">◇</text>
        </view>
        <text class="source-main">{{ metrics.primarySource }}</text>
      </view>
    </view>

    <view class="sv-navy-card insight-card">
      <view class="gold-badge">今日提醒</view>
      <text class="insight-title">《{{ currentMonth }} · 记录回顾》已就绪</text>
      <text class="insight-copy">
        根据最近的记录和对话，建议今晚做一次简短回顾：从最新内容里选一条，写下它真正提醒你的事。
      </text>
      <view class="insight-footer">
        <text class="insight-ref">最近整理</text>
        <text class="insight-link" @click="goReports">查看回顾 ></text>
      </view>
    </view>

    <LibraryPage ref="libraryPanel" embedded />
  </scroll-view>
</template>

<script>
import LibraryPage from '../library/index.vue'
import { getVaultStore } from '../../store/vaultStore.js'

export default {
  name: 'HomePage',
  components: { LibraryPage },
  data() {
    return {
      metrics: { totalFragments: 0, favoriteFragments: 0, tagCount: 0, primarySource: 'Other' },
      fragments: []
    }
  },
  computed: {
    todayLabel() {
      const d = new Date()
      return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}`
    },
    currentMonth() {
      const d = new Date()
      return `${d.getFullYear()}年${d.getMonth() + 1}月`
    },
    recentFragments() {
      return this.fragments.slice(0, 2)
    },
    fragmentProgress() {
      return Math.min(100, this.metrics.totalFragments * 10)
    },
    favoriteProgress() {
      if (!this.metrics.totalFragments) return 0
      return Math.min(100, Math.round((this.metrics.favoriteFragments / this.metrics.totalFragments) * 100))
    }
  },
  onShow() {
    this.loadData()
    this.openEmbeddedQuickComposer()
  },
  methods: {
    loadData() {
      const store = getVaultStore()
      store.refresh()
      this.metrics = store.state.metrics
      this.fragments = store.state.fragments
    },
    goCapture() {
      uni.navigateTo({ url: '/pages/capture/index' })
    },
    goAiLab() {
      uni.navigateTo({ url: '/pages/ai/index' })
    },
    goWorkspace() {
      uni.switchTab({ url: '/pages/workspace/index' })
    },
    goReports() {
      uni.navigateTo({ url: '/pages/home/report/index' })
    },
    openEmbeddedQuickComposer() {
      let shouldOpen = false
      try {
        shouldOpen = uni.getStorageSync('mirrorme_open_quick_composer') === '1'
        if (shouldOpen) uni.removeStorageSync('mirrorme_open_quick_composer')
      } catch (_) {
        shouldOpen = false
      }
      if (!shouldOpen) return
      this.$nextTick(() => {
        const panel = this.$refs.libraryPanel
        if (panel && typeof panel.openQuickComposer === 'function') panel.openQuickComposer()
      })
    },
    goEditor(id) {
      if (!Number.isInteger(Number(id))) return
      uni.navigateTo({ url: `/pages/library/editor?id=${id}` })
    },
    formatDate(ts) {
      if (!ts) return ''
      const d = new Date(ts)
      return `${d.getMonth() + 1}/${d.getDate()}`
    }
  }
}
</script>

<style scoped>
.metric-card {
  min-height: 186rpx;
}

.metric-icon {
  color: #c4a052;
  font-size: 28rpx;
  flex-shrink: 0;
}

.shortcut-icon-svg {
  width: 30rpx;
  height: 30rpx;
}

.navy-fill {
  background: #1a2b48;
}

.source-main {
  display: block;
  margin-top: 14rpx;
  color: #1a2b48;
  font-size: 30rpx;
  line-height: 1.1;
  font-weight: 900;
}

.insight-card {
  margin-top: 24rpx;
}

.gold-badge {
  display: inline-flex;
  width: fit-content;
  padding: 7rpx 16rpx;
  border-radius: 999rpx;
  background: rgba(196, 160, 82, 0.18);
  border: 1rpx solid rgba(196, 160, 82, 0.35);
  color: #c4a052;
  font-family: "Courier New", monospace;
  font-size: 17rpx;
  font-weight: 900;
  letter-spacing: 2rpx;
}

.insight-title {
  display: block;
  margin-top: 20rpx;
  color: rgba(255, 255, 255, 0.96);
  font-size: 28rpx;
  line-height: 1.35;
  font-weight: 900;
  font-style: italic;
}

.insight-copy {
  display: block;
  margin-top: 14rpx;
  color: rgba(255, 255, 255, 0.72);
  font-size: 23rpx;
  line-height: 1.6;
}

.insight-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 26rpx;
  padding-top: 20rpx;
  border-top: 1rpx solid rgba(255, 255, 255, 0.1);
}

.insight-ref {
  color: rgba(255, 255, 255, 0.4);
  font-family: "Courier New", monospace;
  font-size: 17rpx;
}

.insight-link {
  color: #c4a052;
  font-size: 22rpx;
  font-weight: 900;
}

.shortcut-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 18rpx;
}

.shortcut-card {
  display: flex;
  align-items: center;
  gap: 18rpx;
  min-height: 110rpx;
  padding: 20rpx;
  border: 1rpx solid #dedacf;
  border-radius: 22rpx;
  background: #ffffff;
  box-sizing: border-box;
}

.shortcut-icon {
  width: 56rpx;
  height: 56rpx;
  border-radius: 18rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f2f0e9;
  color: #c4a052;
  font-size: 28rpx;
  font-weight: 900;
}

.shortcut-title {
  display: block;
  color: #1a2b48;
  font-size: 22rpx;
  line-height: 1.2;
  font-weight: 900;
}

.shortcut-sub {
  display: block;
  margin-top: 4rpx;
  color: rgba(26, 26, 26, 0.45);
  font-family: "Courier New", monospace;
  font-size: 16rpx;
}

.recent-head {
  margin-top: 4rpx;
}

.recent-section {
  margin-bottom: 0;
}

.empty-card,
.spark-card {
  margin-top: 16rpx;
}

.type-badge {
  padding: 5rpx 12rpx;
  border-radius: 9rpx;
  border: 1rpx solid #f1d9a8;
  background: #fff8e8;
  color: #8a5e13;
  font-family: "Courier New", monospace;
  font-size: 16rpx;
  font-weight: 900;
}

.spark-title {
  display: block;
  margin-top: 18rpx;
  color: #1a2b48;
  font-size: 24rpx;
  line-height: 1.35;
  font-weight: 900;
}

.spark-copy {
  display: block;
  margin-top: 10rpx;
  color: rgba(26, 26, 26, 0.7);
  font-size: 22rpx;
  line-height: 1.55;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.tag-row {
  display: flex;
  gap: 8rpx;
  flex-wrap: wrap;
  margin-top: 14rpx;
}

.empty-title {
  display: block;
  color: #1a2b48;
  font-size: 26rpx;
  font-weight: 900;
  margin-bottom: 8rpx;
}
</style>
