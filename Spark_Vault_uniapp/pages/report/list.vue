<!-- pages/report/list.vue — 报告历史列表 -->
<template>
  <view class="page">
    <!-- Header -->
    <view class="header">
      <text class="back" @click="back">←</text>
      <text class="title">报告历史</text>
      <view class="new-btn" @click="newReport">
        <text class="new-btn-text">＋ 生成</text>
      </view>
    </view>

    <!-- Content -->
    <scroll-view class="list" scroll-y>
      <!-- Empty state -->
      <view v-if="reports.length === 0" class="empty">
        <text class="empty-icon">📋</text>
        <text class="empty-title">还没有报告</text>
        <text class="empty-sub">通过 AI 对话生成你的第一份成长报告</text>
        <view class="empty-cta" @click="newReport">
          <text class="empty-cta-text">🤖 生成报告</text>
        </view>
      </view>

      <!-- Report groups by month -->
      <view v-for="(group, idx) in groupedReports" :key="idx" class="month-group">
        <text class="month-label">{{ group.month }}</text>
        <view class="group-card">
          <view
            class="report-row"
            v-for="(r, ri) in group.items"
            :key="r.id"
            :style="ri < group.items.length - 1 ? 'border-bottom: 2rpx solid #f5f2ee;' : ''"
            @click="openReport(r)"
          >
            <text class="report-icon">{{ typeIcon(r.type) }}</text>
            <view class="report-info">
              <text class="report-title">{{ r.title || '成长报告' }}</text>
              <text class="report-date">{{ formatDate(r.created_at) }}</text>
            </view>
            <view class="report-type-chip">
              <text class="chip-text">{{ typeName(r.type) }}</text>
            </view>
          </view>
        </view>
      </view>

      <view style="height: 60rpx;" />
    </scroll-view>
  </view>
</template>

<script>
import { getVaultStore } from '@/store/vaultStore.js'

const store = getVaultStore()

const TYPE_MAP = {
  weekly: { name: '周报', icon: '📅' },
  reflection: { name: '反思', icon: '🔍' },
  report: { name: '报告', icon: '📊' }
}

export default {
  data() {
    return { reports: [] }
  },
  computed: {
    groupedReports() {
      const groups = {}
      ;[...this.reports].sort((a, b) => b.created_at - a.created_at).forEach((r) => {
        const d = new Date(r.created_at)
        const key = `${d.getFullYear()}年${d.getMonth() + 1}月`
        if (!groups[key]) groups[key] = []
        groups[key].push(r)
      })
      return Object.entries(groups).map(([month, items]) => ({ month, items }))
    }
  },
  onShow() {
    store.refresh()
    this.reports = store.state.reports || []
  },
  methods: {
    back() {
      uni.navigateBack()
    },
    openReport(r) {
      uni.navigateTo({ url: `/pages/report/detail?id=${r.id}` })
    },
    newReport() {
      uni.navigateTo({ url: '/pages/chat/session?mode=report' })
    },
    typeIcon(type) {
      return (TYPE_MAP[type] || TYPE_MAP.report).icon
    },
    typeName(type) {
      return (TYPE_MAP[type] || TYPE_MAP.report).name
    },
    formatDate(ts) {
      if (!ts) return ''
      const d = new Date(ts)
      return `${d.getMonth() + 1}月${d.getDate()}日`
    }
  }
}
</script>

<style scoped>
.page { display: flex; flex-direction: column; height: 100vh; background: #fbf9f6; }

.header { display: flex; align-items: center; gap: 16rpx; padding: 20rpx 28rpx; background: #ffffff; border-bottom: 2rpx solid #f0ece6; }
.back { font-size: 36rpx; color: #1c1b1f; padding: 4rpx 12rpx 4rpx 0; }
.title { flex: 1; font-size: 32rpx; font-weight: 700; color: #1c1b1f; }
.new-btn { background: #004a77; border-radius: 20rpx; padding: 12rpx 24rpx; }
.new-btn-text { font-size: 26rpx; color: #ffffff; font-weight: 600; }

.list { flex: 1; padding: 24rpx; }

/* Empty */
.empty { text-align: center; padding: 100rpx 40rpx; }
.empty-icon { font-size: 80rpx; display: block; margin-bottom: 20rpx; }
.empty-title { display: block; font-size: 32rpx; font-weight: 700; color: #1c1b1f; margin-bottom: 12rpx; }
.empty-sub { display: block; font-size: 26rpx; color: #49454f; margin-bottom: 36rpx; }
.empty-cta { background: #004a77; border-radius: 20rpx; padding: 18rpx 40rpx; display: inline-block; }
.empty-cta-text { font-size: 28rpx; color: #ffffff; font-weight: 600; }

/* Groups */
.month-group { margin-bottom: 28rpx; }
.month-label { display: block; font-size: 24rpx; font-weight: 700; color: #49454f; margin-bottom: 12rpx; padding-left: 4rpx; }
.group-card { background: #ffffff; border-radius: 24rpx; overflow: hidden; }

.report-row { display: flex; align-items: center; gap: 16rpx; padding: 22rpx 24rpx; }
.report-icon { font-size: 36rpx; width: 44rpx; }
.report-info { flex: 1; }
.report-title { display: block; font-size: 28rpx; font-weight: 600; color: #1c1b1f; }
.report-date { display: block; font-size: 22rpx; color: #49454f; margin-top: 4rpx; }
.report-type-chip { background: #f5f2ee; border-radius: 12rpx; padding: 6rpx 14rpx; }
.chip-text { font-size: 20rpx; color: #49454f; }
</style>
