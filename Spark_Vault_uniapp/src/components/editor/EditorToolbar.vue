<!-- Spark_Vault_uniapp/src/components/editor/EditorToolbar.vue -->
<template>
  <view class="toolbar">
    <view
      v-for="item in tools"
      :key="item.type"
      :class="['tool-button', recording && item.type === 'audio' ? 'recording' : '']"
      @click="$emit('insert', item.type)"
    >
      <text class="tool-icon">{{ item.icon }}</text>
      <text class="tool-label">{{ labelFor(item) }}</text>
    </view>
  </view>
</template>

<script>
export default {
  name: 'EditorToolbar',
  props: {
    recording: {
      type: Boolean,
      default: false
    },
    lineHeightLabel: {
      type: String,
      default: '标准行距'
    }
  },
  emits: ['insert'],
  data() {
    return {
      tools: [
        { type: 'heading', icon: 'H1', label: '标题' },
        { type: 'ordered_list', icon: '1.', label: '编号' },
        { type: 'bullet_list', icon: '•', label: '列表' },
        { type: 'line_height', icon: 'LH', label: '行距' },
        { type: 'image', icon: 'IMG', label: '图片' },
        { type: 'audio', icon: 'REC', label: '录音' },
        { type: 'webpage', icon: 'URL', label: '链接' },
        { type: 'file', icon: 'DOC', label: '文件' },
        { type: 'quote', icon: 'QT', label: '引用' },
        { type: 'tag', icon: '#', label: '标签' }
      ]
    }
  },
  methods: {
    labelFor(item) {
      if (this.recording && item.type === 'audio') return '停止'
      if (item.type === 'line_height') return this.lineHeightLabel.replace('行距', '')
      return item.label
    }
  }
}
</script>

<style scoped>
.toolbar {
  position: fixed;
  left: 22rpx;
  right: 22rpx;
  bottom: 24rpx;
  z-index: 12;
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 6rpx;
  height: 112rpx;
  padding: 10rpx 12rpx;
  border: 1rpx solid #e3dbce;
  border-radius: 24rpx;
  background: #fffdf8;
  box-shadow: 0 12rpx 36rpx rgba(31, 41, 51, 0.10);
  box-sizing: border-box;
  overflow-x: auto;
}

.tool-button {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
  min-width: 88rpx;
  height: 90rpx;
  padding: 0 4rpx;
  border-radius: 16rpx;
  background: transparent;
  color: #374151;
}

.tool-button.recording {
  background: #f6f2ec;
  color: #1f2933;
}

.tool-icon,
.tool-label {
  display: block;
  text-align: center;
}

.tool-icon {
  color: #9a7b37;
  font-family: "Courier New", monospace;
  font-size: 24rpx;
  font-weight: 900;
  line-height: 28rpx;
  white-space: nowrap;
}

.tool-label {
  width: 100%;
  margin-top: 8rpx;
  color: #374151;
  font-size: 24rpx;
  font-weight: 700;
  line-height: 28rpx;
  white-space: nowrap;
  word-break: keep-all;
  overflow: visible;
}

.tool-button.recording .tool-icon {
  color: #9a7b37;
}
</style>
