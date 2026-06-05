<!-- Spark_Vault_uniapp/pages/workspace/result.vue -->
<template>
  <view class="page">
    <text class="title">Workspace Result</text>
    <text class="subtitle">{{ report ? report.title : 'No report selected' }}</text>

    <view class="panel" v-if="report">
      <text class="content">{{ report.generatedContent }}</text>
      <button @click="openReferences">View References</button>
    </view>
    <view class="panel" v-else>
      <text class="content">Generate a workspace report first.</text>
      <button @click="backToWorkspace">Back to Workspace</button>
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
    this.reportId = Number(query?.reportId)
    this.report = vaultStore.getReportById(this.reportId)
  },
  methods: {
    openReferences() {
      const ids = this.report?.relatedFragmentIds?.join(',') || ''
      uni.navigateTo({ url: `/pages/workspace/references?ids=${ids}` })
    },
    backToWorkspace() {
      uni.switchTab({ url: '/pages/workspace/index' })
    }
  }
}
</script>

<style scoped>
.page { padding: 24rpx; }
.title { font-size: 38rpx; font-weight: 700; display: block; color: #0f172a; }
.subtitle { font-size: 24rpx; color: #64748b; display: block; margin-top: 8rpx; }
.panel { margin-top: 18rpx; background: #f8fafc; border-radius: 12rpx; padding: 16rpx; }
.content { font-size: 26rpx; color: #1f2937; line-height: 1.6; display: block; margin-bottom: 14rpx; white-space: pre-wrap; }
</style>
