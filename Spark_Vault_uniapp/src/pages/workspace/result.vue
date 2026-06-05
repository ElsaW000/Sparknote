<!-- Spark_Vault_uniapp/pages/workspace/result.vue -->
<template>
  <scroll-view class="iv-page result-page" scroll-y>
    <text class="iv-title">Workspace Result</text>
    <text class="iv-subtitle">{{ report ? report.title : 'No report selected' }}</text>

    <view class="iv-card iv-card-padded panel" v-if="report">
      <text class="content">{{ report.generatedContent }}</text>
      <button class="iv-outline-button" @click="openReferences">View References</button>
    </view>
    <view class="iv-card iv-card-padded panel" v-else>
      <text class="content">Generate a workspace report first.</text>
      <button class="iv-button" @click="backToWorkspace">Back to Workspace</button>
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
    this.reportId = Number(query?.reportId)
    this.report = vaultStore.getReportById(this.reportId)
  },
  methods: {
    openReferences() {
      const ids = this.report?.relatedFragmentIds?.join(',') || ''
      uni.navigateTo({ url: `/pages/workspace/references?ids=${ids}` })
    },
    backToWorkspace() {
      uni.navigateBack()
    }
  }
}
</script>

<style scoped>
.result-page { padding-bottom: 56rpx; }
.panel { margin-top: 24rpx; border-radius: 24rpx; }
.content { font-size: 26rpx; color: #1c1b1f; line-height: 1.62; display: block; margin-bottom: 22rpx; white-space: pre-wrap; }
</style>
