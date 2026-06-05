<!-- Spark_Vault_uniapp/pages/archive/report-detail.vue -->
<template>
  <view class="page">
    <text class="title">{{ report ? report.title : 'Report Detail' }}</text>
    <text class="subtitle">{{ report ? report.userPrompt : 'Report not found' }}</text>

    <view class="panel" v-if="report">
      <text class="content">{{ report.generatedContent }}</text>
      <button @click="openReferences">Open References</button>
      <button @click="remove">Delete Report</button>
    </view>
    <view class="panel" v-else>
      <text class="content">The selected report is unavailable.</text>
    </view>
  </view>
</template>

<script>
import { vaultStore } from '../../store/vaultStore.js'

export default {
  data() {
    return {
      reportId: null,
      report: null
    }
  },
  onLoad(query) {
    this.reportId = Number(query?.id)
    this.report = vaultStore.getReportById(this.reportId)
  },
  methods: {
    openReferences() {
      const ids = this.report?.relatedFragmentIds?.join(',') || ''
      uni.navigateTo({ url: `/pages/workspace/references?ids=${ids}` })
    },
    remove() {
      const result = vaultStore.deleteReport(this.reportId)
      if (!result.ok) {
        uni.showToast({ title: result.error, icon: 'none' })
        return
      }
      uni.showToast({ title: 'Report deleted', icon: 'success' })
      uni.navigateBack()
    }
  }
}
</script>

<style scoped>
.page { padding: 24rpx; }
.title { font-size: 38rpx; font-weight: 700; display: block; color: #0f172a; }
.subtitle { font-size: 24rpx; color: #64748b; display: block; margin-top: 8rpx; }
.panel { margin-top: 18rpx; background: #f8fafc; border-radius: 12rpx; padding: 16rpx; display: flex; flex-direction: column; gap: 12rpx; }
.content { font-size: 26rpx; color: #1f2937; line-height: 1.6; display: block; white-space: pre-wrap; }
</style>
