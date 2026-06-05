<template>
  <view class="ai-page">
    <view class="ai-header">
      <text class="ai-title">Insight</text>
      <text class="ai-subtitle">输入文字，自动生成摘要、标签与清理文本，保存到 Library</text>
    </view>

    <!-- Workspace entry -->
    <view class="workspace-entry" @click="goWorkspace">
      <view class="workspace-entry-left">
        <text class="workspace-icon">⚙</text>
        <view>
          <text class="workspace-entry-title">AI Workspace</text>
          <text class="workspace-entry-sub">基于 Library 片段生成报告 →</text>
        </view>
      </view>
    </view>

    <!-- Input -->
    <view class="iv-card input-card">
      <textarea
        class="ai-textarea"
        v-model="inputText"
        placeholder="粘贴或输入你想整理的文字..."
        :maxlength="5000"
      ></textarea>
      <view class="input-footer">
        <text class="char-count">{{ inputText.length }} / 5000</text>
        <view class="btn-row">
          <button class="iv-button secondary-btn" @click="clearInput">清空</button>
          <button class="iv-button primary-btn" @click="runOrganize" :disabled="!inputText.trim() || loading">
            {{ loading ? '整理中...' : '整理 ✦' }}
          </button>
        </view>
      </view>
    </view>

    <!-- Results -->
    <view v-if="result" class="results-section">
      <!-- Summary -->
      <view class="iv-card result-card">
        <text class="result-label">摘要</text>
        <text class="result-value">{{ result.summary }}</text>
      </view>

      <!-- Tags -->
      <view class="iv-card result-card">
        <text class="result-label">标签</text>
        <view class="tag-row">
          <text class="ai-tag" v-for="tag in result.tags" :key="tag">#{{ tag }}</text>
        </view>
      </view>

      <!-- Cleaned text preview -->
      <view class="iv-card result-card">
        <text class="result-label">清理后文本</text>
        <text class="result-value small">{{ result.cleanedText }}</text>
      </view>

      <!-- Save to Library -->
      <view class="iv-card save-card">
        <text class="save-title">保存到 Library</text>

        <view class="field-row">
          <text class="field-label">来源</text>
          <input class="field-input" v-model="saveSource" placeholder="例如：Book, Browser..." />
        </view>
        <view class="field-row">
          <text class="field-label">来源标题</text>
          <input class="field-input" v-model="saveSourceTitle" placeholder="书名 / 文章标题..." />
        </view>
        <view class="field-row">
          <text class="field-label">作者</text>
          <input class="field-input" v-model="saveAuthor" placeholder="作者名（可选）" />
        </view>
        <view class="field-row">
          <text class="field-label">页码</text>
          <input class="field-input" v-model="savePageNumber" placeholder="页码（可选）" type="number" />
        </view>
        <view class="field-row">
          <text class="field-label">反思</text>
          <textarea class="field-textarea" v-model="saveComment" placeholder="你的感想或批注（可选）..."></textarea>
        </view>

        <view class="save-toggle">
          <checkbox :checked="saveAiSummaryAsComment" @click="saveAiSummaryAsComment = !saveAiSummaryAsComment" />
          <text class="toggle-label">将 AI 摘要追加到反思</text>
        </view>

        <button class="iv-button save-btn" @click="saveToLibrary" :disabled="saving">
          {{ saving ? '保存中...' : '保存到 Library' }}
        </button>
      </view>
    </view>
  </view>
</template>

<script>
import { organize, AI_TAB_SOURCE } from '../../services/aiService.js'
import { createVaultRepository } from '../../services/vaultRepository.js'
import { createId, parseTags } from '../../services/vaultLogic.js'

const repo = createVaultRepository()

export default {
  data() {
    return {
      inputText: '',
      loading: false,
      result: null,

      // Save form
      saveSource: AI_TAB_SOURCE,
      saveSourceTitle: '',
      saveAuthor: '',
      savePageNumber: '',
      saveComment: '',
      saveAiSummaryAsComment: true,
      saving: false
    }
  },

  onLoad() {},

  methods: {
    goWorkspace() {
      uni.navigateTo({ url: '/pages/workspace/index' })
    },

    runOrganize() {
      if (!this.inputText.trim()) return
      this.loading = true
      try {
        this.result = organize(this.inputText)
      } finally {
        this.loading = false
      }
    },

    clearInput() {
      this.inputText = ''
      this.result = null
    },

    saveToLibrary() {
      if (!this.result) return
      this.saving = true

      const comment = this.saveAiSummaryAsComment && this.result.summary
        ? `${this.saveComment}\n\n[AI Summary] ${this.result.summary}`.trim()
        : this.saveComment

      const fragment = {
        id: createId(),
        originalText: this.result.cleanedText || this.inputText,
        sourceType: this.saveSource || AI_TAB_SOURCE,
        sourceTitle: this.saveSourceTitle,
        author: this.saveAuthor,
        pageNumber: this.savePageNumber ? Number(this.savePageNumber) : null,
        tags: this.result.tags,
        userComment: comment,
        createdAt: Date.now(),
        updatedAt: Date.now(),
        favoriteStatus: false
      }

      try {
        repo.saveFragment(fragment)
        uni.showToast({ title: '已保存到 Library', icon: 'success' })
        // Reset form
        this.inputText = ''
        this.result = null
        this.saveComment = ''
        this.saveSourceTitle = ''
        this.saveAuthor = ''
        this.savePageNumber = ''
      } catch (e) {
        uni.showToast({ title: '保存失败: ' + e.message, icon: 'none' })
      } finally {
        this.saving = false
      }
    }
  }
}
</script>

