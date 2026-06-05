<!-- pages/library/browser.vue — S3 碎片全量浏览页 -->
<template>
  <view class="page">
    <!-- Search bar -->
    <view class="search-bar">
      <input
        class="search-input"
        v-model="query"
        placeholder="搜索碎片内容、标签…"
        @input="applyFilters"
      />
      <text v-if="query" class="search-clear" @click="clearSearch">✕</text>
    </view>

    <!-- Big category pills -->
    <scroll-view class="pills-row" scroll-x>
      <view class="pills-inner">
        <text
          v-for="pill in categoryPills"
          :key="pill.value"
          :class="['pill', category === pill.value ? 'active' : '']"
          @click="setCategory(pill.value)"
        >{{ pill.label }}</text>
      </view>
    </scroll-view>

    <!-- Sub-type chips -->
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

    <!-- Sort row -->
    <view class="sort-row">
      <text class="count-label">共 {{ fragments.length }} 条</text>
      <view class="sort-btns">
        <text
          :class="['sort-btn', sortBy === 'time' ? 'active' : '']"
          @click="setSortBy('time')"
        >最近添加</text>
        <text
          :class="['sort-btn', sortBy === 'tag' ? 'active' : '']"
          @click="setSortBy('tag')"
        >按标签</text>
      </view>
    </view>

    <!-- List -->
    <scroll-view class="list" scroll-y>
      <view v-if="fragments.length">
        <view
          class="fragment-card"
          v-for="f in fragments"
          :key="f.id"
          @click="openEditor(f.id)"
        >
          <view class="fc-head">
            <text class="fc-subtype">{{ subtypeIcon(f.subtype) }} {{ f.subtype || '想法' }}</text>
            <text class="fc-time">{{ relativeTime(f.created_at) }}</text>
          </view>
          <text class="fc-content">{{ (f.content || '').slice(0, 150) }}{{ (f.content || '').length > 150 ? '…' : '' }}</text>
          <view class="fc-tags" v-if="f.tags && f.tags.length">
            <text class="tag" v-for="tag in f.tags.slice(0, 4)" :key="tag">#{{ tag }}</text>
          </view>
        </view>
      </view>
      <view v-else class="empty">
        <text class="empty-text">{{ query ? '没有匹配的碎片' : '还没有碎片' }}</text>
      </view>
    </scroll-view>

    <!-- FAB -->
    <view class="fab" @click="openEditor()">＋</view>
  </view>
</template>

<script>
import { getVaultStore } from '@/store/vaultStore.js'
import { FILTER_CHIPS, SUBTYPE_ICONS } from '@/services/vaultLogic.js'

const store = getVaultStore()

