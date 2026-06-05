<!-- pages/library/editor.vue — S2 全屏碎片编辑（Notion 式） -->
<template>
  <view class="editor-page">
    <!-- Nav bar -->
    <view class="nav-bar">
      <text class="nav-cancel" @click="handleCancel">取消</text>
      <text class="nav-title">{{ isEdit ? '编辑碎片' : '新建碎片' }}</text>
      <text class="nav-save" @click="handleSave" :class="{ disabled: !canSave }">保存</text>
    </view>

    <!-- Content type chips -->
    <view class="type-row">
      <text
        :class="['type-chip', contentType === 'personal_content' ? 'active' : '']"
        @click="contentType = 'personal_content'"
      >💡 我的想法</text>
      <text
        :class="['type-chip', contentType === 'reference_content' ? 'active' : '']"
        @click="contentType = 'reference_content'"
      >📖 参考摘录</text>
    </view>

    <!-- Canvas -->
    <scroll-view class="canvas" scroll-y>
      <!-- Title -->
      <input
        class="canvas-title"
        v-model="title"
        placeholder="标题（可选）"
        maxlength="100"
      />

      <!-- Body text -->
      <textarea
        class="canvas-body"
        v-model="content"
        placeholder="写下你的想法、摘录、感悟…"
        :maxlength="5000"
        auto-height
      />

      <!-- URL preview card (if link mode) -->
      <view v-if="urlPreview" class="url-card">
        <text class="url-icon">🌐</text>
        <view class="url-info">
          <text class="url-domain">{{ urlDomain }}</text>
          <text class="url-link">{{ url }}</text>
        </view>
        <text class="url-remove" @click="removeUrl">✕</text>
      </view>

      <!-- URL input (shown when link mode active) -->
      <view v-if="showUrlInput" class="url-input-wrap">
        <input
          class="url-input"
          v-model="url"
          placeholder="粘贴网页链接…"
          @blur="confirmUrl"
        />
        <text class="url-confirm" @click="confirmUrl">确认</text>
      </view>

      <!-- Tags -->
      <view class="tags-row">
        <text class="tag" v-for="tag in tags" :key="tag">#{{ tag }}</text>
        <input
          class="tag-input"
          v-model="tagInput"
          placeholder="＋ 添加标签"
          @confirm="addTag"
          @blur="addTag"
          maxlength="20"
        />
      </view>

      <!-- Source info (reference mode) -->
      <view v-if="contentType === 'reference_content'" class="source-section">
        <text class="source-section-title">来源信息</text>
        <input class="source-input" v-model="sourceTitle" placeholder="来源标题（书名/文章名…）" />
        <input class="source-input" v-model="sourceAuthor" placeholder="作者（可选）" />
      </view>
    </scroll-view>

    <!-- Toolbar -->
    <view class="toolbar">
      <view class="toolbar-row">
        <text class="tool-btn" @click="toggleUrlInput">🔗</text>
        <text class="tool-btn" @click="chooseImage">📷</text>
      </view>
    </view>

    <!-- Delete (edit mode only) -->
    <view v-if="isEdit" class="delete-area">
      <text class="delete-btn" @click="handleDelete">删除此碎片</text>
    </view>
  </view>
</template>

<script>
import { getVaultStore } from '@/store/vaultStore.js'

const store = getVaultStore()

