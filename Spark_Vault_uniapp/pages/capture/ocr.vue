<template>
  <view class="page">
    <text class="title">OCR Presets</text>
    <text class="subtitle">Capture text from images using Tesseract.js (offline, no API key needed).</text>

    <!-- Book mode -->
    <view class="mode-card">
      <text class="mode-title">Book / Document</text>
      <text class="mode-desc">Scan a book page, document, or printed text. Works best with clear print.</text>
      <button class="btn" :loading="bookLoading" @click="pickAndOCR('book')">
        {{ bookLoading ? bookProgress : '📖 Scan Book Page' }}
      </button>
    </view>

    <!-- Screenshot mode -->
    <view class="mode-card">
      <text class="mode-title">Screenshot / Article</text>
      <text class="mode-desc">Extract text from screen captures, article images, or social media posts.</text>
      <button class="btn" :loading="screenshotLoading" @click="pickAndOCR('screenshot')">
        {{ screenshotLoading ? screenshotProgress : '🖼️ Scan Screenshot' }}
      </button>
    </view>

    <!-- Tips -->
    <view class="tips">
      <text class="tips-title">Tips for best results</text>
      <text class="tips-item">• Use clear, well-lit images</text>
      <text class="tips-item">• Avoid heavily stylized or decorative fonts</text>
      <text class="tips-item">• Multi-column layouts may require manual cleanup</text>
      <text class="tips-item">• English text works best; other languages depend on trained data</text>
    </view>

    <!-- Result preview -->
    <view v-if="recognizedText" class="result">
      <text class="result-title">Recognized Text</text>
      <textarea class="result-text" v-model="recognizedText" readonly />
      <view class="result-actions">
        <button class="btn-confirm" @click="confirmText">Use This Text</button>
        <button class="btn-cancel" @click="clearResult">Discard</button>
      </view>
    </view>

    <!-- Error -->
    <view v-if="errorMsg" class="error-box">
      <text class="error-text">{{ errorMsg }}</text>
    </view>
  </view>
</template>

<script>
import Tesseract from 'tesseract.js'

export default {
  data() {
    return {
      bookLoading: false,
      screenshotLoading: false,
      bookProgress: 'Initializing...',
      screenshotProgress: 'Initializing...',
      recognizedText: '',
      errorMsg: ''
    }
  },
  onShow() {
    // Check if we returned from a re-pick (clear old result)
  },
  methods: {
    async pickAndOCR(mode) {
      this.errorMsg = ''
      this.recognizedText = ''

      // Pick image
      const res = await new Promise((resolve) => {
        uni.chooseImage({
          count: 1,
          sourceType: mode === 'book' ? ['album', 'camera'] : ['album', 'camera'],
          success: (r) => resolve(r),
          fail: () => resolve(null)
        })
      })

      if (!res || !res.tempFilePaths?.length) return

      const filePath = res.tempFilePaths[0]
      const progressKey = mode === 'book' ? 'bookProgress' : 'screenshotProgress'
      const loadingKey = mode === 'book' ? 'bookLoading' : 'screenshotLoading'

      this[loadingKey] = true
      this[progressKey] = 'Loading image...'

      try {
        const result = await Tesseract.recognize(filePath, 'eng', {
          logger: (m) => {
            if (m.status === 'recognizing text') {
              const pct = Math.round((m.progress || 0) * 100)
              this[progressKey] = `Recognizing... ${pct}%`
            } else {
              this[progressKey] = m.status
            }
          }
        })

        const text = (result.data.text || '').trim()
        if (!text) {
          this.errorMsg = 'No text was recognized. Try a clearer image.'
        } else {
          this.recognizedText = text
        }
      } catch (e) {
        this.errorMsg = `OCR failed: ${e.message || 'Unknown error'}`
      } finally {
        this[loadingKey] = false
        this[progressKey] = ''
      }
    },

    confirmText() {
      if (!this.recognizedText) return
      // Navigate back, passing recognized text via query + global event
      const pages = getCurrentPages()
      const prevPage = pages[pages.length - 2]
      if (prevPage) {
        // Direct method call on previous page (cleanest in uniapp)
        const capturePage = pages.find((p) => p.route === 'pages/capture/index')
        if (capturePage?.$vm?.onOcrResult) {
          capturePage.$vm.onOcrResult(this.recognizedText)
        }
      }
      // Also emit global event as fallback
      uni.$emit('capture-ocr-result', { text: this.recognizedText })
      uni.navigateBack()
    },

    clearResult() {
      this.recognizedText = ''
      this.errorMsg = ''
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
.mode-card {
  background: #ffffff;
  border-radius: 14rpx;
  padding: 20rpx;
  margin-bottom: 20rpx;
  border: 1px solid #e2e8f0;
}
.mode-title {
  font-size: 30rpx;
  font-weight: 600;
  color: #0f172a;
  display: block;
  margin-bottom: 8rpx;
}
.mode-desc {
  font-size: 24rpx;
  color: #64748b;
  display: block;
  margin-bottom: 14rpx;
}
.btn {
  width: 100%;
  background: #0f172a;
  color: #ffffff;
  border-radius: 10rpx;
  font-size: 28rpx;
  padding: 14rpx;
  line-height: 1.5;
}
.tips {
  background: #fffbeb;
  border-radius: 12rpx;
  padding: 16rpx;
  margin-top: 8rpx;
  border: 1px solid #fde68a;
}
.tips-title {
  font-size: 24rpx;
  font-weight: 600;
  color: #92400e;
  display: block;
  margin-bottom: 10rpx;
}
.tips-item {
  font-size: 22rpx;
  color: #78350f;
  display: block;
  margin-bottom: 4rpx;
}
.result {
  background: #ffffff;
  border-radius: 14rpx;
  padding: 20rpx;
  margin-top: 20rpx;
  border: 1px solid #22c55e;
}
.result-title {
  font-size: 26rpx;
  font-weight: 600;
  color: #15803d;
  display: block;
  margin-bottom: 10rpx;
}
.result-text {
  width: 100%;
  min-height: 200rpx;
  background: #f0fdf4;
  border-radius: 10rpx;
  padding: 12rpx;
  font-size: 26rpx;
  color: #14532d;
  box-sizing: border-box;
  border: 1px solid #bbf7d0;
}
.result-actions {
  display: flex;
  gap: 12rpx;
  margin-top: 12rpx;
}
.btn-confirm {
  flex: 1;
  background: #16a34a;
  color: #ffffff;
  border-radius: 10rpx;
  font-size: 26rpx;
  padding: 12rpx;
}
.btn-cancel {
  flex: 1;
  background: #f1f5f9;
  color: #475569;
  border-radius: 10rpx;
  font-size: 26rpx;
  padding: 12rpx;
}
.error-box {
  background: #fef2f2;
  border-radius: 10rpx;
  padding: 14rpx;
  margin-top: 16rpx;
  border: 1px solid #fecaca;
}
.error-text {
  font-size: 24rpx;
  color: #dc2626;
}
</style>
