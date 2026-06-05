<template>
  <view class="page">
    <text class="title">Metadata</text>
    <text class="subtitle">Provide additional context for this fragment.</text>

    <view class="form">
      <!-- Source type -->
      <view class="field">
        <text class="label">Source Type</text>
        <picker :range="sourceTypes" :value="formIndex" @change="onSourceChange">
          <view class="picker">{{ form.sourceType }}</view>
        </picker>
      </view>

      <!-- Source title -->
      <view class="field">
        <text class="label">Source Title</text>
        <input class="input" v-model="form.sourceTitle" placeholder="e.g. Atomic Habits" />
      </view>

      <!-- Author -->
      <view class="field">
        <text class="label">Author</text>
        <input class="input" v-model="form.author" placeholder="e.g. James Clear" />
      </view>

      <!-- Page number -->
      <view class="field">
        <text class="label">Page Number</text>
        <input class="input" v-model="form.pageNumber" placeholder="e.g. 28" />
      </view>

      <!-- Source URL -->
      <view class="field">
        <text class="label">Source URL</text>
        <input class="input" v-model="form.sourceUrl" placeholder="https://..." type="url" />
      </view>

      <!-- Tags -->
      <view class="field">
        <text class="label">Tags (comma-separated)</text>
        <input class="input" v-model="form.tagsText" placeholder="e.g. Systems, Growth, Habits" />
      </view>

      <!-- Personal comment -->
      <view class="field">
        <text class="label">Personal Comment</text>
        <textarea class="textarea" v-model="form.userComment" placeholder="Why does this matter? What triggered it?" />
      </view>

      <!-- OCR text (readonly, from previous step) -->
      <view v-if="form.ocrText" class="field">
        <text class="label">OCR Text (from scan, read-only)</text>
        <textarea class="textarea ocr-text" v-model="form.ocrText" readonly />
      </view>
    </view>

    <!-- Actions -->
    <view class="actions">
      <button class="btn-confirm" @click="confirm">Confirm & Return</button>
      <button class="btn-cancel" @click="cancel">Cancel</button>
    </view>
  </view>
</template>

<script>
import { SOURCE_TYPES } from '../../services/vaultLogic.js'

export default {
  data() {
    return {
      sourceTypes: SOURCE_TYPES.filter((t) => t !== 'All'),
      formIndex: 0,
      form: {
        sourceType: 'Book',
        sourceTitle: '',
        author: '',
        pageNumber: '',
        sourceUrl: '',
        tagsText: '',
        userComment: '',
        ocrText: ''
      }
    }
  },
  onLoad(query) {
    // Receive OCR text from query (navigateTo with query params)
    if (query && query.ocrText) {
      try {
        this.form.ocrText = decodeURIComponent(query.ocrText)
      } catch {
        this.form.ocrText = query.ocrText || ''
      }
    }
  },
  methods: {
    onSourceChange(event) {
      const index = Number(event.detail.value)
      this.formIndex = Number.isInteger(index) ? index : 0
      this.form.sourceType = this.sourceTypes[this.formIndex] || 'Other'
    },
    confirm() {
      // Send form data back to capture/index via global event
      uni.$emit('capture-metadata-result', { ...this.form })
      uni.navigateBack()
    },
    cancel() {
      uni.navigateBack()
    }
  }
}
</script>

<style scoped>
.page {
  padding: 24rpx;
  background: #f8fafc;
  min-height: 100vh;
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
  margin-bottom: 24rpx;
}
.form {
  background: #ffffff;
  border-radius: 14rpx;
  padding: 20rpx;
  border: 1px solid #e2e8f0;
}
.field {
  margin-bottom: 20rpx;
}
.label {
  font-size: 24rpx;
  color: #334155;
  display: block;
  margin-bottom: 8rpx;
  font-weight: 500;
}
.input,
.picker {
  background: #f8fafc;
  border-radius: 10rpx;
  padding: 12rpx;
  font-size: 26rpx;
  color: #0f172a;
  border: 1px solid #e2e8f0;
}
.textarea {
  width: 100%;
  min-height: 140rpx;
  background: #f8fafc;
  border-radius: 10rpx;
  padding: 12rpx;
  font-size: 26rpx;
  color: #0f172a;
  box-sizing: border-box;
  border: 1px solid #e2e8f0;
}
.ocr-text {
  background: #f0fdf4;
  border-color: #bbf7d0;
  color: #14532d;
  font-size: 24rpx;
}
.actions {
  margin-top: 20rpx;
  display: flex;
  flex-direction: column;
  gap: 10rpx;
}
.btn-confirm {
  background: #0f172a;
  color: #ffffff;
  border-radius: 10rpx;
  font-size: 28rpx;
  padding: 14rpx;
}
.btn-cancel {
  background: #f1f5f9;
  color: #475569;
  border-radius: 10rpx;
  font-size: 28rpx;
  padding: 14rpx;
}
</style>
