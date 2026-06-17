<!-- pages/home/report/index.vue -->
<template>
  <view class="page">
    <view class="nav-bar">
      <text class="nav-back" @click="goBack">返回</text>
      <text class="nav-title">报告历史</text>
      <text class="nav-action" @click="goGenerate">生成</text>
    </view>
    <scroll-view scroll-y class="body">
      <view v-if="reports.length === 0" class="empty-state">
        <text class="empty-icon">📋</text>
        <text class="empty-text">还没有报告</text>
        <button class="btn-generate" @click="goGenerate">生成本月报告</button>
      </view>
      <view v-else>
        <view v-for="(group, month) in grouped" :key="month">
          <text class="month-label">{{ month }}</text>
          <view
            v-for="r in group"
            :key="r.id"
            class="report-item card"
            @click="goDetail(r.id)"
          >
            <text class="r-icon">📋</text>
            <view class="r-info">
              <text class="r-title">{{ r.title }}</text>
              <text class="r-meta">{{ formatDate(r.created_at) }}</text>
            </view>
            <text class="arrow">查看</text>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script>
import { getVaultStore } from '../../../store/vaultStore.js'

export default {
  name: 'ReportIndex',
  data() { return { reports: [] } },
  computed: {
    grouped() {
      return this.reports.reduce((acc, r) => {
        const m = r.month || '未知月份'
        if (!acc[m]) acc[m] = []
        acc[m].push(r)
        return acc
      }, {})
    }
  },
  onShow() {
    const store = getVaultStore()
    store.refresh()
    this.reports = store.state.reports
  },
  methods: {
    goGenerate() { uni.navigateTo({ url: '/pages/home/report/generate' }) },
    goDetail(id) { uni.navigateTo({ url: `/pages/home/report/detail?id=${id}` }) },
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
.nav-back,
.nav-action {
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
.nav-action { background: #1a2b48; border-color: #1a2b48; color: #c4a052; }
.nav-title { flex: 1; font-size: 34rpx; font-weight: 800; color: #1a1a2e; }
.body { padding: 32rpx; }
.empty-state { text-align: center; padding: 80rpx 0; }
.empty-icon { display: block; font-size: 80rpx; margin-bottom: 20rpx; }
.empty-text { display: block; font-size: 28rpx; color: #aaa; margin-bottom: 32rpx; }
.btn-generate { background: #004a77; color: #fff; border-radius: 40rpx; font-size: 28rpx; padding: 20rpx 48rpx; border: none; }
.month-label { display: block; font-size: 26rpx; color: #888; margin: 16rpx 0 12rpx; }
.report-item { display: flex; align-items: center; gap: 20rpx; margin-bottom: 16rpx; }
.card { background: #fff; border-radius: 20rpx; padding: 28rpx 32rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06); }
.r-icon { font-size: 36rpx; }
.r-info { flex: 1; }
.r-title { display: block; font-size: 28rpx; font-weight: 500; color: #1a1a2e; }
.r-meta { display: block; font-size: 22rpx; color: #aaa; margin-top: 4rpx; }
.arrow {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 72rpx;
  height: 44rpx;
  padding: 0 16rpx;
  border: 1rpx solid #dedacf;
  border-radius: 999rpx;
  color: #1a2b48;
  background: #f8f7f2;
  font-size: 21rpx;
  font-weight: 900;
  box-sizing: border-box;
}
</style>
