<!-- Spark_Vault_uniapp/src/pages/capture/index.vue -->
<template>
  <scroll-view scroll-y class="iv-page capture">
    <text class="iv-title">Capture Inspiration</text>
    <text class="iv-subtitle">Harvest fragments of thoughts, physical book text or browser clippings safely into your Vault space.</text>

    <view class="ocr-card">
      <view class="iv-row">
        <text class="ocr-icon">▣</text>
        <text class="ocr-title">OCR Prototype Presets</text>
      </view>
      <text class="iv-caption ocr-copy">If no camera library is enabled, trigger OCR by running simulated text page presets below.</text>
      <view class="ocr-actions">
        <button class="ocr-button" @click="applyBookPreset">Book Page OCR</button>
        <button class="ocr-button" @click="applyBrowserPreset">Screenshot OCR</button>
      </view>
    </view>

    <view class="import-card">
      <view class="iv-row import-head">
        <text class="import-icon">↧</text>
        <text class="import-title">批量文本 / Link 导入</text>
      </view>
      <textarea
        class="iv-textarea import-input"
        v-model="importText"
        placeholder="粘贴一批文本、网页链接、Markdown、导出的书签内容..."
        :maxlength="12000"
        @input="analyzeImport"
      />
      <view class="import-stats">
        <text class="import-stat">{{ importAnalysis.lineCount }} 行</text>
        <text class="import-stat">{{ importAnalysis.linkCount }} 个链接</text>
      </view>
      <view v-if="importAnalysis.links.length" class="link-list">
        <text
          v-for="link in importAnalysis.links.slice(0, 5)"
          :key="link"
          class="link-chip"
        >{{ link }}</text>
        <text v-if="importAnalysis.links.length > 5" class="link-more">+{{ importAnalysis.links.length - 5 }}</text>
      </view>
      <view class="import-actions">
        <button class="ocr-button" :disabled="!importAnalysis.hasContent" @click="useImportText">填入正文</button>
        <button class="ocr-button primary-import" :disabled="!importAnalysis.linkCount" @click="saveDetectedLinks">保存链接</button>
      </view>
    </view>

    <view class="voice-card">
      <view class="iv-row">
        <text class="voice-icon">🎙</text>
        <text class="voice-title">口述记录</text>
      </view>
      <text class="iv-caption voice-copy">按住录音，口述你的想法或灵感。</text>
      <view class="voice-actions">
        <button class="voice-button" @click="startVoiceRecord">🎤 按住说话</button>
      </view>
    </view>

    <text class="field-label">Fragment Quote/Text:</text>
    <textarea
      class="iv-textarea quote-input"
      v-model="form.originalText"
      placeholder="Paste quote text from browsers, e-books, screenshots, or write personal thoughts directly..."
    />

    <view class="assist-card">
      <view class="iv-between">
        <text class="assist-title">AI Auto-Assist:</text>
        <button class="assist-link" :disabled="!form.originalText" @click="generateHelpers">Generate Tags & Summary</button>
      </view>
      <text v-if="aiSummary" class="assist-summary">{{ aiSummary }}</text>
    </view>

    <text class="iv-section-title">Metadata Settings</text>
    <text class="field-label small">Source Type Type</text>
    <view class="source-grid">
      <text
        v-for="source in sourceTypes"
        :key="source"
        :class="['source-chip', form.sourceType === source ? 'active' : '']"
        @click="form.sourceType = source"
      >{{ source }}</text>
    </view>

    <input class="iv-input spacing" v-model="form.sourceTitle" placeholder="Source Title (e.g. Book title, Website name)" />
    <view class="split-row">
      <input class="iv-input" v-model="form.author" placeholder="Author" />
      <input class="iv-input page-field" v-model="form.pageNumber" placeholder="Page #" />
    </view>
    <input class="iv-input spacing" v-model="form.sourceUrl" placeholder="Source URL / Web Link" />
    <textarea class="iv-textarea comment-input" v-model="form.userComment" placeholder="Personal Comment / Private Thought Reflection" />
    <input class="iv-input spacing" v-model="form.tagsText" placeholder="Semantic Tags (comma-separated)" />

    <button class="iv-button save-button" :disabled="!form.originalText" @click="save">Save into Vault Study</button>
  </scroll-view>
</template>

<script>
import { SOURCE_TYPES, fallbackSummary, fallbackTags } from '../../services/vaultLogic.js'
import { getVaultStore } from '../../store/vaultStore.js'
import { analyzeImportText } from '../../services/captureImport.js'

