<!-- pages/library/index.vue — Library Tab：碎片收集与浏览 -->
<template>
  <scroll-view class="page" scroll-y>
    <!-- Header -->
    <view class="header">
      <view class="header-left">
        <text class="title">Library</text>
        <text class="subtitle">我的知识碎片</text>
      </view>
      <view class="header-icons">
        <text class="icon-btn" @click="navigate('/pages/library/browser')">⌕</text>
        <text class="icon-btn" @click="navigate('/pages/library/browser')">≡</text>
      </view>
    </view>

    <!-- Quick capture card -->
    <view class="capture-card">
      <text class="capture-card-title">＋ 添加碎片</text>

      <!-- Type chips -->
      <view class="type-chips">
        <text
          v-for="t in captureTypes"
          :key="t.value"
          :class="['type-chip', captureType === t.value ? 'active' : '']"
          @click="captureType = t.value"
        >{{ t.label }}</text>
      </view>

      <!-- Textarea with expand icon -->
      <view class="textarea-wrap">
        <textarea
          class="capture-textarea"
          v-model="draftText"
          placeholder="随手记录一个想法…"
          :maxlength="2000"
          auto-height
        />
        <text class="expand-icon" @click="openEditor()">⤢</text>
      </view>

      <!-- Quick action buttons -->
      <view class="quick-actions">
        <view class="quick-btn" @click="openEditor('photo')">
          <text class="quick-btn-icon">📷</text>
          <text class="quick-btn-label">拍照</text>
        </view>
        <view class="quick-btn" @click="openEditor('voice')">
          <text class="quick-btn-icon">🎙</text>
          <text class="quick-btn-label">录音</text>
        </view>
        <view class="quick-btn" @click="openEditor('link')">
          <text class="quick-btn-icon">🌐</text>
          <text class="quick-btn-label">网页</text>
        </view>
      </view>

      <!-- Save button -->
      <button
        class="save-btn"
        :disabled="!draftText.trim() || saving"
        @click="quickSave"
      >{{ saving ? '保存中…' : '保存到 Library' }}</button>
    </view>

    <!-- Fragment list filter chips -->
    <scroll-view class="chips-row" scroll-x>
      <view class="chips-inner">
        <text
          v-for="chip in filterChips"
          :key="chip"
          :class="['chip', activeChip === chip ? 'active' : '']"
          @click="setChip(chip)"
        >{{ chip }}</text>
      </view>
    </scroll-view>

    <!-- Fragment list -->
    <view class="list-section">
      <text class="list-header">全部碎片 · {{ fragments.length }}</text>
      <view v-if="fragments.length">
        <view
          class="fragment-card"
          v-for="f in fragments"
          :key="f.id"
          @click="openEditor(null, f.id)"
        >
          <view class="fc-head">
            <view class="fc-meta">
              <text class="fc-subtype">{{ subtypeIcon(f.subtype) }} {{ f.subtype || '想法' }}</text>
              <text class="fc-time">{{ relativeTime(f.created_at) }}</text>
            </view>
            <text class="fc-type-badge" :class="f.content_type === 'reference_content' ? 'ref' : 'personal'">
              {{ f.content_type === 'reference_content' ? '参考资料' : '我的内容' }}
            </text>
          </view>
          <text class="fc-content">{{ (f.content || '').slice(0, 120) }}{{ (f.content || '').length > 120 ? '…' : '' }}</text>
          <view class="fc-tags" v-if="f.tags && f.tags.length">
            <text class="tag" v-for="tag in f.tags.slice(0, 3)" :key="tag">#{{ tag }}</text>
          </view>
        </view>
      </view>
      <view v-else class="empty">
        <text>还没有碎片</text>
        <text class="empty-sub">在上方输入框记录今天的第一个想法</text>
      </view>
    </view>
  </scroll-view>
</template>

<script>
import { getVaultStore } from '@/store/vaultStore.js'
import { FILTER_CHIPS, SUBTYPE_ICONS } from '@/services/vaultLogic.js'

const store = getVaultStore()

