<!-- Spark_Vault_uniapp/pages/archive/report-detail.vue -->
<template>
  <scroll-view class="iv-page report-detail" scroll-y>
    <text class="iv-title">{{ report ? report.title : 'Report Detail' }}</text>
    <text class="iv-subtitle">{{ report ? report.userPrompt : 'Report not found' }}</text>

    <view class="iv-card iv-card-padded panel" v-if="report">
      <text class="content">{{ report.generatedContent }}</text>
      <button class="iv-outline-button" @click="openReferences">Open References</button>
      <button class="danger-outline" @click="remove">Delete Report</button>
    </view>
    <view class="iv-card iv-card-padded panel" v-else>
      <text class="content">The selected report is unavailable.</text>
    </view>
  </scroll-view>
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
.report-detail { padding-bottom: 56rpx; }
.panel { margin-top: 24rpx; border-radius: 24rpx; display: flex; flex-direction: column; gap: 14rpx; }
.content { font-size: 26rpx; color: #1c1b1f; line-height: 1.62; display: block; white-space: pre-wrap; }
.danger-outline { min-height: 88rpx; border-radius: 24rpx; color: #ba1a1a; background: #fff; border: 1rpx solid #ba1a1a; font-size: 25rpx; font-weight: 800; line-height: 88rpx; }
</style>