export default {
  data() {
    return {
      sourceTypes: SOURCE_TYPES.filter((item) => item !== 'All'),
      aiSummary: '',
      importText: '',
      importAnalysis: analyzeImportText(''),
      form: {
        originalText: '',
        sourceType: 'Book',
        sourceTitle: '',
        sourceUrl: '',
        author: '',
        pageNumber: '',
        tagsText: '',
        userComment: ''
      }
    }
  },
  methods: {
    applyBookPreset() {
      this.form.originalText = 'Atomic Habits [Self-Discipline & Focus]\nGoals vs Systems paradigm.\nChapter 2. Page 28.'
      this.form.sourceType = 'Book'
      this.form.sourceTitle = 'Atomic Habits'
      this.form.author = 'James Clear'
      this.form.pageNumber = '28'
      this.generateHelpers()
    },
    applyBrowserPreset() {
      this.form.originalText = 'Browser article quote:\nArtificial intelligence highlights slowest humane thinking paradigms.\nAuthored by Edward Sinclair.'
      this.form.sourceType = 'Browser'
      this.form.sourceTitle = 'In Praise of Slow Thinking'
      this.form.author = 'E. Sinclair'
      this.form.sourceUrl = 'https://example.com/slow-thinking'
      this.generateHelpers()
    },
    analyzeImport() {
      this.importAnalysis = analyzeImportText(this.importText)
    },
    useImportText() {
      this.analyzeImport()
      if (!this.importAnalysis.hasContent) {
        uni.showToast({ title: '请先粘贴内容', icon: 'none' })
        return
      }
      this.form.originalText = this.importAnalysis.content
      this.form.sourceType = this.importAnalysis.linkCount ? 'Browser' : 'Manual'
      this.form.sourceUrl = this.importAnalysis.links[0] || ''
      this.generateHelpers()
    },
    saveDetectedLinks() {
      this.analyzeImport()
      if (!this.importAnalysis.linkCount) {
        uni.showToast({ title: '没有识别到链接', icon: 'none' })
        return
      }
      const store = getVaultStore()
      let saved = 0
      for (const link of this.importAnalysis.links) {
        const result = store.saveFragment({
          originalText: link,
          content: link,
          content_type: 'reference_content',
          form_kind: '网页',
          subtype: '网页',
          sourceType: 'Browser',
          sourceTitle: link,
          sourceUrl: link,
          tags: ['link-import']
        })
        if (result.ok) saved += 1
      }
      uni.showToast({ title: `已保存 ${saved} 个链接`, icon: 'success' })
      this.importText = ''
      this.importAnalysis = analyzeImportText('')
      setTimeout(() => {
        uni.switchTab({ url: '/pages/home/index' })
      }, 500)
    },
    startVoiceRecord() {
      if (typeof uni === 'undefined' || typeof uni.getRecorderManager !== 'function') {
        uni.showModal({
          title: '不支持录音',
          content: '当前环境不支持录音功能，请手动输入文字。',
          showCancel: false
        })
        return
      }
      const recorderManager = uni.getRecorderManager()
      recorderManager.onStart(() => {
        uni.showToast({ title: '录音中...', icon: 'none', duration: 10000 })
      })
      recorderManager.onStop((res) => {
        uni.hideToast()
        // 将录音文件路径填充到原始文本字段，便于后续 AI 整理
        this.form.originalText = '🎤 [语音录制] ' + (res.tempFilePath || '')
        uni.showModal({
          title: '录音已填充',
          content: '录音文件路径已填充到上方文本框，可直接点击"Generate Tags & Summary"整理。',
          showCancel: false,
          confirmText: '好的'
        })
      })
      recorderManager.onError((err) => {
        uni.hideToast()
        uni.showModal({
          title: '录音失败',
          content: '无法访问麦克风，请检查权限设置。',
          showCancel: false
        })
      })
      try {
        recorderManager.start({ format: 'mp3', duration: 60000 })
      } catch (e) {
        uni.showModal({
          title: '不支持录音',
          content: '当前环境不支持录音功能，请手动输入文字。',
          showCancel: false
        })
      }
    },
    generateHelpers() {
      if (!this.form.originalText?.trim()) {
        uni.showToast({ title: 'Fragment text is required', icon: 'none' })
        return
      }
      const tags = fallbackTags(this.form.originalText)
      this.form.tagsText = tags.join(', ')
      this.aiSummary = fallbackSummary(this.form.originalText)
    },
    save() {
      const store = getVaultStore()
      const result = store.saveFragment({
        ...this.form,
        aiSummary: this.aiSummary
      })
      if (!result.ok) {
        uni.showToast({ title: result.error, icon: 'none' })
        return
      }
      uni.showToast({ title: 'Fragment saved', icon: 'success' })
      this.resetForm()
      uni.switchTab({ url: '/pages/home/index' })
    },
    resetForm() {
      const sourceType = this.form.sourceType || 'Book'
      this.form = {
        originalText: '',
        sourceType,
        sourceTitle: '',
        sourceUrl: '',
        author: '',
        pageNumber: '',
        tagsText: '',
        userComment: ''
      }
      this.aiSummary = ''
    }
  }
}
</script>

