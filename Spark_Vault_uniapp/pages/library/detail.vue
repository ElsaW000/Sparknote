<!-- Spark_Vault_uniapp/pages/library/detail.vue -->
<template>
  <view class="page">
    <text class="title">Fragment Detail</text>
    <text class="subtitle">View and edit a captured fragment.</text>

    <view v-if="loaded" class="panel">
      <textarea class="textarea" v-model="form.originalText" placeholder="Fragment text" />
      <input class="input" v-model="form.sourceType" placeholder="Source Type" />
      <input class="input" v-model="form.sourceTitle" placeholder="Source Title" />
      <input class="input" v-model="form.author" placeholder="Author" />
      <input class="input" v-model="form.pageNumber" placeholder="Page Number" />
      <input class="input" v-model="form.sourceUrl" placeholder="Source URL" />
      <input class="input" v-model="form.tagsText" placeholder="Tags" />
      <textarea class="textarea small" v-model="form.userComment" placeholder="Personal Comment" />
      <textarea class="textarea small" v-model="form.aiSummary" placeholder="AI Summary" />
      <label class="switch-row">
        <checkbox :checked="form.favoriteStatus" @click="form.favoriteStatus = !form.favoriteStatus" />
        <text>Favorite</text>
      </label>
    </view>
    <view v-else class="empty">
      <text>Fragment not found.</text>
    </view>

    <view class="actions" v-if="loaded">
      <button type="primary" @click="save">Save Changes</button>
      <button @click="remove">Delete Fragment</button>
    </view>
  </view>
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
.page { padding: 24rpx; }
.title { font-size: 38rpx; font-weight: 700; display: block; color: #0f172a; }
.subtitle { font-size: 24rpx; color: #64748b; display: block; margin-top: 8rpx; }
.panel { margin-top: 16rpx; display: flex; flex-direction: column; gap: 10rpx; }
.textarea { min-height: 180rpx; background: #f8fafc; border-radius: 10rpx; padding: 12rpx; box-sizing: border-box; font-size: 26rpx; width: 100%; }
.textarea.small { min-height: 120rpx; }
.input { background: #f8fafc; border-radius: 10rpx; padding: 12rpx; font-size: 26rpx; box-sizing: border-box; }
.switch-row { display: flex; align-items: center; gap: 10rpx; font-size: 24rpx; color: #334155; }
.actions { margin-top: 16rpx; display: flex; flex-direction: column; gap: 10rpx; }
.empty { margin-top: 24rpx; font-size: 26rpx; color: #64748b; }
</style>
