<!-- Spark_Vault_uniapp/pages/capture/index.vue -->
<template>
  <view class="page">
    <text class="title">Capture</text>
    <text class="subtitle">Save text fragments with metadata, tags, and local AI helpers.</text>

    <!-- OCR banner (shows when OCR text is available) -->
    <view v-if="form.ocrText" class="ocr-banner">
      <text class="ocr-label">✅ OCR Text Captured</text>
      <text class="ocr-text-preview">{{ form.ocrText.slice(0, 100) }}{{ form.ocrText.length > 100 ? '...' : '' }}</text>
      <view class="ocr-actions">
        <button class="btn-small" @click="clearOcr">Clear OCR</button>
      </view>
    </view>

    <!-- Fragment text area -->
    <view class="section">
      <text class="label">Fragment Quote / Text</text>
      <textarea
        class="textarea"
        v-model="form.originalText"
        placeholder="Paste quote text, or use the OCR button below to scan from an image..."
      />
      <view class="ocr-row">
        <button class="btn-ocr" @click="goOcr">📷 Scan from Image (OCR)</button>
      </view>
    </view>

    <!-- Basic metadata -->
    <view class="section">
      <text class="label">Basic Metadata</text>
      <picker :range="sourceTypes" :value="sourceIndex" @change="onSourceChange">
        <view class="picker">{{ form.sourceType }}</view>
      </picker>
      <input class="input" v-model="form.sourceTitle" placeholder="Source Title" />
      <input class="input" v-model="form.author" placeholder="Author" />
      <input class="input" v-model="form.pageNumber" placeholder="Page Number" />
    </view>

    <!-- Advanced metadata -->
    <view class="section">
      <text class="label">More Fields</text>
      <input class="input" v-model="form.sourceUrl" placeholder="Source URL" />
      <input class="input" v-model="form.tagsText" placeholder="Tags (comma-separated)" />
      <textarea class="textarea small" v-model="form.userComment" placeholder="Personal comment: why does this matter?" />
      <button class="btn-link" @click="goMetadata">⚙️ Advanced Metadata →</button>
    </view>

    <!-- Save -->
    <view class="actions">
      <button type="primary" @click="save" :disabled="saving">
        {{ saving ? 'Saving...' : '💾 Save Fragment' }}
      </button>
    </view>

    <!-- Toast -->
    <view v-if="toastMsg" class="toast" :class="toastType">{{ toastMsg }}</view>
  </view>
</template>

<script>
import { SOURCE_TYPES } from '../../services/vaultLogic.js'
import { vaultStore } from '../../store/vaultStore.js'

export default {
  data() {
    return {
      sourceTypes: SOURCE_TYPES.filter((item) => item !== 'All'),
      sourceIndex: 0,
      form: {
        originalText: '',
        sourceType: 'Book',
        sourceTitle: '',
        sourceUrl: '',
        author: '',
        pageNumber: '',
        tagsText: '',
        userComment: '',
        ocrText: ''
      },
      saving: false,
      toastMsg: '',
      toastTimer: null
    }
  },
  onShow() {
    // Listen for events from sub-pages
    uni.$on('capture-ocr-result', this.onOcrResult)
    uni.$on('capture-metadata-result', this.onMetadataResult)
  },
  onHide() {
    // Clean up listeners to avoid duplicates
    uni.$off('capture-ocr-result', this.onOcrResult)
    uni.$off('capture-metadata-result', this.onMetadataResult)
  },
  methods: {
    onOcrResult(payload) {
      if (!payload || !payload.text) return
      const text = payload.text.trim()
      if (!text) return
      this.form.ocrText = text
      // If the main text is empty, prefill it from OCR
      if (!this.form.originalText) {
        this.form.originalText = text
      }
      this.showToast('OCR text captured!', 'success')
    },

    onMetadataResult(payload) {
      if (!payload) return
      // Merge metadata fields back into form
      const {
        sourceType, sourceTitle, author, pageNumber,
        sourceUrl, tagsText, userComment, ocrText
      } = payload

      if (sourceType) this.form.sourceType = sourceType
      if (sourceTitle !== undefined) this.form.sourceTitle = sourceTitle
      if (author !== undefined) this.form.author = author
      if (pageNumber !== undefined) this.form.pageNumber = pageNumber
      if (sourceUrl !== undefined) this.form.sourceUrl = sourceUrl
      if (tagsText !== undefined) this.form.tagsText = tagsText
      if (userComment !== undefined) this.form.userComment = userComment
      if (ocrText) this.form.ocrText = ocrText

      this.showToast('Metadata updated', 'success')
    },

    goOcr() {
      uni.navigateTo({ url: '/pages/capture/ocr' })
    },

    goMetadata() {
      // Pass current form data via query params (as backup)
      const query = {
        sourceType: this.form.sourceType,
        sourceTitle: this.form.sourceTitle,
        author: this.form.author,
        pageNumber: this.form.pageNumber,
        sourceUrl: this.form.sourceUrl,
        tagsText: this.form.tagsText,
        userComment: this.form.userComment,
        ocrText: this.form.ocrText
      }
      const queryStr = Object.entries(query)
        .filter(([, v]) => v)
        .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
        .join('&')
      uni.navigateTo({ url: '/pages/capture/metadata' + (queryStr ? '?' + queryStr : '') })
    },

    clearOcr() {
      this.form.ocrText = ''
      this.showToast('OCR text cleared', 'info')
    },

    onSourceChange(event) {
      const index = Number(event.detail.value)
      this.sourceIndex = Number.isInteger(index) ? index : 0
      this.form.sourceType = this.sourceTypes[this.sourceIndex] || 'Other'
    },

    save() {
      if (!this.form.originalText?.trim()) {
        this.showToast('Please enter or scan some text first', 'error')
        return
      }

      this.saving = true
      const result = vaultStore.saveFragment({
        ...this.form,
        // Pass ocrText as a field if createFragment supports it
        ocrText: this.form.ocrText || null
      })

      if (!result.ok) {
        this.showToast(result.error || 'Save failed', 'error')
        this.saving = false
        return
      }

      this.saving = false
      this.showToast('Fragment saved!', 'success')
      this.resetForm()

      setTimeout(() => {
        uni.switchTab({ url: '/pages/library/index' })
      }, 800)
    },

    resetForm() {
      this.form = {
        originalText: '',
        sourceType: this.form.sourceType || 'Book',
        sourceTitle: '',
        sourceUrl: '',
        author: '',
        pageNumber: '',
        tagsText: '',
        userComment: '',
        ocrText: ''
      }
      this.sourceIndex = 0
    },

    showToast(msg, type = 'info') {
      if (this.toastTimer) clearTimeout(this.toastTimer)
      this.toastMsg = msg
      this.toastType = type
      this.toastTimer = setTimeout(() => {
        this.toastMsg = ''
      }, 2500)
    }
  }
}
</script>

