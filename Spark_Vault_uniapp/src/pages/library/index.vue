<!-- pages/library/index.vue -->
<template>
  <scroll-view scroll-y class="page">
    <!-- Header -->
    <view class="header">
      <view>
        <text class="title">Library</text>
        <text class="subtitle">我的知识碎片</text>
      </view>
      <view class="header-actions">
        <text class="icon-btn" @click="toggleSearch">⌕</text>
        <text class="icon-btn" @click="goEditor">＋</text>
      </view>
    </view>

    <!-- Quick Entry Card -->
    <view class="card quick-entry">
      <view class="entry-label">＋ 添加碎片</view>
      <view class="entry-row">
        <textarea
          class="entry-textarea"
          v-model="quickText"
          placeholder="随手记录一个想法、金句、观察…"
          :maxlength="500"
          :auto-height="true"
        />
        <text class="fullscreen-btn" @click="goEditor">⤢</text>
      </view>
      <text class="entry-hint">点击 ⤢ 进入全屏编辑（支持图片 / 录音 / 链接）</text>
      <!-- Subtype chips -->
      <scroll-view scroll-x class="chip-scroll">
        <view class="chip-row">
          <text
            v-for="chip in subtypeChips"
            :key="chip.label"
            :class="['chip', quickSubtype === chip.subtype ? 'chip-active' : '']"
            @click="quickSubtype = chip.subtype"
          >{{ chip.label }}</text>
        </view>
      </scroll-view>
      <button class="btn-save" @click="saveQuick" :disabled="!quickText.trim()">保存到 Library</button>
    </view>

    <!-- Filter Chips -->
    <scroll-view scroll-x class="chip-scroll">
      <view class="chip-row">
        <text
          v-for="chip in filterChips"
          :key="chip"
          :class="['chip', activeChip === chip ? 'chip-active' : '']"
          @click="selectChip(chip)"
        >{{ chip }}</text>
      </view>
    </scroll-view>

    <!-- Fragment Count -->
    <text class="list-header">全部碎片 · {{ filteredFragments.length }}</text>

    <!-- Fragment List -->
    <view v-if="filteredFragments.length === 0" class="empty-state">
      <text class="empty-text">还没有碎片。点击上方输入框开始记录。</text>
    </view>

    <view class="fragment-list">
      <view
        v-for="f in filteredFragments"
        :key="f.id"
        class="fragment-card card"
        @click="goEditor(f.id)"
      >
        <view class="fragment-top">
          <text class="fragment-type">{{ subtypeIcon(f.subtype) }} {{ f.subtype }}</text>
          <text class="fragment-time">{{ timeAgo(f.created_at) }}</text>
        </view>
        <text class="fragment-content">{{ f.content }}</text>
        <text v-if="f.tags && f.tags.length" class="fragment-tags">
          {{ f.tags.map(t => '#' + t).join(' ') }}
        </text>
        <text v-if="f.title" class="fragment-source">{{ f.title }}</text>
      </view>
    </view>
  </scroll-view>
</template>

<script>
import { getVaultStore } from '../../store/vaultStore.js'
import { SUBTYPE_ICONS, FILTER_CHIPS } from '../../services/vaultLogic.js'

const SUBTYPE_CHIPS = [
  { label: '💡 想法', subtype: '想法' },
  { label: '📖 书摘', subtype: '书摘' },
  { label: '🌐 网页', subtype: '网页' },
  { label: '其他', subtype: '日记' }
]

