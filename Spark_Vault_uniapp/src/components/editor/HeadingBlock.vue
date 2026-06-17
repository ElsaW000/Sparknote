<!-- Spark_Vault_uniapp/src/components/editor/HeadingBlock.vue -->
<template>
  <input
    class="heading"
    :value="block.text"
    placeholder="小标题"
    :maxlength="80"
    @focus="$emit('select')"
    @input="handleInput"
  />
</template>

<script>
export default {
  name: 'HeadingBlock',
  props: {
    block: {
      type: Object,
      required: true
    }
  },
  emits: ['select', 'update'],
  methods: {
    handleInput(event) {
      this.$emit('update', { ...this.block, text: event.detail?.value || '' })
    }
  }
}
</script>

<style scoped>
.heading {
  width: 100%;
  min-height: 76rpx;
  padding: 8rpx 0;
  color: #1f2933;
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
  font-size: 44rpx;
  font-weight: 700;
  background: transparent;
  border: none;
  outline: none;
  border-radius: 0;
  box-shadow: none;
  box-sizing: border-box;
}
</style>
