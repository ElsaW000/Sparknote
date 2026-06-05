<!-- Spark_Vault_uniapp/pages/library/merge.vue -->
<template>
  <scroll-view class="iv-page merge" scroll-y>
    <text class="iv-title">Merge Fragments</text>
    <text class="iv-subtitle">Select two or more fragments and create a synthesized note.</text>

    <view class="iv-card iv-card-padded merge-panel">
      <text class="row">Selected fragments: {{ selectedIds.length }}</text>
      <input class="iv-input" v-model="title" placeholder="Merged Source Title" />
      <label class="switch-row">
        <checkbox :checked="deleteOriginals" @click="deleteOriginals = !deleteOriginals" />
        <text>Delete originals after merge</text>
      </label>
      <button class="iv-button" @click="confirmMerge">Confirm Merge</button>
    </view>

    <view class="list" v-if="fragments.length">
      <view class="iv-card item" v-for="fragment in fragments" :key="fragment.id" @click="toggle(fragment.id)">
        <checkbox :checked="selectedIds.includes(fragment.id)" />
        <view class="item-body">
          <text class="item-title">{{ fragment.sourceTitle || fragment.sourceType || 'Untitled' }}</text>
          <text class="item-sub">{{ fragment.originalText }}</text>
        </view>
      </view>
    </view>
    <view class="empty" v-else>
      <text>No fragments available to merge.</text>
    </view>
  </scroll-view>
</template>

<script>
import { vaultStore } from '../../store/vaultStore.js'

export default {
  data() {
    return {
      fragments: [],
      selectedIds: [],
      title: '',
      deleteOriginals: false
    }
  },
  onShow() {
    vaultStore.refresh()
    this.fragments = vaultStore.state.fragments
  },
  methods: {
    toggle(id) {
      const numericId = Number(id)
      if (!Number.isInteger(numericId)) return
      this.selectedIds = this.selectedIds.includes(numericId)
        ? this.selectedIds.filter((item) => item !== numericId)
        : [...this.selectedIds, numericId]
    },
    confirmMerge() {
      const result = vaultStore.mergeSelected(this.selectedIds, this.title, this.deleteOriginals)
      if (!result.ok) {
        uni.showToast({ title: result.error, icon: 'none' })
        return
      }
      uni.showToast({ title: 'Fragments merged', icon: 'success' })
      uni.navigateBack()
    }
  }
}
</script>

<style scoped>
.merge { padding-bottom: 56rpx; }
.merge-panel { margin-top: 24rpx; }
.row { display: block; font-size: 26rpx; margin-bottom: 14rpx; color: #004a77; font-weight: 800; }
.switch-row { margin: 18rpx 0; display: flex; align-items: center; gap: 12rpx; font-size: 24rpx; color: #49454f; }
.list { margin-top: 18rpx; display: flex; flex-direction: column; gap: 10rpx; }
.item { display: flex; gap: 12rpx; align-items: flex-start; border-radius: 20rpx; padding: 18rpx; }
.item-body { flex: 1; }
.item-title { display: block; font-size: 28rpx; font-weight: 800; color: #004a77; }
.item-sub { display: block; font-size: 22rpx; color: #49454f; margin-top: 6rpx; line-height: 1.5; }
.empty { margin-top: 24rpx; font-size: 26rpx; color: #49454f; }
</style>
