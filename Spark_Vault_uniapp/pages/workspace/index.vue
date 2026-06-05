<!-- Spark_Vault_uniapp/pages/workspace/index.vue -->
<template>
  <view class="page">
    <text class="title">AI Workspace</text>
    <text class="subtitle">Generate a local synthesis report from your vault fragments.</text>

    <view class="panel">
      <textarea class="textarea" v-model="prompt" placeholder="What would you like to synthesize?" />
      <view class="chips">
        <text
          v-for="type in reportTypes"
          :key="type"
          :class="['chip', reportType === type ? 'active' : '']"
          @click="reportType = type"
        >{{ type }}</text>
      </view>
      <button type="primary" @click="generate">Synthesize Studio Draft</button>
    </view>

    <button @click="openReferences">View Vault References</button>
  </view>
</template>

<script>
import { vaultStore } from '../../store/vaultStore.js'

export default {
  data() {
    return {
      prompt: '',
      reportType: 'Outline',
      reportTypes: ['Outline', 'Research', 'Essay', 'Ideas', 'Journal']
    }
  },
  methods: {
    generate() {
      const result = vaultStore.generateWorkspaceReport({
        prompt: this.prompt,
        reportType: this.reportType
      })
      if (!result.ok) {
        uni.showToast({ title: result.error, icon: 'none' })
        return
      }
      uni.navigateTo({ url: `/pages/workspace/result?reportId=${result.report.id}` })
    },
    openReferences() {
      const ids = vaultStore.state.workspaceReferences.map((fragment) => fragment.id).join(',')
      uni.navigateTo({ url: `/pages/workspace/references?ids=${ids}` })
    }
  }
}
</script>

<style scoped>
.page { padding: 24rpx; }
.title { font-size: 40rpx; font-weight: 700; display: block; color: #0f172a; }
.subtitle { font-size: 24rpx; color: #64748b; display: block; margin-top: 8rpx; }
.panel { margin-top: 20rpx; background: #f8fafc; border-radius: 14rpx; padding: 14rpx; }
.textarea { width: 100%; min-height: 220rpx; background: #fff; border-radius: 10rpx; padding: 12rpx; box-sizing: border-box; font-size: 26rpx; }
.chips { margin: 12rpx 0; display: flex; gap: 8rpx; flex-wrap: wrap; }
.chip { padding: 8rpx 14rpx; background: #dbeafe; border-radius: 999rpx; font-size: 22rpx; color: #1d4ed8; }
.chip.active { background: #1d4ed8; color: #fff; }
</style>
