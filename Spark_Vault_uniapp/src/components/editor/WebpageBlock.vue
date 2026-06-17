<!-- Spark_Vault_uniapp/src/components/editor/WebpageBlock.vue -->
<template>
  <view class="web-card" @click="$emit('select')">
    <text class="domain">{{ block.domain || 'web link' }}</text>
    <input
      class="web-title"
      :value="block.title"
      placeholder="网页标题"
      @input="updateField('title', $event.detail?.value || '')"
    />
    <textarea
      class="summary"
      :value="block.summary"
      placeholder="网页摘要"
      :auto-height="true"
      @input="updateField('summary', $event.detail?.value || '')"
    />
    <input
      class="url"
      :value="block.url"
      placeholder="https://..."
      @input="updateUrl"
    />
  </view>
</template>

<script>
function getDomain(url = '') {
  try {
    return new URL(url).hostname.replace(/^www\./, '')
  } catch (_) {
    return 'web link'
  }
}

export default {
  name: 'WebpageBlock',
  props: {
    block: {
      type: Object,
      required: true
    }
  },
  emits: ['select', 'update'],
  methods: {
    updateField(field, value) {
      this.$emit('update', { ...this.block, [field]: value })
    },
    updateUrl(event) {
      const url = event.detail?.value || ''
      this.$emit('update', { ...this.block, url, domain: getDomain(url) })
    }
  }
}
</script>

<style scoped>
.web-card {
  margin: 0;
  padding: 22rpx;
  border-radius: 24rpx;
  background: #faf7f1;
  border: 1rpx solid #e8ded2;
  box-shadow: 0 8rpx 24rpx rgba(31, 41, 51, 0.06);
  box-sizing: border-box;
  transition: all 300ms ease-in-out;
  transform-origin: center;
  will-change: transform, box-shadow;
}

.web-card:hover,
.web-card:active {
  transform: scale(1.05);
  box-shadow: 0 24rpx 56rpx rgba(31, 41, 51, 0.16);
}

.domain {
  display: block;
  color: #9a7b37;
  font-family: "Courier New", monospace;
  font-size: 22rpx;
  font-weight: 700;
  letter-spacing: 0.04em;
}

.web-title {
  width: 100%;
  min-height: 62rpx;
  margin-top: 8rpx;
  color: #1f2933;
  font-size: 28rpx;
  font-weight: 700;
  background: transparent;
}

.summary {
  width: 100%;
  min-height: 76rpx;
  color: #4b5563;
  font-size: 24rpx;
  line-height: 1.48;
  background: transparent;
}

.url {
  width: 100%;
  min-height: 46rpx;
  margin-top: 10rpx;
  color: #6b7280;
  font-size: 22rpx;
  background: transparent;
}
</style>
