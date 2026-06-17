<!-- Spark_Vault_uniapp/src/components/editor/ParagraphBlock.vue -->
<template>
  <textarea
    :class="['paragraph', lineHeightClass]"
    :value="block.text"
    :focus="focused"
    :placeholder="placeholder"
    placeholder-style="color: #A8A29E;"
    :auto-height="true"
    :maxlength="2000"
    @focus="$emit('select')"
    @input="handleInput"
    @confirm="$emit('split')"
    @keydown.enter.prevent="$emit('split')"
  />
</template>

<script>
export default {
  name: 'ParagraphBlock',
  props: {
    block: {
      type: Object,
      required: true
    },
    focused: {
      type: Boolean,
      default: false
    },
    placeholder: {
      type: String,
      default: '继续记录…'
    },
    lineHeightMode: {
      type: String,
      default: 'normal'
    }
  },
  emits: ['select', 'update', 'split'],
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
.paragraph {
  width: 100%;
  min-height: 48rpx;
  margin: 0;
  padding: 6rpx 0;
  color: #374151;
  font-size: 30rpx;
  background: transparent;
  border: none;
  outline: none;
  border-radius: 0;
  box-shadow: none;
  box-sizing: border-box;
}

.line-compact {
  line-height: 1.45;
}

.line-normal {
  line-height: 1.75;
}

.line-loose {
  line-height: 2.05;
}
</style>
