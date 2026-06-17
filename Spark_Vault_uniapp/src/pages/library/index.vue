<!-- Spark_Vault_uniapp/src/pages/library/index.vue -->
<template>
  <scroll-view scroll-y :class="['sv-page', embedded ? 'library-embedded' : '']">
    <view v-if="!embedded" class="sv-header">
      <view>
        <text class="sv-kicker">LIBRARY INDEX</text>
        <text class="sv-title">碎片库 <text class="sv-title-mark">. Vault</text></text>
      </view>
    </view>

    <view class="search-wrap">
      <text class="search-icon">⌕</text>
      <input
        class="search-input"
        v-model="query"
        placeholder="搜寻笔记标题、内容或标签..."
        confirm-type="search"
        @input="applyFilters"
      />
    </view>

    <scroll-view scroll-x class="chip-scroll">
      <view class="sv-chip-row">
        <text
          v-for="filter in filters"
          :key="filter.key"
          :class="['sv-chip', activeFilter === filter.key ? 'active' : '']"
          @click="selectFilter(filter.key)"
        >
          {{ filter.label }} ({{ countFor(filter.key) }})
        </text>
      </view>
    </scroll-view>

    <view v-if="filteredFragments.length === 0" class="sv-card empty-state">
      <text class="empty-symbol">□</text>
      <text class="empty-title">未检索到关联碎片</text>
      <text class="sv-body">换个关键词试试。</text>
    </view>

    <view
      v-for="fragment in filteredFragments"
      :key="fragment.id"
      class="sv-card fragment-card"
    >
      <view class="sv-between">
        <view class="sv-row meta-row">
          <text :class="['type-badge', isReference(fragment) ? 'reference' : 'thought']">
            {{ isReference(fragment) ? '外部摘录' : '想法' }}
          </text>
          <text class="sv-caption">{{ fragment.sourceType || fragment.sourceTitle || 'Manual' }}</text>
        </view>
        <text class="sv-caption">{{ formatDate(fragment.created_at || fragment.createdAt) }}</text>
      </view>

      <view class="fragment-main" @click="goEditor(fragment.id)">
        <text class="fragment-title">{{ fragment.title || fragment.sourceTitle || '未命名碎片' }} ></text>
        <text class="fragment-copy">{{ fragment.content || fragment.originalText }}</text>
      </view>

      <view v-if="fragment.tags && fragment.tags.length" class="tag-row">
        <text v-for="tag in fragment.tags" :key="tag" class="sv-tag">#{{ tag }}</text>
      </view>

      <view class="card-actions">
        <text :class="['action-link', fragment.favoriteStatus ? 'active' : '']" @click="toggleFavorite(fragment)">
          {{ fragment.favoriteStatus ? '★ 已收藏' : '☆ 收藏' }}
        </text>
        <text class="action-link" @click="goEditor(fragment.id)">修改</text>
        <text class="delete-link" @click="confirmDelete(fragment.id)">删除</text>
      </view>
    </view>

    <button class="float-create" @click="openQuickComposer">＋</button>

    <view v-if="quickComposerOpen" class="composer-mask" @click="closeQuickComposer">
      <view :class="['quick-composer', composerExpanded ? 'expanded' : '']" @click.stop>
        <view
          class="composer-handle"
          @click.stop="toggleComposerHeight"
          @mousedown.stop.prevent="startComposerDrag"
          @touchstart.stop="startComposerDrag"
          @touchmove.stop="moveComposerDrag"
          @touchend.stop="endComposerDrag"
        />
        <textarea
          class="composer-input"
          v-model="quickText"
          placeholder="现在的想法是..."
          :maxlength="2000"
          :auto-height="true"
          focus
        />
        <view v-if="quickAttachments.length" class="attachment-row">
          <text
            v-for="(item, index) in quickAttachments"
            :key="index"
            class="attachment-pill"
          >{{ item.type === 'audio' ? '录音' : '图片' }}</text>
        </view>
        <view class="composer-tools">
          <text class="tool-chip" @click="insertQuickTag">
            <Icon icon="lucide:hash" class="tool-icon" />
          </text>
          <text class="tool-chip" @click="pickQuickImage">
            <Icon icon="lucide:image" class="tool-icon" />
          </text>
          <text class="tool-chip" @click="quickText += '**重点**'">
            <Icon icon="lucide:bold" class="tool-icon" />
          </text>
          <text class="tool-chip" @click="quickText += '\n1. '">
            <Icon icon="lucide:list-ordered" class="tool-icon" />
          </text>
          <text class="tool-chip" @click="quickText += '\n- '">
            <Icon icon="lucide:list" class="tool-icon" />
          </text>
          <text class="tool-chip plugin" @click="showPluginHint">
            <Icon icon="lucide:ellipsis" class="tool-icon" />
          </text>
          <text
            :class="['voice-chip', quickRecording ? 'recording' : '']"
            @click="toggleQuickRecord"
          >
            <Icon :icon="quickRecording ? 'lucide:square' : 'lucide:mic'" class="tool-icon" />
          </text>
          <button class="send-chip" :disabled="!canSaveQuick()" @click="saveQuick">
            <Icon icon="lucide:send" class="tool-icon" />
          </button>
        </view>
      </view>
    </view>
  </scroll-view>
