<!-- Spark_Vault_uniapp/pages/workspace/references.vue -->
<template>
  <view class="page">
    <text class="title">Workspace References</text>
    <text class="subtitle">Fragments cited by the latest synthesis.</text>

    <view class="list" v-if="references.length">
      <view class="item" v-for="fragment in references" :key="fragment.id" @click="openDetail(fragment.id)">
        <text class="item-title">[{{ fragment.sourceType }}] {{ fragment.sourceTitle || 'Untitled' }}</text>
        <text class="item-sub">{{ fragment.originalText }}</text>
      </view>
    </view>
    <view class="empty" v-else>
      <text>No references were linked to this report.</text>
    </view>
  </view>
</template>

<script>
import { vaultStore } from '../../store/vaultStore.js'

export default {
  data() {
    return {
      references: []
    }
  },
  onLoad(query) {
    const ids = String(query?.ids || '')
      .split(',')
      .map((id) => Number(id))
      .filter(Number.isInteger)
    this.references = ids.map((id) => vaultStore.getFragmentById(id)).filter(Boolean)
  },
  methods: {
    openDetail(id) {
      if (!Number.isInteger(Number(id))) return
      uni.navigateTo({ url: `/pages/library/detail?id=${id}` })
    }
  }
}
</script>

<style scoped>
.page { padding: 24rpx; }
.title { font-size: 38rpx; font-weight: 700; display: block; color: #0f172a; }
.subtitle { font-size: 24rpx; color: #64748b; display: block; margin-top: 8rpx; }
.list { margin-top: 18rpx; display: flex; flex-direction: column; gap: 10rpx; }
.item { background: #f8fafc; border-radius: 12rpx; padding: 16rpx; }
.item-title { display: block; font-size: 28rpx; font-weight: 600; color: #0f172a; }
.item-sub { display: block; font-size: 22rpx; color: #64748b; margin-top: 6rpx; line-height: 1.5; }
.empty { margin-top: 24rpx; font-size: 26rpx; color: #64748b; }
</style>