export default {
  name: 'LibraryPage',
  data() {
    return {
      quickText: '',
      quickSubtype: '想法',
      activeChip: '全部',
      filteredFragments: [],
      subtypeChips: SUBTYPE_CHIPS,
      filterChips: FILTER_CHIPS
    }
  },
  onShow() {
    this.loadData()
  },
  methods: {
    loadData() {
      const store = getVaultStore()
      store.refresh()
      this.filteredFragments = store.state.filteredFragments.length > 0 || this.activeChip !== '全部'
        ? store.state.filteredFragments
        : store.state.fragments
    },
    selectChip(chip) {
      this.activeChip = chip
      const store = getVaultStore()
      store.updateFilters({ chip })
      this.filteredFragments = store.state.filteredFragments
    },
    saveQuick() {
      const text = this.quickText.trim()
      if (!text) return
      const store = getVaultStore()
      const result = store.saveFragment({
        content: text,
        content_type: ['书摘', '网页', '文件'].includes(this.quickSubtype) ? 'reference_content' : 'personal_content',
        subtype: this.quickSubtype
      })
      if (result.ok) {
        this.quickText = ''
        this.quickSubtype = '想法'
        this.loadData()
        uni.showToast({ title: '已保存', icon: 'success', duration: 1500 })
      } else {
        uni.showToast({ title: result.error || '保存失败', icon: 'none' })
      }
    },
    goEditor(id) {
      const url = id ? `/pages/library/editor?id=${id}` : '/pages/library/editor'
      uni.navigateTo({ url })
    },
    toggleSearch() {
      // TODO: show search input
    },
    subtypeIcon(subtype) {
      return SUBTYPE_ICONS[subtype] || '📄'
    },
    timeAgo(ts) {
      if (!ts) return ''
      const diff = Date.now() - ts
      const mins = Math.floor(diff / 60000)
      const hours = Math.floor(diff / 3600000)
      const days = Math.floor(diff / 86400000)
      if (mins < 1) return '刚刚'
      if (mins < 60) return `${mins}分钟前`
      if (hours < 24) return `${hours}小时前`
      if (days === 1) return '昨天'
      if (days < 7) return `${days}天前`
      const d = new Date(ts)
      return `${d.getMonth() + 1}/${d.getDate()}`
    }
  }
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  background: #fbf9f6;
  padding: 48rpx 32rpx 120rpx;
  box-sizing: border-box;
}
.header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 32rpx;
  padding-top: 20rpx;
}
.title {
  display: block;
  font-size: 52rpx;
  font-weight: 700;
  color: #1a1a2e;
}
.subtitle {
  display: block;
  font-size: 26rpx;
  color: #888;
  margin-top: 4rpx;
}
.header-actions {
  display: flex;
  gap: 16rpx;
  align-items: center;
  padding-top: 8rpx;
}
.icon-btn {
  font-size: 40rpx;
  color: #004a77;
  padding: 8rpx;
}
.card {
  background: #fff;
  border-radius: 20rpx;
  padding: 32rpx;
  margin-bottom: 24rpx;
  box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06);
}
.quick-entry {}
.entry-label {
  font-size: 28rpx;
  font-weight: 600;
  color: #1a1a2e;
  margin-bottom: 16rpx;
}
.entry-row {
  display: flex;
  align-items: flex-start;
  gap: 16rpx;
}
.entry-textarea {
  flex: 1;
  font-size: 28rpx;
  color: #333;
  min-height: 80rpx;
  padding: 0;
  background: transparent;
}
.fullscreen-btn {
  font-size: 36rpx;
  color: #004a77;
  padding: 4rpx 8rpx;
}
.entry-hint {
  display: block;
  font-size: 22rpx;
  color: #aaa;
  margin: 8rpx 0 16rpx;
}
.chip-scroll {
  margin-bottom: 16rpx;
}
.chip-row {
  display: flex;
  flex-wrap: nowrap;
  gap: 16rpx;
  padding-right: 16rpx;
}
.chip {
  display: inline-block;
  padding: 12rpx 24rpx;
  background: #f0f0f0;
  border-radius: 40rpx;
  font-size: 26rpx;
  color: #555;
  white-space: nowrap;
  flex-shrink: 0;
}
.chip-active {
  background: #004a77;
  color: #fff;
}
.btn-save {
  width: 100%;
  background: #004a77;
  color: #fff;
  border-radius: 12rpx;
  font-size: 28rpx;
  padding: 20rpx 0;
  border: none;
  margin-top: 8rpx;
}
.btn-save[disabled] {
  opacity: 0.4;
}
.list-header {
  display: block;
  font-size: 26rpx;
  color: #888;
  margin-bottom: 16rpx;
}
.empty-state {
  text-align: center;
  padding: 60rpx 0;
}
.empty-text {
  font-size: 26rpx;
  color: #aaa;
}
.fragment-card {
  margin-bottom: 16rpx;
}
.fragment-top {
  display: flex;
  justify-content: space-between;
  margin-bottom: 12rpx;
}
.fragment-type {
  font-size: 24rpx;
  color: #004a77;
  font-weight: 500;
}
.fragment-time {
  font-size: 22rpx;
  color: #aaa;
}
.fragment-content {
  display: block;
  font-size: 28rpx;
  color: #1a1a2e;
  line-height: 1.6;
  margin-bottom: 8rpx;
  /* 2-line clamp */
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}
.fragment-tags {
  display: block;
  font-size: 22rpx;
  color: #004a77;
  margin-top: 4rpx;
}
.fragment-source {
  display: block;
  font-size: 22rpx;
  color: #888;
  margin-top: 4rpx;
}
</style>