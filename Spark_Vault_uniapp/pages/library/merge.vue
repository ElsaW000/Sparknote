<!-- Spark_Vault_uniapp/pages/library/merge.vue -->
<template>
  <view class="page">
    <text class="title">Merge Fragments</text>
    <text class="subtitle">Select two or more fragments and create a synthesized note.</text>

    <view class="panel">
      <text class="row">Selected fragments: {{ selectedIds.length }}</text>
      <input class="input" v-model="title" placeholder="Merged Source Title" />
      <label class="switch-row">
        <checkbox :checked="deleteOriginals" @click="deleteOriginals = !deleteOriginals" />
        <text>Delete originals after merge</text>
      </label>
      <button type="primary" @click="confirmMerge">Confirm Merge</button>
    </view>

    <view class="list" v-if="fragments.length">
      <view class="item" v-for="fragment in fragments" :key="fragment.id" @click="toggle(fragment.id)">
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
  </view>
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
.page { padding: 24rpx; }
.title { font-size: 38rpx; font-weight: 700; display: block; color: #0f172a; }
.subtitle { font-size: 24rpx; color: #64748b; display: block; margin-top: 8rpx; }
.panel { margin-top: 18rpx; background: #f8fafc; border-radius: 12rpx; padding: 16rpx; }
.row { display: block; font-size: 26rpx; margin-bottom: 10rpx; color: #334155; }
.input { background: #fff; border-radius: 10rpx; padding: 12rpx; font-size: 26rpx; box-sizing: border-box; }
.switch-row { margin: 14rpx 0; display: flex; align-items: center; gap: 10rpx; font-size: 24rpx; color: #334155; }
.list { margin-top: 18rpx; display: flex; flex-direction: column; gap: 10rpx; }
.item { display: flex; gap: 12rpx; align-items: flex-start; background: #fff; border: 1px solid #e2e8f0; border-radius: 12rpx; padding: 14rpx; }
.item-body { flex: 1; }
.item-title { display: block; font-size: 28rpx; font-weight: 600; color: #0f172a; }
.item-sub { display: block; font-size: 22rpx; color: #64748b; margin-top: 6rpx; line-height: 1.5; }
.empty { margin-top: 24rpx; font-size: 26rpx; color: #64748b; }
</style>