</template>

<script>
import { Icon } from '@iconify/vue'
import { getVaultStore } from '../../store/vaultStore.js'
import { ensureIconifyCollections } from '../../services/iconifyIcons.js'

ensureIconifyCollections()

export default {
  name: 'LibraryPage',
  components: { Icon },
  props: {
    embedded: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      quickText: '',
      quickSaved: false,
      quickComposerOpen: false,
      composerExpanded: false,
      composerDragStartY: 0,
      composerDragDeltaY: 0,
      composerMouseDragging: false,
      quickRecording: false,
      quickAttachments: [],
      query: '',
      activeFilter: 'all',
      fragments: [],
      filteredFragments: [],
      filters: [
        { key: 'all', label: '全部碎片' },
        { key: 'thought', label: '想法' },
        { key: 'reference', label: '摘录' },
        { key: 'faves', label: '收藏' }
      ]
    }
  },
  onShow() {
    this.loadData()
    this.consumeQuickComposerFlag()
  },
  beforeUnmount() {
    this.removeComposerMouseListeners()
  },
  onUnload() {
    this.removeComposerMouseListeners()
  },
  methods: {
    loadData() {
      const store = getVaultStore()
      store.refresh()
      this.fragments = store.state.fragments
      this.applyFilters()
    },
    isReference(fragment) {
      return fragment?.content_type === 'reference_content' || ['书摘', '网页', '文件'].includes(fragment?.subtype)
    },
    applyFilters() {
      const q = this.query.trim().toLowerCase()
      this.filteredFragments = this.fragments.filter((fragment) => {
        if (!fragment) return false
        if (this.activeFilter === 'thought' && this.isReference(fragment)) return false
        if (this.activeFilter === 'reference' && !this.isReference(fragment)) return false
        if (this.activeFilter === 'faves' && !fragment.favoriteStatus) return false
        if (!q) return true
        const haystack = [
          fragment.title,
          fragment.sourceTitle,
          fragment.content,
          fragment.originalText,
          Array.isArray(fragment.tags) ? fragment.tags.join(' ') : ''
        ].join(' ').toLowerCase()
        return haystack.includes(q)
      })
    },
    selectFilter(key) {
      this.activeFilter = key
      this.applyFilters()
    },
    openQuickComposer() {
      this.quickComposerOpen = true
      this.composerExpanded = false
      this.composerDragStartY = 0
      this.composerDragDeltaY = 0
      this.composerMouseDragging = false
      this.setNativeTabBarVisible(false)
    },
    consumeQuickComposerFlag() {
      let shouldOpen = false
      try {
        shouldOpen = uni.getStorageSync('mirrorme_open_quick_composer') === '1'
        if (shouldOpen) uni.removeStorageSync('mirrorme_open_quick_composer')
      } catch (_) {
        shouldOpen = false
      }
      if (shouldOpen) this.openQuickComposer()
    },
    closeQuickComposer() {
      if (this.quickRecording) return
      if (this.canSaveQuick()) {
        this.saveQuick()
        return
      }
      this.resetQuickComposer()
    },
    resetQuickComposer() {
      this.quickComposerOpen = false
      this.composerExpanded = false
      this.composerDragStartY = 0
      this.composerDragDeltaY = 0
      this.composerMouseDragging = false
      this.removeComposerMouseListeners()
      this.setNativeTabBarVisible(true)
    },
    setNativeTabBarVisible(visible) {
      if (typeof uni === 'undefined') return
      const action = visible ? uni.showTabBar : uni.hideTabBar
      if (typeof action !== 'function') return
      try {
        action({ animation: true, fail: () => {} })
      } catch (_) {
        // H5 preview can ignore native tabbar visibility APIs.
      }
    },
    toggleComposerHeight() {
      this.composerExpanded = !this.composerExpanded
    },
    startComposerDrag(event) {
      const pointer = event?.touches?.[0] || event
      this.composerDragStartY = pointer?.clientY || 0
      this.composerDragDeltaY = 0
      if (event?.type === 'mousedown') {
        this.composerMouseDragging = true
        this.addComposerMouseListeners()
      }
    },
    moveComposerDrag(event) {
      const pointer = event?.touches?.[0] || event
      if (!pointer || !this.composerDragStartY) return
      this.composerDragDeltaY = pointer.clientY - this.composerDragStartY
    },
    endComposerDrag() {
      if (this.composerDragDeltaY < -28) {
        this.composerExpanded = true
      } else if (this.composerDragDeltaY > 28) {
        this.composerExpanded = false
      }
      this.composerDragStartY = 0
      this.composerDragDeltaY = 0
      this.composerMouseDragging = false
      this.removeComposerMouseListeners()
    },
    addComposerMouseListeners() {
      if (typeof document === 'undefined') return
      document.addEventListener('mousemove', this.moveComposerDrag)
      document.addEventListener('mouseup', this.endComposerDrag)
    },
    removeComposerMouseListeners() {
      if (typeof document === 'undefined') return
      document.removeEventListener('mousemove', this.moveComposerDrag)
      document.removeEventListener('mouseup', this.endComposerDrag)
    },
    canSaveQuick() {
      return Boolean(this.quickText.trim() || this.quickAttachments.length)
    },
    countFor(key) {
      if (key === 'thought') return this.fragments.filter((f) => !this.isReference(f)).length
      if (key === 'reference') return this.fragments.filter((f) => this.isReference(f)).length
      if (key === 'faves') return this.fragments.filter((f) => f.favoriteStatus).length
      return this.fragments.length
    },
    saveQuickLegacy() {
      const text = this.quickText.trim()
      if (!text) return
      const store = getVaultStore()
      const result = store.saveFragment({
        content: text,
        content_type: 'personal_content',
        subtype: '想法',
        tags: ['随手记']
      })
      if (!result.ok) {
        uni.showToast({ title: result.error || '保存失败', icon: 'none' })
        return
      }
      this.quickText = ''
      this.quickSaved = true
      this.loadData()
      setTimeout(() => { this.quickSaved = false }, 1600)
    },
    saveQuick() {
      const text = this.quickText.trim()
      if (!text && !this.quickAttachments.length) return
      const store = getVaultStore()
      const blocks = []
      if (text) {
        blocks.push({ id: `quick_${Date.now()}`, type: 'paragraph', text })
      }
      this.quickAttachments.forEach((attachment, index) => {
        blocks.push({
          id: `attachment_${Date.now()}_${index}`,
          ...attachment
        })
      })
      const result = store.saveFragment({
        title: text ? text.slice(0, 24) : '未命名碎片',
        content: text,
        originalText: text,
        content_type: 'personal_content',
        subtype: '想法',
        acquisition_method: this.quickAttachments.some((item) => item.type === 'audio') ? 'voice' : 'manual',
        blocks,
        tags: ['随手记录']
      })
      if (!result.ok) {
        uni.showToast({ title: result.error || '保存失败', icon: 'none' })
        return
      }
      this.quickText = ''
      this.quickAttachments = []
      this.resetQuickComposer()
      this.quickSaved = true
      this.loadData()
      setTimeout(() => { this.quickSaved = false }, 1600)
    },
    insertQuickTag() {
      this.quickText = `${this.quickText}${this.quickText ? ' ' : ''}#`
    },
    pickQuickImage() {
      if (typeof uni === 'undefined' || typeof uni.chooseImage !== 'function') {
        uni.showToast({ title: '当前环境不支持选择图片', icon: 'none' })
        return
      }
      uni.chooseImage({
        count: 1,
        sourceType: ['album', 'camera'],
        success: (res) => {
          const path = res?.tempFilePaths?.[0]
          if (!path) {
            uni.showToast({ title: '图片路径为空', icon: 'none' })
            return
          }
          this.quickAttachments = [
            ...this.quickAttachments,
            { type: 'image', src: path, caption: '截图或图片', ocrStatus: '待识别' }
          ]
          uni.showToast({ title: '图片已加入', icon: 'success' })
        },
        fail: () => {
          uni.showToast({ title: '未选择图片', icon: 'none' })
        }
      })
    },
    toggleQuickRecord() {
      if (typeof uni === 'undefined' || typeof uni.getRecorderManager !== 'function') {
        uni.showToast({ title: '当前环境不支持录音', icon: 'none' })
        return
      }
      const recorder = uni.getRecorderManager()
      if (!this.quickRecording) {
        recorder.onStop((res) => {
          const src = res?.tempFilePath
          this.quickRecording = false
          if (!src) {
            uni.showToast({ title: '录音文件为空', icon: 'none' })
            return
          }
          this.quickAttachments = [
            ...this.quickAttachments,
            { type: 'audio', src, transcribeStatus: '待转写' }
          ]
          uni.showToast({ title: '录音已加入', icon: 'success' })
        })
        recorder.start({ duration: 60000, format: 'mp3' })
        this.quickRecording = true
        return
      }
      recorder.stop()
    },
    showPluginHint() {
      uni.showToast({ title: '更多采集方式稍后接入', icon: 'none' })
    },
    toggleFavorite(fragment) {
      if (!fragment || !Number.isInteger(Number(fragment.id))) return
      const store = getVaultStore()
      const result = store.updateFragment(Number(fragment.id), {
        ...fragment,
        favoriteStatus: !fragment.favoriteStatus
      })
      if (!result.ok) {
        uni.showToast({ title: result.error || '操作失败', icon: 'none' })
        return
      }
      this.loadData()
    },
    confirmDelete(id) {
      if (!Number.isInteger(Number(id))) return
      uni.showModal({
        title: '删除碎片',
        content: '确定要删除这条记录吗？',
        confirmText: '删除',
        confirmColor: '#b91c1c',
        success: (res) => {
          if (!res.confirm) return
          const store = getVaultStore()
          const result = store.deleteFragment(Number(id))
          if (!result.ok) {
            uni.showToast({ title: result.error || '删除失败', icon: 'none' })
            return
          }
          this.loadData()
        }
      })
    },
    goEditor(id) {
      if (!id) {
        this.openQuickComposer()
        return
      }
      const url = id ? `/pages/library/editor?id=${id}` : '/pages/library/editor'
      uni.navigateTo({ url })
    },
    formatDate(ts) {
      if (!ts) return ''
      const d = new Date(ts)
      return `${d.getMonth() + 1}/${d.getDate()}`
    }
  }
}
</script>

