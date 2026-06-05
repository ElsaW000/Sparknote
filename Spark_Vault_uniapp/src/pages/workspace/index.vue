<!-- Spark_Vault_uniapp/src/pages/workspace/index.vue -->
<template>
  <scroll-view class="iv-page workspace" scroll-y>
    <text class="iv-title">AI Thinking Workspace</text>
    <text class="iv-subtitle">
      Consult the collective intelligence of your vault. Synthesize fragments into essays, topic maps,
      research papers or organized outlines instantly.
    </text>

    <view class="iv-card iv-card-padded inquiry-card">
      <text class="field-label">What would you like to synthesize?</text>
      <textarea
        class="iv-textarea prompt-input"
        v-model="prompt"
        maxlength="-1"
        placeholder="e.g. I want to draft a research paper about systems and self-discipline strategies..."
      />

      <text class="field-label format-label">Output Synthesized Format</text>
      <scroll-view class="format-scroll" scroll-x>
        <view class="format-row">
          <text
            v-for="type in reportTypes"
            :key="type.key"
            :class="['iv-chip', reportType === type.key ? 'active' : '']"
            @click="reportType = type.key"
          >
            {{ type.label }}
          </text>
        </view>
      </scroll-view>

      <button class="iv-button synth-button" @click="generate">
        ✦ Synthesize Studio Draft
      </button>
    </view>

    <view v-if="workspaceResult" class="result-section">
      <view class="iv-between result-heading">
        <text class="iv-section-title inline-title">Synthesized Draft</text>
        <text class="clear-link" @click="clearDraft">Clear Draft</text>
      </view>

      <view class="iv-card iv-card-padded draft-card">
        <text class="draft-content">{{ workspaceResult.content }}</text>
        <button class="iv-outline-button references-button" @click="openReferences">
          View Vault References
        </button>
      </view>

      <text class="iv-section-title references-title">Related Vault Fragments</text>
      <view
        v-for="fragment in workspaceReferences"
        :key="fragment.id"
        class="iv-card iv-card-padded reference-card"
        @click="openFragment(fragment.id)"
      >
        <view class="iv-between">
          <text :class="['iv-badge', badgeClass(fragment.sourceType)]">{{ fragment.sourceType }}</text>
          <text class="reference-arrow">›</text>
        </view>
        <text class="reference-title">{{ fragment.sourceTitle || 'Untitled Source' }}</text>
        <text class="iv-caption reference-copy">{{ fragment.originalText }}</text>
      </view>
    </view>

    <view v-else class="empty-studio">
      <view class="iv-icon-circle empty-icon">⌂</view>
      <text class="empty-text">Your Private Research Studio is ready.</text>
    </view>
  </scroll-view>
</template>

<script>
import { vaultStore } from '../../store/vaultStore.js'

export default {
  data() {
    return {
      prompt: '',
      reportType: 'Outline',
      workspaceResult: vaultStore.state.workspaceResult,
      workspaceReferences: vaultStore.state.workspaceReferences,
      reportTypes: [
        { key: 'Outline', label: 'Writing Outline' },
        { key: 'Research', label: 'Research Report' },
        { key: 'Journal', label: 'Reflection Journal' },
        { key: 'TopicMap', label: 'Topic Map' },
        { key: 'Ideas', label: 'Content Ideas' },
        { key: 'Essay', label: 'Essay Draft' }
      ]
    }
  },
  onShow() {
    this.syncWorkspace()
  },
  methods: {
    syncWorkspace() {
      this.workspaceResult = vaultStore.state.workspaceResult
      this.workspaceReferences = vaultStore.state.workspaceReferences
    },
    generate() {
      const result = vaultStore.generateWorkspaceReport({
        prompt: this.prompt,
        reportType: this.reportType
      })
      if (!result.ok) {
        uni.showToast({ title: result.error || 'Workspace prompt is required', icon: 'none' })
        return
      }
      this.syncWorkspace()
      uni.showToast({ title: 'Draft saved', icon: 'success' })
    },
    clearDraft() {
      vaultStore.state.workspaceResult = null
      vaultStore.state.workspaceReferences = []
      this.syncWorkspace()
    },
    openReferences() {
      const ids = this.workspaceReferences.map((fragment) => fragment.id).join(',')
      uni.navigateTo({ url: `/pages/workspace/references?ids=${ids}` })
    },
    openFragment(id) {
      if (!Number.isInteger(Number(id))) return
      uni.navigateTo({ url: `/pages/library/detail?id=${id}` })
    },
    badgeClass(sourceType) {
      if (sourceType === 'Browser') return 'web'
      if (sourceType === 'Book') return ''
      return 'other'
    }
  }
}
</script>

<style scoped>
.workspace {
  padding-bottom: 56rpx;
}

.inquiry-card {
  margin-top: 28rpx;
}

.field-label {
  display: block;
  font-size: 22rpx;
  line-height: 1.25;
  font-weight: 800;
  color: #004a77;
}

.prompt-input {
  margin-top: 16rpx;
  min-height: 190rpx;
}

.format-label {
  margin-top: 28rpx;
}

.format-scroll {
  margin-top: 16rpx;
  width: 100%;
  white-space: nowrap;
}

.format-row {
  display: inline-flex;
  gap: 12rpx;
  padding-bottom: 8rpx;
}

.synth-button {
  margin-top: 26rpx;
}

.result-section {
  margin-top: 26rpx;
}

.result-heading {
  margin-bottom: 12rpx;
}

.inline-title {
  margin: 0;
}

.clear-link {
  font-size: 24rpx;
  font-weight: 700;
  color: #004a77;
}

.draft-card {
  border-radius: 24rpx;
}

.draft-content {
  display: block;
  white-space: pre-wrap;
  font-size: 25rpx;
  line-height: 1.62;
  color: #1c1b1f;
}

.references-button {
  margin-top: 24rpx;
}

.references-title {
  margin-top: 28rpx;
}

.reference-card {
  margin-top: 14rpx;
  border-radius: 20rpx;
}

.reference-arrow {
  font-size: 34rpx;
  color: #6750a4;
}

.reference-title {
  display: block;
  margin-top: 16rpx;
  font-size: 26rpx;
  line-height: 1.3;
  font-weight: 800;
  color: #004a77;
}

.reference-copy {
  margin-top: 8rpx;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
}

.empty-studio {
  min-height: 320rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16rpx;
}

.empty-icon {
  background: rgba(234, 221, 255, 0.7);
}

.empty-text {
  font-size: 25rpx;
  color: #49454f;
}
</style>