<style scoped>
.page {
  padding: 24rpx;
  background: #f8fafc;
  min-height: 100vh;
  padding-bottom: 120rpx;
}
.title {
  font-size: 40rpx;
  font-weight: 700;
  display: block;
  color: #0f172a;
}
.subtitle {
  font-size: 24rpx;
  color: #64748b;
  display: block;
  margin-top: 8rpx;
  margin-bottom: 20rpx;
}
.ocr-banner {
  background: #f0fdf4;
  border: 1px solid #22c55e;
  border-radius: 12rpx;
  padding: 14rpx;
  margin-bottom: 16rpx;
}
.ocr-label {
  font-size: 24rpx;
  font-weight: 600;
  color: #15803d;
  display: block;
  margin-bottom: 6rpx;
}
.ocr-text-preview {
  font-size: 22rpx;
  color: #166534;
  display: block;
  margin-bottom: 8rpx;
  line-height: 1.5;
}
.ocr-actions {
  display: flex;
  gap: 8rpx;
}
.btn-small {
  background: #dcfce7;
  color: #15803d;
  border-radius: 8rpx;
  font-size: 22rpx;
  padding: 8rpx 16rpx;
  border: 1px solid #86efac;
}
.section {
  margin-bottom: 16rpx;
  background: #ffffff;
  border-radius: 14rpx;
  padding: 14rpx;
  border: 1px solid #e2e8f0;
}
.label {
  display: block;
  font-size: 24rpx;
  color: #334155;
  margin-bottom: 8rpx;
  font-weight: 500;
}
.textarea {
  width: 100%;
  min-height: 180rpx;
  background: #f8fafc;
  border-radius: 10rpx;
  padding: 12rpx;
  box-sizing: border-box;
  font-size: 26rpx;
  color: #0f172a;
  border: 1px solid #e2e8f0;
}
.textarea.small {
  min-height: 120rpx;
}
.input,
.picker {
  margin-top: 10rpx;
  background: #f8fafc;
  border-radius: 10rpx;
  padding: 12rpx;
  font-size: 26rpx;
  box-sizing: border-box;
  color: #0f172a;
  border: 1px solid #e2e8f0;
}
.ocr-row {
  margin-top: 10rpx;
}
.btn-ocr {
  width: 100%;
  background: #eff6ff;
  color: #1d4ed8;
  border-radius: 10rpx;
  font-size: 26rpx;
  padding: 12rpx;
  border: 1px solid #bfdbfe;
}
.btn-link {
  width: 100%;
  background: #f8fafc;
  color: #64748b;
  border-radius: 10rpx;
  font-size: 24rpx;
  padding: 10rpx;
  margin-top: 8rpx;
  border: 1px dashed #cbd5e1;
}
.actions {
  margin-top: 16rpx;
}
.toast {
  position: fixed;
  bottom: 120rpx;
  left: 50%;
  transform: translateX(-50%);
  padding: 12rpx 24rpx;
  border-radius: 10rpx;
  font-size: 26rpx;
  z-index: 9999;
  max-width: 600rpx;
  text-align: center;
}
.toast.success {
  background: #16a34a;
  color: #ffffff;
}
.toast.error {
  background: #dc2626;
  color: #ffffff;
}
.toast.info {
  background: #0f172a;
  color: #ffffff;
}
</style>
