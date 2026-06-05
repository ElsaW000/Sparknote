<!-- Spark_Vault_uniapp/src/pages/archive/index.vue -->
<template>
  <scroll-view class="iv-page archive" scroll-y>
    <text class="iv-title">AI Research Archives</text>
    <text class="iv-subtitle">
      Review all outlines, drafts, essay topic maps and research reports previously compiled inside
      your vault.
    </text>

    <view v-if="reports.length" class="report-list">
      <view
        v-for="report in reports"
        :key="report.id"
        class="iv-card report-card"
        @click="openReport(report.id)"
      >
        <view class="iv-between">
          <text class="report-title">{{ report.title }}</text>
          <text class="delete-report" @click.stop="removeReport(report.id)">×</text>
        </view>
        <text class="report-prompt">Prompt: "{{ report.userPrompt || 'No prompt saved' }}"</text>
        <text class="report-date">{{ formatDate(report.createdAt) }}</text>
      </view>
    </view>

    <view v-else class="empty-archive">
      <text class="empty-copy">
        No previous research workspace outputs saved. Synthesize thoughts inside the workspace tab.
      </text>
    </view>

    <text class="iv-section-title settings-title">Thinking Studio Settings</text>
    <text class="iv-subtitle settings-subtitle">Secure configurations and workspace presets controls.</text>

    <view class="iv-card iv-card-padded status-card">
      <view class="status-row">
        <view class="status-dot"></view>
        <text class="status-title">Local Heuristics Fallback Active</text>
      </view>
      <text class="iv-caption status-copy">
        API Key Status Details:
        Current uni-app build uses local summarizing, tag extraction, and workspace synthesis so the
        phone test can run without cloud secrets.
      </text>
    </view>

    <view class="iv-card iv-card-padded diagnostics-card">
      <text class="diagnostics-title">Database Diagnostics & Seeds</text>
      <view class="diagnostics-grid">
        <view class="metric-pill">
          <text class="metric-value">{{ metrics.totalFragments }}</text>
          <text class="metric-label">Fragments</text>
        </view>
        <view class="metric-pill">
          <text class="metric-value">{{ metrics.reportCount }}</text>
          <text class="metric-label">Reports</text>
        </view>
      </view>
      <view class="action-row">
        <button class="iv-button action-button" @click="loadSeeds">⇩ Re-load Seeds</button>
        <button class="danger-button action-button" @click="confirmClear">! Nuke Vault</button>
      </view>
    </view>
  </scroll-view>
</template>

<script>
import { vaultStore } from '../../store/vaultStore.js'

export default {
  data() {
    return {
      reports: [],
      metrics: vaultStore.state.metrics
    }
  },
  onShow() {
    this.syncState()
  },
  methods: {
    syncState() {
      vaultStore.refresh()
      this.reports = vaultStore.state.reports
      this.metrics = vaultStore.state.metrics
    },
    openReport(id) {
      if (!Number.isInteger(Number(id))) return
      uni.navigateTo({ url: `/pages/archive/report-detail?id=${id}` })
    },
    removeReport(id) {
      if (!Number.isInteger(Number(id))) return
      const result = vaultStore.deleteReport(id)
      if (!result.ok) {
        uni.showToast({ title: result.error || 'Delete failed', icon: 'none' })
        return
      }
      this.syncState()
      uni.showToast({ title: 'Report deleted', icon: 'success' })
    },
    loadSeeds() {
      vaultStore.loadCuratedSeeds()
      this.syncState()
      uni.showToast({ title: 'Seeds loaded', icon: 'success' })
    },
    confirmClear() {
      uni.showModal({
        title: 'Nuke Vault',
        content: 'Clear all local fragments and reports on this device?',
        confirmText: 'Clear',
        confirmColor: '#ba1a1a',
        success: (res) => {
          if (!res.confirm) return
          this.clearAll()
        }
      })
    },
    clearAll() {
      vaultStore.clearAll()
      this.syncState()
      uni.showToast({ title: 'Vault cleared', icon: 'success' })
    },
    formatDate(value) {
      const date = new Date(Number(value) || Date.now())
      if (Number.isNaN(date.getTime())) return ''
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
    }
  }
}
</script>

<style scoped>
.archive {
  padding-bottom: 56rpx;
}

.report-list {
  margin-top: 28rpx;
  display: flex;
  flex-direction: column;
  gap: 20rpx;
}

.report-card {
  padding: 24rpx;
  border-radius: 20rpx;
}

.report-title {
  flex: 1;
  font-size: 26rpx;
  line-height: 1.32;
  font-weight: 800;
  color: #004a77;
}

.delete-report {
  width: 48rpx;
  height: 48rpx;
  border-radius: 999rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ba1a1a;
  font-size: 32rpx;
  background: rgba(186, 26, 26, 0.08);
}

.report-prompt,
.report-date {
  display: block;
  margin-top: 10rpx;
  font-size: 22rpx;
  line-height: 1.42;
  color: #49454f;
}

.report-prompt {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.report-date {
  color: #6750a4;
}

.empty-archive {
  margin-top: 28rpx;
  padding: 48rpx 32rpx;
  border: 1rpx solid rgba(0, 74, 119, 0.3);
  border-radius: 20rpx;
  text-align: center;
}

.empty-copy {
  font-size: 24rpx;
  line-height: 1.55;
  color: #49454f;
}

.settings-title {
  margin-top: 52rpx;
}

.settings-subtitle {
  margin-bottom: 24rpx;
}

.status-card,
.diagnostics-card {
  border-radius: 24rpx;
  margin-top: 20rpx;
}

.status-row {
  display: flex;
  align-items: center;
  gap: 16rpx;
}

.status-dot {
  width: 20rpx;
  height: 20rpx;
  border-radius: 999rpx;
  background: #ff9800;
}

.status-title {
  font-size: 26rpx;
  line-height: 1.3;
  font-weight: 800;
  color: #ff9800;
}

.status-copy {
  margin-top: 16rpx;
}

.diagnostics-title {
  display: block;
  font-size: 26rpx;
  font-weight: 800;
  color: #004a77;
}

.diagnostics-grid {
  margin-top: 18rpx;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14rpx;
}

.metric-pill {
  padding: 20rpx;
  border-radius: 18rpx;
  background: #f3edf7;
}

.metric-value,
.metric-label {
  display: block;
}

.metric-value {
  font-size: 32rpx;
  font-weight: 800;
  color: #6750a4;
}

.metric-label {
  margin-top: 4rpx;
  font-size: 22rpx;
  font-weight: 700;
  color: #49454f;
}

.action-row {
  margin-top: 22rpx;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14rpx;
}

.action-button {
  min-height: 80rpx;
  border-radius: 20rpx;
  font-size: 22rpx;
  font-weight: 800;
  line-height: 80rpx;
}

.danger-button {
  background: #ba1a1a;
  color: #ffffff;
}
</style>
