<!-- Spark_Vault_uniapp/src/components/editor/FileBlock.vue -->
<template>
  <view class="file-card" @click="$emit('select')">
    <view class="file-icon">{{ block.fileType || 'FILE' }}</view>
    <view class="file-main">
      <input
        class="file-name"
        :value="block.name"
        placeholder="文件名"
        @input="updateField('name', $event.detail?.value || '')"
      />
      <text class="file-meta">{{ readableSize }} · {{ block.parseStatus || '等待解析' }}</text>
    </view>
  </view>
</template>

<script>
export default {
  name: 'FileBlock',
  props: {
    block: {
      type: Object,
      required: true
    }
  },
  emits: ['select', 'update'],
  computed: {
    readableSize() {
      const size = Number(this.block.size || 0)
      if (!size) return '未知大小'
      if (size < 1024) return `${size} B`
      if (size < 1024 * 1024) return `${Math.round(size / 1024)} KB`
      return `${(size / 1024 / 1024).toFixed(1)} MB`
    }
  },
  methods: {
    updateField(field, value) {
      this.$emit('update', { ...this.block, [field]: value })
    }
  }
}
</script>

<style scoped>
.file-card {
  display: flex;
  align-items: center;
  gap: 18rpx;
  margin: 0;
  padding: 20rpx;
  border: 1rpx solid #e8ded2;
  border-radius: 24rpx;
  background: #faf7f1;
  box-shadow: 0 8rpx 24rpx rgba(31, 41, 51, 0.06);
  box-sizing: border-box;
  transition: all 300ms ease-in-out;
  transform-origin: center;
  will-change: transform, box-shadow;
}

.file-card:hover,
.file-card:active {
  transform: scale(1.05);
  box-shadow: 0 24rpx 56rpx rgba(31, 41, 51, 0.16);
}

.file-icon {
  width: 88rpx;
  height: 68rpx;
  border-radius: 18rpx;
  background: #f6f2ec;
  border: 1rpx solid #e8ded2;
  color: #9a7b37;
  font-family: "Courier New", monospace;
  font-size: 20rpx;
  font-weight: 900;
  line-height: 68rpx;
  text-align: center;
  flex-shrink: 0;
}

.file-main {
  flex: 1;
  min-width: 0;
}

.file-name {
  width: 100%;
  min-height: 46rpx;
  color: #1f2933;
  font-size: 28rpx;
  font-weight: 700;
  background: transparent;
}

.file-meta {
  display: block;
  margin-top: 4rpx;
  color: #6b7280;
  font-size: 22rpx;
}
</style>