export default {
  data() {
    return {
      draftText: '',
      captureType: 'personal_content',
      captureTypes: [
        { label: '💡 我的想法', value: 'personal_content' },
        { label: '📖 参考摘录', value: 'reference_content' }
      ],
      filterChips: FILTER_CHIPS,
      activeChip: '全部',
      fragments: [],
      saving: false
    }
  },
  onShow() {
    this.syncState()
  },
  methods: {
    syncState() {
      store.refresh()
      store.updateFilters({ chip: this.activeChip, query: '' })
      this.fragments = store.state.filteredFragments || []
    },
    subtypeIcon(subtype) {
      return SUBTYPE_ICONS[subtype] || '💡'
    },
    relativeTime(ts) {
      if (!ts) return ''
      const diff = Date.now() - ts
      if (diff < 60000) return '刚刚'
      if (diff < 3600000) return `${Math.floor(diff / 60000)} 分钟前`
      if (diff < 86400000) return `${Math.floor(diff / 3600000)} 小时前`
      if (diff < 7 * 86400000) return `${Math.floor(diff / 86400000)} 天前`
      const d = new Date(ts)
      return `${d.getMonth() + 1}/${d.getDate()}`
    },
    setChip(chip) {
      this.activeChip = chip
      store.updateFilters({ chip, query: '' })
      this.fragments = store.state.filteredFragments || []
    },
    quickSave() {
      const text = this.draftText.trim()
      if (!text) return
      this.saving = true
      const result = store.saveFragment({
        content: text,
        content_type: this.captureType,
        subtype: this.captureType === 'reference_content' ? '书摘' : '想法'
      })
      this.saving = false
      if (result.ok) {
        this.draftText = ''
        this.syncState()
        uni.showToast({ title: '已保存', icon: 'success', duration: 1200 })
      } else {
        uni.showToast({ title: result.error, icon: 'none' })
      }
    },
    openEditor(mode, id) {
      let url = '/pages/library/editor'
      if (id) {
        url += `?id=${id}`
      } else if (this.draftText.trim()) {
        // Pass draft text via storage
        try { uni.setStorageSync('editor_draft', { text: this.draftText, content_type: this.captureType }) } catch (_) {}
        url += '?from=draft'
      } else if (mode) {
        url += `?mode=${mode}`
      }
      uni.navigateTo({ url })
    },
    navigate(url) {
      uni.navigateTo({ url })
    }
  }
}
</script>

<style scoped>
.page { background: #fbf9f6; padding: 24rpx; }

/* Header */
.header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 24rpx; }
.header-left {}
.title { display: block; font-size: 48rpx; font-weight: 800; color: #1c1b1f; }
.subtitle { display: block; font-size: 26rpx; color: #49454f; margin-top: 4rpx; }
.header-icons { display: flex; gap: 20rpx; align-items: center; padding-top: 8rpx; }
.icon-btn { font-size: 36rpx; color: #004a77; padding: 8rpx; }

/* Capture card */
.capture-card { background: #ffffff; border-radius: 24rpx; padding: 24rpx; margin-bottom: 24rpx; }
.capture-card-title { display: block; font-size: 28rpx; font-weight: 700; color: #1c1b1f; margin-bottom: 16rpx; }
.type-chips { display: flex; gap: 12rpx; margin-bottom: 16rpx; flex-wrap: wrap; }
.type-chip { padding: 10rpx 20rpx; background: #f5f2ee; border-radius: 48rpx; font-size: 24rpx; color: #49454f; }
.type-chip.active { background: #004a77; color: #ffffff; }

.textarea-wrap { position: relative; background: #f5f2ee; border-radius: 16rpx; padding: 16rpx; margin-bottom: 16rpx; }
.capture-textarea { width: 100%; font-size: 28rpx; color: #1c1b1f; min-height: 100rpx; background: transparent; }
.expand-icon { position: absolute; right: 14rpx; bottom: 14rpx; font-size: 28rpx; color: #49454f; }

.quick-actions { display: flex; gap: 16rpx; margin-bottom: 20rpx; }
.quick-btn { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 6rpx; background: #f5f2ee; border-radius: 16rpx; padding: 16rpx 0; }
.quick-btn-icon { font-size: 36rpx; }
.quick-btn-label { font-size: 22rpx; color: #49454f; }

.save-btn { background: #004a77; color: #ffffff; border-radius: 20rpx; font-size: 28rpx; padding: 18rpx; border: none; }
.save-btn[disabled] { opacity: 0.4; }

/* Filter chips */
.chips-row { margin-bottom: 20rpx; }
.chips-inner { display: flex; gap: 12rpx; padding-right: 24rpx; white-space: nowrap; }
.chip { display: inline-block; padding: 10rpx 22rpx; background: #ffffff; border-radius: 48rpx; font-size: 24rpx; color: #49454f; border: 2rpx solid #e8e4de; white-space: nowrap; }
.chip.active { background: #004a77; color: #ffffff; border-color: #004a77; }

/* List */
.list-section {}
.list-header { display: block; font-size: 26rpx; font-weight: 600; color: #49454f; margin-bottom: 16rpx; }
.fragment-card { background: #ffffff; border-radius: 20rpx; padding: 20rpx 24rpx; margin-bottom: 14rpx; }
.fc-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10rpx; }
.fc-meta { display: flex; align-items: center; gap: 12rpx; }
.fc-subtype { font-size: 24rpx; color: #49454f; font-weight: 600; }
.fc-time { font-size: 22rpx; color: #a39e97; }
.fc-type-badge { font-size: 20rpx; padding: 4rpx 12rpx; border-radius: 20rpx; }
.fc-type-badge.personal { background: #e8f4e8; color: #2d7d2d; }
.fc-type-badge.ref { background: #e8f0fb; color: #1a4fa0; }
.fc-content { display: block; font-size: 28rpx; line-height: 1.65; color: #1c1b1f; margin-bottom: 12rpx; }
.fc-tags { display: flex; gap: 8rpx; flex-wrap: wrap; }
.tag { font-size: 20rpx; color: #004a77; background: #e8f0fb; border-radius: 8rpx; padding: 4rpx 10rpx; }

/* Empty */
.empty { text-align: center; color: #49454f; font-size: 28rpx; padding: 40rpx 0; }
.empty-sub { display: block; font-size: 24rpx; color: #a39e97; margin-top: 8rpx; }
</style>
