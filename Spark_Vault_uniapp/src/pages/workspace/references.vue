<!-- Spark_Vault_uniapp/pages/workspace/references.vue -->
<template>
  <scroll-view class="iv-page references-page" scroll-y>
    <text class="iv-title">Workspace References</text>
    <text class="iv-subtitle">Fragments cited by the latest synthesis.</text>

    <view class="list" v-if="references.length">
      <view class="iv-card item" v-for="fragment in references" :key="fragment.id" @click="openDetail(fragment.id)">
        <text class="item-title">[{{ fragment.sourceType }}] {{ fragment.sourceTitle || 'Untitled' }}</text>
        <text class="item-sub">{{ fragment.originalText }}</text>
      </view>
    </view>
    <view class="empty" v-else>
      <text>No references were linked to this report.</text>
    </view>
  </scroll-view>
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
.references-page { padding-bottom: 56rpx; }
.list { margin-top: 18rpx; display: flex; flex-direction: column; gap: 10rpx; }
.item { border-radius: 20rpx; padding: 20rpx; }
.item-title { display: block; font-size: 28rpx; font-weight: 800; color: #004a77; }
.item-sub { display: block; font-size: 22rpx; color: #49454f; margin-top: 6rpx; line-height: 1.5; }
.empty { margin-top: 24rpx; font-size: 26rpx; color: #49454f; }
</style>
