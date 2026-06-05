<!-- pages/library/editor.vue -->
<template>
  <view class="page">
    <!-- Nav Bar -->
    <view class="nav-bar">
      <text class="nav-cancel" @click="cancel">取消</text>
      <text class="nav-title">{{ isEdit ? '编辑碎片' : '新建碎片' }}</text>
      <button class="nav-save" @click="save" :disabled="!form.content.trim()">保存</button>
    </view>

    <!-- Content Type Tabs -->
    <view class="type-tabs">
      <view
        :class="['type-tab', form.content_type === 'personal_content' ? 'active' : '']"
        @click="setContentType('personal_content')"
      >
        <text>💡 我的想法</text>
      </view>
      <view
        :class="['type-tab', form.content_type === 'reference_content' ? 'active' : '']"
        @click="setContentType('reference_content')"
      >
        <text>📖 参考摘录</text>
      </view>
    </view>

    <scroll-view scroll-y class="body">
      <!-- Subtype chips -->
      <scroll-view scroll-x class="chip-scroll">
        <view class="chip-row">
          <text
            v-for="sub in currentSubtypes"
            :key="sub.subtype"
            :class="['chip', form.subtype === sub.subtype ? 'chip-active' : '']"
            @click="form.subtype = sub.subtype"
          >{{ sub.label }}</text>
        </view>
      </scroll-view>

      <!-- Title (for reference content) -->
      <view v-if="form.content_type === 'reference_content'" class="field">
        <input
          class="input-title"
          v-model="form.title"
          placeholder="标题（可选）"
          :maxlength="100"
        />
      </view>

      <!-- Main Content -->
      <view class="field">
        <textarea
          class="textarea-main"
          v-model="form.content"
          :placeholder="contentPlaceholder"
          :maxlength="5000"
          :auto-height="true"
        />
      </view>

      <!-- Source URL (for reference content) -->
      <view v-if="form.content_type === 'reference_content'" class="field source-row">
        <text class="field-icon">🌐</text>
        <input
          class="input-url"
          v-model="form.source_url"
          placeholder="来源链接（可选）"
          :maxlength="500"
        />
      </view>

      <!-- Tags -->
      <view class="field tags-field">
        <scroll-view scroll-x class="chip-scroll">
          <view class="chip-row">
            <text
              v-for="tag in form.tags"
              :key="tag"
              class="tag-chip"
              @click="removeTag(tag)"
            >#{{ tag }} ×</text>
            <view class="tag-add" @click="showTagInput = true">
              <text class="tag-add-icon">＋ 标签</text>
            </view>
          </view>
        </scroll-view>
        <view v-if="showTagInput" class="tag-input-row">
          <input
            class="tag-input"
            v-model="newTag"
            placeholder="输入标签后回车"
            :maxlength="20"
            @confirm="addTag"
          />
          <text class="tag-input-ok" @click="addTag">确定</text>
        </view>
      </view>

      <!-- Delete (edit mode only) -->
      <view v-if="isEdit" class="delete-row" @click="confirmDelete">
        <text class="delete-text">🗑 删除这条碎片</text>
      </view>
    </scroll-view>
  </view>
</template>

<script>
import { getVaultStore } from '../../store/vaultStore.js'
import { SUBTYPE_MAP } from '../../services/vaultLogic.js'

const SUBTYPE_LABELS = {
  '想法': '💡 想法', '日记': '✍ 日记', '录音': '🎙 录音',
  '书摘': '📖 书摘', '网页': '🌐 网页', '文件': '📎 文件'
}

