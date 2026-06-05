<!-- Spark_Vault_uniapp/pages/library/detail.vue -->
<template>
  <scroll-view class="iv-page detail" scroll-y>
    <text class="iv-title">Fragment Detail</text>
    <text class="iv-subtitle">View and edit a captured fragment.</text>

    <view v-if="loaded" class="iv-card iv-card-padded detail-panel">
      <textarea class="iv-textarea" v-model="form.originalText" placeholder="Fragment text" />
      <input class="iv-input" v-model="form.sourceType" placeholder="Source Type" />
      <input class="iv-input" v-model="form.sourceTitle" placeholder="Source Title" />
      <input class="iv-input" v-model="form.author" placeholder="Author" />
      <input class="iv-input" v-model="form.pageNumber" placeholder="Page Number" />
      <input class="iv-input" v-model="form.sourceUrl" placeholder="Source URL" />
      <input class="iv-input" v-model="form.tagsText" placeholder="Tags" />
      <textarea class="iv-textarea small" v-model="form.userComment" placeholder="Personal Comment" />
      <textarea class="iv-textarea small" v-model="form.aiSummary" placeholder="AI Summary" />
      <label class="switch-row">
        <checkbox :checked="form.favoriteStatus" @click="form.favoriteStatus = !form.favoriteStatus" />
        <text>Favorite</text>
      </label>
    </view>
    <view v-else class="empty">
      <text>Fragment not found.</text>
    </view>

    <view class="actions" v-if="loaded">
      <button class="iv-button" @click="save">Save Changes</button>
      <button class="danger-outline" @click="remove">Delete Fragment</button>
    </view>
  </scroll-view>
</template>

<script>
import { vaultStore } from '../../store/vaultStore.js'

export default {
  data() {
    return {
      id: null,
      loaded: false,
      form: {
        originalText: '',
        sourceType: '',
        sourceTitle: '',
        sourceUrl: '',
        author: '',
        pageNumber: '',
        tagsText: '',
        userComment: '',
        aiSummary: '',
        favoriteStatus: false
      }
    }
  },
  onLoad(query) {
    this.id = Number(query?.id)
    this.loadFragment()
  },
  methods: {
    loadFragment() {
      if (!Number.isInteger(this.id)) {
        this.loaded = false
        return
      }
      const fragment = vaultStore.getFragmentById(this.id)
      if (!fragment) {
        this.loaded = false
        return
      }
      this.loaded = true
      this.form = {
        originalText: fragment.originalText || '',
        sourceType: fragment.sourceType || 'Other',
        sourceTitle: fragment.sourceTitle || '',
        sourceUrl: fragment.sourceUrl || '',
        author: fragment.author || '',
        pageNumber: fragment.pageNumber || '',
        tagsText: Array.isArray(fragment.tags) ? fragment.tags.join(', ') : '',
        userComment: fragment.userComment || '',
        aiSummary: fragment.aiSummary || '',
        favoriteStatus: Boolean(fragment.favoriteStatus)
      }
    },
    save() {
      const result = vaultStore.updateFragment(this.id, this.form)
      if (!result.ok) {
        uni.showToast({ title: result.error, icon: 'none' })
        return
      }
      uni.showToast({ title: 'Changes saved', icon: 'success' })
      uni.navigateBack()
    },
    remove() {
      const result = vaultStore.deleteFragment(this.id)
      if (!result.ok) {
        uni.showToast({ title: result.error, icon: 'none' })
        return
      }
      uni.showToast({ title: 'Fragment deleted', icon: 'success' })
      uni.navigateBack()
    }
  }
}
</script>

<style scoped>
.detail { padding-bottom: 56rpx; }
.detail-panel { margin-top: 24rpx; display: flex; flex-direction: column; gap: 16rpx; }
.small { min-height: 132rpx; }
.switch-row { display: flex; align-items: center; gap: 12rpx; font-size: 24rpx; color: #49454f; }
.actions { margin-top: 20rpx; display: flex; flex-direction: column; gap: 14rpx; }
.danger-outline { min-height: 88rpx; border-radius: 24rpx; color: #ba1a1a; background: #fff; border: 1rpx solid #ba1a1a; font-size: 25rpx; font-weight: 800; line-height: 88rpx; }
.empty { margin-top: 24rpx; font-size: 26rpx; color: #49454f; }
</style>
