<!-- Spark_Vault_uniapp/src/components/editor/QuoteBlock.vue -->
<template>
  <view class="quote-wrap">
    <textarea
      :class="['quote', lineHeightClass]"
      :value="block.text"
      placeholder="引用一段原文、对话或想法..."
      :auto-height="true"
      :maxlength="1200"
      @focus="$emit('select')"
      @input="handleInput"
    />
  </view>
</template>

<script>
export default {
  name: 'QuoteBlock',
  props: {
    block: {
      type: Object,
      required: true
    },
    lineHeightMode: {
      type: String,
      default: 'normal'
    }
  },
  emits: ['select', 'update'],
  computed: {
    lineHeightClass() {
      return `line-${this.lineHeightMode || 'normal'}`
    }
  },
  methods: {
    handleInput(event) {
      this.$emit('update', { ...this.block, text: event.detail?.value || '' })
    }
  }
}
</script>

<style scoped>
.quote-wrap {
  margin: 0;
  padding: 12rpx 0 12rpx 24rpx;
  border-left: 4rpx solid #d6a84f;
  border-radius: 0;
  background: rgba(214, 168, 79, 0.06);
  border-top: none;
  border-right: none;
  border-bottom: none;
  box-sizing: border-box;
}

.quote {
  width: 100%;
  min-height: 72rpx;
  color: #4b5563;
  font-size: 30rpx;
  background: transparent;
  border: none;
  outline: none;
}

.line-compact {
  line-height: 1.45;
}

.line-normal {
  line-height: 1.7;
}

.line-loose {
  line-height: 2.05;
}
</style>
