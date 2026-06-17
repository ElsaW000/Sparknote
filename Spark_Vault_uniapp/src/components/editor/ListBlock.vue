<!-- Spark_Vault_uniapp/src/components/editor/ListBlock.vue -->
<template>
  <view :class="['list-block', lineHeightClass]">
    <view
      v-for="(item, index) in normalizedItems"
      :key="index"
      class="list-row"
    >
      <text class="list-marker">{{ markerFor(index) }}</text>
      <input
        class="list-input"
        :value="item"
        :focus="focused && index === normalizedItems.length - 1"
        :placeholder="placeholderFor(index)"
        :maxlength="240"
        @focus="$emit('select')"
        @input="updateItem(index, $event)"
        @confirm="insertAfter(index)"
      />
    </view>
  </view>
</template>

<script>
export default {
  name: 'ListBlock',
  props: {
    block: {
      type: Object,
      required: true
    },
    focused: {
      type: Boolean,
      default: false
    },
    lineHeightMode: {
      type: String,
      default: 'normal'
    }
  },
  emits: ['select', 'update'],
  computed: {
    normalizedItems() {
      const items = Array.isArray(this.block.items) ? this.block.items : []
      return items.length ? items : ['']
    },
    lineHeightClass() {
      return `line-${this.lineHeightMode || 'normal'}`
    }
  },
  methods: {
    markerFor(index) {
      return this.block.type === 'ordered_list' ? `${index + 1}.` : '•'
    },
    placeholderFor(index) {
      return index === 0 ? '写下第一条...' : '继续添加...'
    },
    updateItem(index, event) {
      const items = [...this.normalizedItems]
      items[index] = event.detail?.value || ''
      this.$emit('update', { ...this.block, items })
    },
    insertAfter(index) {
      const items = [...this.normalizedItems]
      items.splice(index + 1, 0, '')
      this.$emit('update', { ...this.block, items })
    }
  }
}
</script>

<style scoped>
.list-block {
  width: 100%;
  padding: 4rpx 0;
  box-sizing: border-box;
}

.list-row {
  display: flex;
  align-items: flex-start;
  gap: 14rpx;
  min-height: 56rpx;
}

.list-marker {
  width: 42rpx;
  flex-shrink: 0;
  color: #9a7b37;
  font-size: 28rpx;
  font-weight: 800;
  line-height: 1.7;
  text-align: right;
}

.list-input {
  flex: 1;
  min-height: 54rpx;
  padding: 0;
  color: #374151;
  font-size: 30rpx;
  background: transparent;
  border: none;
  box-sizing: border-box;
}

.line-compact .list-row {
  margin-bottom: 2rpx;
}

.line-normal .list-row {
  margin-bottom: 10rpx;
}

.line-loose .list-row {
  margin-bottom: 20rpx;
}
</style>