<style scoped>
.ai-page {
  min-height: 100vh;
  background-color: #fbf9f6;
  padding: 20rpx;
  padding-bottom: 80rpx;
}

.ai-header {
  padding: 20rpx 0 28rpx;
}

.ai-title {
  font-size: 40rpx;
  font-weight: bold;
  color: #1a1a1a;
}

.ai-subtitle {
  display: block;
  margin-top: 8rpx;
  font-size: 24rpx;
  color: rgba(73, 69, 79, 0.72);
}

.input-card {
  margin-bottom: 28rpx;
  padding: 24rpx;
}

.workspace-entry {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: #eef4fb;
  border: 1rpx solid #c2d9ef;
  border-radius: 16rpx;
  padding: 24rpx 28rpx;
  margin-bottom: 28rpx;
}

.workspace-entry-left {
  display: flex;
  align-items: center;
  gap: 20rpx;
}

.workspace-icon {
  font-size: 40rpx;
  color: #004a77;
}

.workspace-entry-title {
  display: block;
  font-size: 28rpx;
  font-weight: 600;
  color: #004a77;
}

.workspace-entry-sub {
  display: block;
  font-size: 22rpx;
  color: #49454f;
  margin-top: 4rpx;
}

.ai-textarea {
  width: 100%;
  min-height: 220rpx;
  font-size: 27rpx;
  line-height: 1.65;
  color: #1c1b1f;
  border: none;
  resize: none;
  background: transparent;
}

.input-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 16rpx;
  padding-top: 14rpx;
  border-top: 1rpx solid rgba(73, 69, 79, 0.12);
}

.char-count {
  font-size: 22rpx;
  color: rgba(73, 69, 79, 0.5);
}

.btn-row {
  display: flex;
  gap: 16rpx;
}

.secondary-btn {
  background: transparent;
  border: 1rpx solid #cac4d0;
  color: #49454f;
  font-size: 25rpx;
  line-height: 64rpx;
  padding: 0 24rpx;
}

.primary-btn {
  background: #004a77;
  color: #fff;
  font-size: 25rpx;
  line-height: 64rpx;
  padding: 0 28rpx;
}

.results-section {
  display: flex;
  flex-direction: column;
  gap: 20rpx;
}

.result-card {
  padding: 24rpx;
}

.result-label {
  display: block;
  font-size: 22rpx;
  font-weight: 700;
  color: #004a77;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 12rpx;
}

.result-value {
  font-size: 27rpx;
  line-height: 1.6;
  color: #1c1b1f;
}

.result-value.small {
  font-size: 24rpx;
  color: rgba(73, 69, 79, 0.82);
}

.tag-row {
  display: flex;
  flex-wrap: wrap;
  gap: 12rpx;
}

.ai-tag {
  font-size: 22rpx;
  font-family: monospace;
  color: #004a77;
  background: rgba(0, 74, 119, 0.08);
  padding: 6rpx 14rpx;
  border-radius: 8rpx;
}

.save-card {
  padding: 24rpx;
  background: #f0f7ff;
  border: 1rpx solid #cce0f0;
}

.save-title {
  display: block;
  font-size: 28rpx;
  font-weight: 700;
  color: #004a77;
  margin-bottom: 20rpx;
}

.field-row {
  margin-bottom: 16rpx;
}

.field-label {
  display: block;
  font-size: 22rpx;
  color: #49454f;
  margin-bottom: 6rpx;
  font-weight: 600;
}

.field-input {
  width: 100%;
  height: 72rpx;
  padding: 0 16rpx;
  border: 1rpx solid #cac4d0;
  border-radius: 12rpx;
  background: #ffffff;
  font-size: 26rpx;
  color: #1c1b1f;
  box-sizing: border-box;
}

.field-textarea {
  width: 100%;
  min-height: 120rpx;
  padding: 12rpx 16rpx;
  border: 1rpx solid #cac4d0;
  border-radius: 12rpx;
  background: #ffffff;
  font-size: 26rpx;
  color: #1c1b1f;
  resize: none;
}

.save-toggle {
  display: flex;
  align-items: center;
  gap: 10rpx;
  margin: 16rpx 0 20rpx;
}

.toggle-label {
  font-size: 24rpx;
  color: #49454f;
}

.save-btn {
  width: 100%;
  background: #004a77;
  color: #fff;
  font-size: 28rpx;
  line-height: 88rpx;
  border-radius: 16rpx;
}
</style>