<style scoped>
.search-wrap {
  position: relative;
  margin-bottom: 18rpx;
}

.library-embedded {
  min-height: auto;
  margin-top: 30rpx;
  padding: 0;
  background: transparent;
}

.search-icon {
  position: absolute;
  left: 24rpx;
  top: 50%;
  transform: translateY(-50%);
  color: rgba(26, 26, 26, 0.4);
  font-size: 30rpx;
  z-index: 1;
}

.search-input {
  width: 100%;
  min-height: 76rpx;
  box-sizing: border-box;
  padding: 0 24rpx 0 72rpx;
  border-radius: 18rpx;
  border: 1rpx solid #dedacf;
  background: #ffffff;
  color: #1a2b48;
  font-size: 24rpx;
  font-weight: 700;
}

.quick-card {
  margin-bottom: 18rpx;
}

.quick-title {
  color: #1a2b48;
  font-size: 21rpx;
  font-weight: 900;
  letter-spacing: 1rpx;
}

.saved-mark {
  color: #047857;
  font-size: 20rpx;
  font-weight: 900;
}

.quick-row {
  display: flex;
  gap: 14rpx;
  margin-top: 16rpx;
}

.quick-input {
  flex: 1;
  min-height: 62rpx;
  padding: 0 18rpx;
  border: 1rpx solid #dedacf;
  border-radius: 14rpx;
  background: #ffffff;
  color: #1a2b48;
  font-size: 23rpx;
}

