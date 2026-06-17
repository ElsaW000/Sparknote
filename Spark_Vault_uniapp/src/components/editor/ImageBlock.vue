<!-- Spark_Vault_uniapp/src/components/editor/ImageBlock.vue -->
<template>
  <view class="image-block" @click="$emit('select')">
    <view class="image-frame">
      <image class="image-preview" :src="block.src" mode="widthFix" />
      <text class="ocr-chip">OCR {{ block.ocrStatus || '待识别' }}</text>
    </view>
    <input
      class="caption"
      :value="block.caption"
      placeholder="添加图片说明"
      @input="handleCaption"
    />
  </view>
</template>

<script>
export default {
  name: 'ImageBlock',
  props: {
    block: {
      type: Object,
      required: true
    }
  },
  emits: ['select', 'update'],
  methods: {
    handleCaption(event) {
      this.$emit('update', { ...this.block, caption: event.detail?.value || '' })
    }
  }
}
</script>

<style scoped>
.image-block {
  margin: 0;
  background: transparent;
}

.image-frame {
  position: relative;
  width: 100%;
  overflow: hidden;
  border-radius: 22rpx;
  background: #eee7dd;
  transition: all 300ms ease-in-out;
  transform-origin: center;
  will-change: transform, box-shadow;
}

.image-frame:hover,
.image-frame:active {
  transform: scale(1.05);
  box-shadow: 0 24rpx 56rpx rgba(31, 41, 51, 0.16);
}

.image-preview {
  display: block;
  width: 100%;
  background: #eee7dd;
}

.ocr-chip {
  position: absolute;
  right: 14rpx;
  top: 14rpx;
  min-height: 38rpx;
  padding: 0 14rpx;
  border-radius: 999rpx;
  background: rgba(255, 253, 248, 0.82);
  color: #6b7280;
  font-size: 20rpx;
  font-weight: 700;
  line-height: 38rpx;
}

.caption {
  width: 100%;
  min-height: 48rpx;
  margin-top: 10rpx;
  color: #7a746b;
  font-size: 22rpx;
  background: transparent;
  border: none;
}
</style>