export default {
  data() {
    return {
      fragmentId: null,
      isEdit: false,
      contentType: 'personal_content',
      title: '',
      content: '',
      tags: [],
      tagInput: '',
      url: '',
      urlPreview: false,
      showUrlInput: false,
      sourceTitle: '',
      sourceAuthor: '',
      saving: false
    }
  },
  computed: {
    canSave() {
      return this.content.trim().length > 0 || this.url.trim().length > 0
    },
    urlDomain() {
      try {
        return new URL(this.url).hostname
      } catch (_) {
        return this.url
      }
    }
  },
  onLoad(options) {
    // Load draft from storage if coming from Library quick-capture
    if (options.from === 'draft') {
      try {
        const draft = uni.getStorageSync('editor_draft')
        if (draft) {
          this.content = draft.text || ''
          this.contentType = draft.content_type || 'personal_content'
          uni.removeStorageSync('editor_draft')
        }
      } catch (_) {}
    }

    // Load existing fragment for editing
    if (options.id) {
      this.fragmentId = Number(options.id)
      this.isEdit = true
      this.loadFragment(this.fragmentId)
    }

    // Pre-fill mode (photo/voice/link)
    if (options.mode === 'link') {
      this.showUrlInput = true
    }
  },
  methods: {
    loadFragment(id) {
      const f = store.getFragmentById(id)
      if (!f) return
      this.contentType = f.content_type || 'personal_content'
      this.title = f.title || ''
      this.content = f.content || ''
      this.tags = Array.isArray(f.tags) ? [...f.tags] : []
      this.url = f.source_url || ''
      if (this.url) this.urlPreview = true
    },
    addTag() {
      const t = this.tagInput.trim().replace(/^#/, '')
      if (t && !this.tags.includes(t)) {
        this.tags.push(t)
      }
      this.tagInput = ''
    },
    toggleUrlInput() {
      if (this.urlPreview) return
      this.showUrlInput = !this.showUrlInput
    },
    confirmUrl() {
      const u = this.url.trim()
      if (!u) { this.showUrlInput = false; return }
      this.urlPreview = true
      this.showUrlInput = false
      if (!this.content.trim()) {
        this.contentType = 'reference_content'
      }
    },
    removeUrl() {
      this.url = ''
      this.urlPreview = false
    },
    chooseImage() {
      uni.chooseImage({
        count: 1,
        sizeType: ['compressed'],
        sourceType: ['album', 'camera'],
        success: (res) => {
          const path = res.tempFilePaths[0]
          // Insert as placeholder text (actual OCR would need API call)
          this.content += `\n[图片: ${path.split('/').pop()}]`
          uni.showToast({ title: 'OCR 识别需要后端支持', icon: 'none', duration: 2000 })
        }
      })
    },
    handleCancel() {
      if (this.content.trim() || this.title.trim()) {
        uni.showModal({
          title: '放弃编辑？',
          content: '未保存的内容将丢失',
          confirmText: '放弃',
          cancelText: '继续编辑',
          success: (res) => { if (res.confirm) uni.navigateBack() }
        })
      } else {
        uni.navigateBack()
      }
    },
    handleSave() {
      if (!this.canSave) return
      if (this.saving) return
      this.addTag() // flush tag input
      this.saving = true

      const data = {
        content: this.content.trim() || this.url,
        content_type: this.contentType,
        subtype: this.contentType === 'reference_content' ? '书摘' : '想法',
        title: this.title.trim() || null,
        tags: this.tags,
        source_url: this.url.trim() || null
      }

      let result
      if (this.isEdit && this.fragmentId) {
        result = store.updateFragment(this.fragmentId, data)
      } else {
        result = store.saveFragment(data)
      }

      this.saving = false
      if (result.ok) {
        uni.showToast({ title: '已保存', icon: 'success', duration: 1000 })
        setTimeout(() => uni.navigateBack(), 1000)
      } else {
        uni.showToast({ title: result.error || '保存失败', icon: 'none' })
      }
    },
    handleDelete() {
      uni.showModal({
        title: '删除碎片',
        content: '删除后无法恢复',
        confirmText: '删除',
        confirmColor: '#ba1a1a',
        cancelText: '取消',
        success: (res) => {
          if (res.confirm && this.fragmentId) {
            store.deleteFragment(this.fragmentId)
            uni.navigateBack()
          }
        }
      })
    }
  }
}
</script>

<style scoped>
.editor-page { display: flex; flex-direction: column; height: 100vh; background: #ffffff; }

/* Nav */
.nav-bar { display: flex; justify-content: space-between; align-items: center; padding: 20rpx 28rpx; border-bottom: 2rpx solid #f0ece6; }
.nav-cancel { font-size: 28rpx; color: #49454f; }
.nav-title { font-size: 30rpx; font-weight: 700; color: #1c1b1f; }
.nav-save { font-size: 28rpx; color: #004a77; font-weight: 700; }
.nav-save.disabled { opacity: 0.3; }

/* Type chips */
.type-row { display: flex; gap: 16rpx; padding: 16rpx 28rpx; border-bottom: 2rpx solid #f0ece6; }
.type-chip { padding: 10rpx 24rpx; border-radius: 48rpx; font-size: 26rpx; color: #49454f; background: #f5f2ee; }
.type-chip.active { background: #004a77; color: #ffffff; }

/* Canvas */
.canvas { flex: 1; padding: 24rpx 28rpx; overflow: hidden; }
.canvas-title { width: 100%; font-size: 36rpx; font-weight: 700; color: #1c1b1f; margin-bottom: 20rpx; border: none; background: transparent; }
.canvas-body { width: 100%; font-size: 28rpx; line-height: 1.72; color: #1c1b1f; min-height: 300rpx; background: transparent; border: none; }

/* URL card */
.url-card { display: flex; align-items: center; gap: 14rpx; background: #f5f2ee; border-radius: 16rpx; padding: 16rpx 20rpx; margin: 16rpx 0; }
.url-icon { font-size: 32rpx; }
.url-info { flex: 1; }
.url-domain { display: block; font-size: 26rpx; font-weight: 600; color: #1c1b1f; }
.url-link { display: block; font-size: 22rpx; color: #49454f; word-break: break-all; }
.url-remove { font-size: 26rpx; color: #49454f; padding: 8rpx; }

/* URL input */
.url-input-wrap { display: flex; align-items: center; gap: 12rpx; background: #f5f2ee; border-radius: 16rpx; padding: 14rpx 20rpx; margin: 16rpx 0; }
.url-input { flex: 1; font-size: 26rpx; color: #1c1b1f; background: transparent; }
.url-confirm { font-size: 26rpx; color: #004a77; font-weight: 700; }

/* Tags */
.tags-row { display: flex; flex-wrap: wrap; gap: 10rpx; margin: 16rpx 0; align-items: center; }
.tag { font-size: 22rpx; color: #004a77; background: #e8f0fb; border-radius: 8rpx; padding: 6rpx 12rpx; }
.tag-input { font-size: 24rpx; color: #49454f; min-width: 120rpx; background: transparent; }

/* Source section */
.source-section { margin-top: 24rpx; border-top: 2rpx solid #f0ece6; padding-top: 20rpx; }
.source-section-title { display: block; font-size: 24rpx; color: #49454f; font-weight: 600; margin-bottom: 14rpx; }
.source-input { width: 100%; font-size: 26rpx; color: #1c1b1f; background: #f5f2ee; border-radius: 12rpx; padding: 14rpx 16rpx; margin-bottom: 12rpx; }

/* Toolbar */
.toolbar { padding: 16rpx 28rpx; border-top: 2rpx solid #f0ece6; background: #ffffff; }
.toolbar-row { display: flex; gap: 24rpx; }
.tool-btn { font-size: 32rpx; padding: 8rpx 12rpx; color: #49454f; }

/* Delete */
.delete-area { padding: 16rpx 28rpx 32rpx; text-align: center; }
.delete-btn { font-size: 26rpx; color: #ba1a1a; }
</style>