.quick-button {
  width: 112rpx;
  min-height: 62rpx;
  border-radius: 14rpx;
  background: #1a2b48;
  color: #c4a052;
  font-size: 21rpx;
  font-weight: 900;
  line-height: 62rpx;
}

.quick-button[disabled] {
  opacity: 0.45;
}

.chip-scroll {
  margin-bottom: 18rpx;
  white-space: nowrap;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 64rpx 28rpx;
  border-style: dashed;
}

.empty-symbol {
  color: #c4a052;
  font-size: 54rpx;
}

.empty-title {
  margin-top: 12rpx;
  color: #1a2b48;
  font-size: 26rpx;
  font-weight: 900;
}

.fragment-card {
  margin-bottom: 18rpx;
}

.meta-row {
  min-width: 0;
}

.type-badge {
  padding: 5rpx 12rpx;
  border-radius: 9rpx;
  font-family: "Courier New", monospace;
  font-size: 16rpx;
  font-weight: 900;
}

.type-badge.thought {
  background: #fff8e8;
  border: 1rpx solid #f1d9a8;
  color: #8a5e13;
}

.type-badge.reference {
  background: #1a2b48;
  border: 1rpx solid #1a2b48;
  color: #ffffff;
}

.fragment-main {
  margin-top: 18rpx;
}