export default {
  data() {
    return {
      query: '',
      category: 'all',
      activeChip: '全部',
      sortBy: 'time',
      fragments: [],
      categoryPills: [
        { label: '全部', value: 'all' },
        { label: '💡 我的想法', value: 'personal_content' },
        { label: '📖 参考资料', value: 'reference_content' }
      ],
      filterChips: FILTER_CHIPS
    }
  },
  onShow() {
    this.applyFilters()
  },
  methods: {
    applyFilters() {
      store.refresh()
      let list = store.state.fragments || []

      // Category filter
      if (this.category !== 'all') {
        list = list.filter((f) => f.content_type === this.category)
      }

      // Chip filter
      const chip = this.activeChip
      if (chip && chip !== '全部') {
        const chipSubtype = chip.replace(/^[\p{Emoji}\s]+/u, '').trim()
        list = list.filter((f) => f.subtype === chipSubtype)
      }

      // Query filter
      const q = this.query.toLowerCase().trim()
      if (q) {
        list = list.filter((f) => {
          const hay = [f.content, f.title, (f.tags || []).join(' ')].join(' ').toLowerCase()
          return hay.includes(q)
        })
      }

      // Sort
      list = [...list].sort((a, b) => (b.created_at || 0) - (a.created_at || 0))

      this.fragments = list
    },
    setCategory(val) {
      this.category = val
      this.activeChip = '全部'
      this.applyFilters()
    },
    setChip(chip) {
      this.activeChip = chip
      this.applyFilters()
    },
    setSortBy(val) {
      this.sortBy = val
      this.applyFilters()
    },
    clearSearch() {
      this.query = ''
      this.applyFilters()
    },
    subtypeIcon(subtype) {
      return SUBTYPE_ICONS[subtype] || '💡'
    },
    relativeTime(ts) {
      if (!ts) return ''
      const diff = Date.now() - ts
      if (diff < 60000) return '刚刚'
      if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
      if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`
      if (diff < 7 * 86400000) return `${Math.floor(diff / 86400000)}天前`
      const d = new Date(ts)
      return `${d.getMonth() + 1}/${d.getDate()}`
    },
    openEditor(id) {
      const url = id ? `/pages/library/editor?id=${id}` : '/pages/library/editor'
      uni.navigateTo({ url })
    }
  }
}
</script>

<style scoped>
.page { display: flex; flex-direction: column; height: 100vh; background: #f5f2ee; padding: 16rpx 24rpx 0; }

.search-bar { display: flex; align-items: center; background: #ffffff; border-radius: 20rpx; padding: 14rpx 20rpx; margin-bottom: 16rpx; }
.search-input { flex: 1; font-size: 28rpx; color: #1c1b1f; background: transparent; }
.search-clear { font-size: 28rpx; color: #49454f; padding: 4rpx 8rpx; }

.pills-row { margin-bottom: 12rpx; }
.pills-inner { display: flex; gap: 12rpx; padding-right: 24rpx; }
.pill { display: inline-block; padding: 12rpx 24rpx; background: #ffffff; border-radius: 48rpx; font-size: 26rpx; color: #49454f; white-space: nowrap; }
.pill.active { background: #004a77; color: #ffffff; }

.chips-row { margin-bottom: 14rpx; }
.chips-inner { display: flex; gap: 10rpx; padding-right: 24rpx; }
.chip { display: inline-block; padding: 8rpx 18rpx; background: rgba(255,255,255,0.6); border-radius: 48rpx; font-size: 22rpx; color: #49454f; white-space: nowrap; }
.chip.active { background: #1c1b1f; color: #ffffff; }

.sort-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14rpx; }
.count-label { font-size: 24rpx; color: #49454f; }
.sort-btns { display: flex; gap: 12rpx; }
.sort-btn { font-size: 24rpx; color: #49454f; padding: 6rpx 14rpx; border-radius: 20rpx; background: rgba(255,255,255,0.6); }
.sort-btn.active { background: #ffffff; color: #004a77; font-weight: 700; }

.list { flex: 1; }
.fragment-card { background: #ffffff; border-radius: 20rpx; padding: 20rpx 24rpx; margin-bottom: 14rpx; }
.fc-head { display: flex; justify-content: space-between; margin-bottom: 10rpx; }
.fc-subtype { font-size: 24rpx; color: #49454f; font-weight: 600; }
.fc-time { font-size: 22rpx; color: #a39e97; }
.fc-content { display: block; font-size: 28rpx; line-height: 1.65; color: #1c1b1f; margin-bottom: 12rpx; }
.fc-tags { display: flex; gap: 8rpx; flex-wrap: wrap; }
.tag { font-size: 20rpx; color: #004a77; background: #e8f0fb; border-radius: 8rpx; padding: 4rpx 10rpx; }
.empty { padding: 60rpx; text-align: center; }
.empty-text { font-size: 28rpx; color: #a39e97; }

.fab { position: fixed; right: 40rpx; bottom: 120rpx; width: 100rpx; height: 100rpx; background: #004a77; border-radius: 50rpx; color: #ffffff; font-size: 52rpx; display: flex; align-items: center; justify-content: center; box-shadow: 0 4rpx 20rpx rgba(0,74,119,0.3); }
</style>