export default {
  name: 'LibraryEditor',
  data() {
    return {
      fragmentId: null,
      form: {
        content: '',
        content_type: 'personal_content',
        subtype: '想法',
        title: '',
        source_url: '',
        tags: []
      },
      showTagInput: false,
      newTag: ''
    }
  },
  computed: {
    isEdit() { return !!this.fragmentId },
    currentSubtypes() {
      return (SUBTYPE_MAP[this.form.content_type] || []).map((s) => ({
        subtype: s,
        label: SUBTYPE_LABELS[s] || s
      }))
    },
    contentPlaceholder() {
      if (this.form.content_type === 'personal_content') {
        return '写下你的想法、日记、观察…'
      }
      return '摘录书中段落、文章内容…'
    }
  },
  onLoad(options) {
    if (options.id) {
      this.fragmentId = Number(options.id)
      this.loadFragment()
    }
  },
  methods: {
    loadFragment() {
      const store = getVaultStore()
      const f = store.getFragmentById(this.fragmentId)
      if (f) {
        this.form = {
          content: f.content || '',
          content_type: f.content_type || 'personal_content',
          subtype: f.subtype || '想法',
          title: f.title || '',
          source_url: f.source_url || '',
          tags: Array.isArray(f.tags) ? [...f.tags] : []
        }
      }
    },
    setContentType(type) {
      this.form.content_type = type
      // Reset subtype to first of new type
      const subs = SUBTYPE_MAP[type] || []
      if (!subs.includes(this.form.subtype)) {
        this.form.subtype = subs[0] || '想法'
      }
    },
    addTag() {
      const tag = this.newTag.trim()
      if (tag && !this.form.tags.includes(tag)) {
        this.form.tags.push(tag)
      }
      this.newTag = ''
      this.showTagInput = false
    },
    removeTag(tag) {
      this.form.tags = this.form.tags.filter((t) => t !== tag)
    },
    save() {
      const store = getVaultStore()
      let result
      if (this.isEdit) {
        result = store.updateFragment(this.fragmentId, { ...this.form })
      } else {
        result = store.saveFragment({ ...this.form })
      }
      if (result.ok) {
        uni.showToast({ title: '已保存', icon: 'success', duration: 1200 })
        setTimeout(() => uni.navigateBack(), 1200)
      } else {
        uni.showToast({ title: result.error || '保存失败', icon: 'none' })
      }
    },
    cancel() {
      uni.navigateBack()
    },
    confirmDelete() {
      uni.showModal({
        title: '删除碎片',
        content: '确定要删除这条碎片吗？此操作不可撤销。',
        confirmText: '删除',
        confirmColor: '#d9534f',
        success: (res) => {
          if (res.confirm) {
            const store = getVaultStore()
            store.deleteFragment(this.fragmentId)
            uni.showToast({ title: '已删除', icon: 'none', duration: 1200 })
            setTimeout(() => uni.navigateBack(), 1200)
          }
        }
      })
    }
  }
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  background: #fbf9f6;
  display: flex;
  flex-direction: column;
}
.nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 60rpx 32rpx 24rpx;
  background: #fff;
  border-bottom: 1rpx solid #f0f0f0;
}
.nav-cancel {
  font-size: 30rpx;
  color: #555;
  padding: 8rpx;
}
.nav-title {
  font-size: 30rpx;
  font-weight: 600;
  color: #1a1a2e;
}
.nav-save {
  background: #004a77;
  color: #fff;
  border-radius: 40rpx;
  font-size: 26rpx;
  padding: 12rpx 32rpx;
  border: none;
}
.nav-save[disabled] { opacity: 0.4; }
.type-tabs {
  display: flex;
  background: #fff;
  border-bottom: 2rpx solid #f0f0f0;
}
.type-tab {
  flex: 1;
  text-align: center;
  padding: 24rpx 0;
  font-size: 28rpx;
  color: #888;
  border-bottom: 4rpx solid transparent;
  box-sizing: border-box;
}
.type-tab.active {
  color: #004a77;
  font-weight: 600;
  border-bottom-color: #004a77;
}
.body {
  flex: 1;
  padding: 24rpx 32rpx 120rpx;
}
.chip-scroll { margin-bottom: 20rpx; }
.chip-row {
  display: flex;
  gap: 16rpx;
  padding-bottom: 4rpx;
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
.field {
  margin-bottom: 24rpx;
}
.input-title {
  width: 100%;
  font-size: 32rpx;
  font-weight: 600;
  color: #1a1a2e;
  padding: 16rpx 0;
  border: none;
  border-bottom: 1rpx solid #e0e0e0;
  background: transparent;
  box-sizing: border-box;
}
.textarea-main {
  width: 100%;
  min-height: 240rpx;
  font-size: 30rpx;
  color: #1a1a2e;
  line-height: 1.8;
  border: none;
  background: transparent;
  padding: 0;
  box-sizing: border-box;
}
.source-row {
  display: flex;
  align-items: center;
  gap: 12rpx;
  padding: 16rpx;
  background: #f8f8f8;
  border-radius: 12rpx;
}
.field-icon { font-size: 32rpx; }
.input-url {
  flex: 1;
  font-size: 26rpx;
  color: #555;
  background: transparent;
  border: none;
}
.tags-field {}
.tag-chip {
  display: inline-block;
  padding: 10rpx 20rpx;
  background: #eaf4ff;
  color: #004a77;
  border-radius: 40rpx;
  font-size: 24rpx;
  white-space: nowrap;
  flex-shrink: 0;
}
.tag-add {
  display: flex;
  align-items: center;
  padding: 10rpx 20rpx;
  background: #f0f0f0;
  border-radius: 40rpx;
  flex-shrink: 0;
}
.tag-add-icon { font-size: 24rpx; color: #888; }
.tag-input-row {
  display: flex;
  align-items: center;
  gap: 16rpx;
  margin-top: 16rpx;
  padding: 16rpx;
  background: #f8f8f8;
  border-radius: 12rpx;
}
.tag-input {
  flex: 1;
  font-size: 28rpx;
  background: transparent;
  border: none;
}
.tag-input-ok {
  font-size: 26rpx;
  color: #004a77;
  font-weight: 500;
}
.delete-row {
  margin-top: 48rpx;
  text-align: center;
  padding: 24rpx 0;
}
.delete-text {
  font-size: 28rpx;
  color: #d9534f;
}
</style>