.fragment-title {
  display: block;
  color: #1a2b48;
  font-size: 25rpx;
  font-weight: 900;
  line-height: 1.35;
}

.fragment-copy {
  display: block;
  margin-top: 9rpx;
  color: rgba(26, 26, 26, 0.7);
  font-size: 22rpx;
  line-height: 1.55;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
}

.tag-row {
  display: flex;
  flex-wrap: wrap;
  gap: 8rpx;
  margin-top: 16rpx;
}

.card-actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 18rpx;
  padding-top: 16rpx;
  border-top: 1rpx solid rgba(222, 218, 207, 0.65);
}

.action-link,
.delete-link {
  font-size: 21rpx;
  font-weight: 900;
}

.action-link {
  color: rgba(26, 26, 26, 0.55);
}

.action-link.active {
  color: #c4a052;
}

.delete-link {
  color: #b91c1c;
}

.float-create {
  position: fixed;
  right: 32rpx;
  bottom: 144rpx;
  width: 92rpx;
  height: 92rpx;
  border-radius: 999rpx;
  background: #1a2b48;
  color: #c4a052;
  font-size: 46rpx;
  font-weight: 300;
  line-height: 92rpx;
  border: 1rpx solid rgba(196, 160, 82, 0.35);
  box-shadow: 0 18rpx 38rpx rgba(26, 43, 72, 0.28);
}

.composer-mask {
  position: fixed;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  z-index: 99999;
  display: flex;
  align-items: flex-end;
  padding: 0 10rpx;
  background: rgba(26, 26, 26, 0.28);
  box-sizing: border-box;
}

.quick-composer {
  width: 100%;
  min-height: 422rpx;
  padding: 18rpx 34rpx 26rpx;
  border-radius: 34rpx 34rpx 0 0;
  border: 1rpx solid rgba(196, 160, 82, 0.32);
  background: #1a2b48;
  box-shadow: 0 -18rpx 44rpx rgba(26, 43, 72, 0.28);
  box-sizing: border-box;
  transition: min-height 180ms ease-out;
}

.quick-composer.expanded {
  min-height: 72vh;
}

.composer-handle {
  width: 58rpx;
  height: 8rpx;
  margin: 0 auto 30rpx;
  border-radius: 999rpx;
  background: rgba(248, 247, 242, 0.34);
}

.composer-input {
  width: 100%;
  min-height: 186rpx;
  max-height: 420rpx;
  color: #f8f7f2;
  font-size: 32rpx;
  line-height: 1.65;
  background: transparent;
  border: none;
  box-sizing: border-box;
}

.attachment-row {
  display: flex;
  flex-wrap: wrap;
  gap: 10rpx;
  margin: 12rpx 0 6rpx;
}

.attachment-pill {
  height: 42rpx;
  padding: 0 16rpx;
  border-radius: 999rpx;
  background: rgba(248, 247, 242, 0.08);
  border: 1rpx solid rgba(248, 247, 242, 0.14);
  color: #f8f7f2;
  font-size: 20rpx;
  line-height: 42rpx;
}

.composer-tools {
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr)) minmax(74rpx, 88rpx);
  align-items: center;
  gap: 10rpx;
  margin-top: 22rpx;
  padding-top: 20rpx;
  border-top: 1rpx solid rgba(248, 247, 242, 0.12);
  overflow: hidden;
}

.tool-chip,
.voice-chip,
.send-chip {
  min-width: 0;
  width: 100%;
  height: 58rpx;
  padding: 0 8rpx;
  border-radius: 999rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(248, 247, 242, 0.08);
  border: 1rpx solid rgba(248, 247, 242, 0.14);
  color: #f8f7f2;
  font-size: 24rpx;
  font-weight: 800;
  box-sizing: border-box;
}

.tool-chip.plugin {
  color: #c4a052;
}

.tool-icon {
  width: 30rpx;
  height: 30rpx;
}

.voice-chip {
  color: #c4a052;
  border: 1rpx solid rgba(196, 160, 82, 0.32);
  background: rgba(196, 160, 82, 0.10);
}

.voice-chip.recording {
  color: #fecaca;
  border-color: rgba(248, 113, 113, 0.36);
  background: rgba(127, 29, 29, 0.36);
}

.send-chip {
  min-width: 0;
  margin: 0;
  background: #c4a052;
  color: #1a2b48;
  border: none;
  line-height: 58rpx;
}

.send-chip[disabled] {
  opacity: 0.38;
}
</style>