<style scoped>
.capture {
  height: 100vh;
}

.ocr-card {
  margin-top: 28rpx;
  margin-bottom: 30rpx;
  padding: 24rpx;
  border-radius: 24rpx;
  background: rgba(215, 227, 255, 0.62);
}

.import-card {
  margin-top: 24rpx;
  margin-bottom: 30rpx;
  padding: 24rpx;
  border-radius: 20rpx;
  border: 1rpx solid rgba(0, 74, 119, 0.16);
  background: #ffffff;
  box-sizing: border-box;
}

.import-head {
  margin-bottom: 14rpx;
}

.import-icon {
  color: #004a77;
  font-size: 30rpx;
}

.import-title {
  color: #004a77;
  font-size: 24rpx;
  font-weight: 800;
}

.import-input {
  min-height: 170rpx;
}

.import-stats {
  display: flex;
  gap: 12rpx;
  margin-top: 14rpx;
}

.import-stat,
.link-more {
  padding: 5rpx 12rpx;
  border-radius: 999rpx;
  background: rgba(0, 74, 119, 0.08);
  color: #004a77;
  font-size: 20rpx;
  font-weight: 800;
}

.link-list {
  display: flex;
  flex-wrap: wrap;
  gap: 10rpx;
  margin-top: 12rpx;
}

.link-chip {
  max-width: 100%;
  padding: 6rpx 12rpx;
  border-radius: 10rpx;
  background: #f8f7f2;
  color: #1a2b48;
  font-size: 19rpx;
  line-height: 1.35;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.import-actions {
  display: flex;
  gap: 12rpx;
  margin-top: 16rpx;
}

.primary-import {
  background: #004a77;
  color: #ffffff;
}

.voice-card {
  margin-top: 28rpx;
  margin-bottom: 30rpx;
  padding: 24rpx;
  border-radius: 24rpx;
  background: rgba(255, 237, 215, 0.62);
}

.voice-icon,
.ocr-icon {
  color: #004a77;
  font-size: 34rpx;
}

.voice-title,
.ocr-title,
.assist-title {
  font-size: 24rpx;
  font-weight: 800;
  color: #004a77;
}

.voice-copy,
.ocr-copy {
  margin-top: 10rpx;
}

.voice-actions {
  margin-top: 18rpx;
}

.voice-button {
  min-height: 72rpx;
  margin: 0;
  background: rgba(255, 237, 215, 0.82);
  color: #004a77;
  font-size: 25rpx;
  font-weight: 750;
  border: 2rpx solid rgba(0, 74, 119, 0.35);
  border-radius: 18rpx;
  padding: 0 32rpx;
  line-height: 64rpx;
}

.ocr-button {
  min-height: 62rpx;
  margin: 0 10rpx 0 0;
  background: rgba(215, 227, 255, 0.82);
  color: #004a77;
  font-size: 22rpx;
  font-weight: 700;
  border: 2rpx solid rgba(0, 74, 119, 0.3);
  border-radius: 16rpx;
  padding: 0 20rpx;
  line-height: 56rpx;
  background: transparent;
  color: #004a77;
  font-size: 22rpx;
  font-weight: 700;
}

.assist-summary {
  display: block;
  margin-top: 14rpx;
  padding: 18rpx;
  border-radius: 18rpx;
  background: rgba(243, 237, 247, 0.7);
  color: #49454f;
  font-size: 23rpx;
  line-height: 1.5;
}

.source-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10rpx;
  margin: 10rpx 0 20rpx;
}

.source-chip {
  min-height: 62rpx;
  border-radius: 16rpx;
  border: 1rpx solid rgba(0, 74, 119, 0.45);
  color: #1c1b1f;
  background: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22rpx;
  font-weight: 650;
}

.source-chip.active {
  background: #004a77;
  border-color: #004a77;
  color: #ffffff;
  font-weight: 800;
}

.spacing {
  margin-bottom: 16rpx;
}

.split-row {
  display: grid;
  grid-template-columns: 1fr 0.72fr;
  gap: 16rpx;
  margin-bottom: 16rpx;
}

.comment-input {
  min-height: 150rpx;
  margin-bottom: 16rpx;
}

.save-button {
  margin: 28rpx 0 42rpx;
}
</style>
