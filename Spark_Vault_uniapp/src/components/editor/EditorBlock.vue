<!-- Spark_Vault_uniapp/src/components/editor/EditorBlock.vue -->
<template>
  <view :class="['editor-block', isEmbedded ? 'embedded' : '', selected ? 'selected' : '']" @click.stop="$emit('select', block.id)">
    <view v-if="selected" class="more-wrap">
      <text class="more-button" @click.stop="menuOpen = !menuOpen">更多</text>
      <view v-if="menuOpen" class="more-menu">
        <text class="menu-item" @click.stop="emitAndClose('duplicate')">复制</text>
        <text class="menu-item" @click.stop="emitAndClose('move-up')">上移</text>
        <text class="menu-item" @click.stop="emitAndClose('move-down')">下移</text>
        <text class="menu-item danger" @click.stop="emitAndClose('delete')">删除</text>
      </view>
    </view>

    <ParagraphBlock
      v-if="block.type === 'paragraph'"
      :block="block"
      :focused="focused"
      :placeholder="paragraphPlaceholder"
      :line-height-mode="lineHeightMode"
      @select="$emit('select', block.id)"
      @update="$emit('update', $event)"
      @split="$emit('split-paragraph', block.id)"
    />
    <HeadingBlock
      v-else-if="block.type === 'heading'"
      :block="block"
      @select="$emit('select', block.id)"
      @update="$emit('update', $event)"
    />
    <QuoteBlock
      v-else-if="block.type === 'quote'"
      :block="block"
      :line-height-mode="lineHeightMode"
      @select="$emit('select', block.id)"
      @update="$emit('update', $event)"
    />
    <ListBlock
      v-else-if="block.type === 'ordered_list' || block.type === 'bullet_list'"
      :block="block"
      :focused="focused"
      :line-height-mode="lineHeightMode"
      @select="$emit('select', block.id)"
      @update="$emit('update', $event)"
    />
    <ImageBlock
      v-else-if="block.type === 'image'"
      :block="block"
      @select="$emit('select', block.id)"
      @update="$emit('update', $event)"
    />
    <WebpageBlock
      v-else-if="block.type === 'webpage'"
      :block="block"
      @select="$emit('select', block.id)"
      @update="$emit('update', $event)"
    />
    <FileBlock
      v-else-if="block.type === 'file'"
      :block="block"
      @select="$emit('select', block.id)"
      @update="$emit('update', $event)"
    />
    <AudioBlock
      v-else-if="block.type === 'audio'"
      :block="block"
      @select="$emit('select', block.id)"
      @update="$emit('update', $event)"
      @audio-action="$emit('audio-action', $event)"
    />
    <view
      v-if="isEmbedded && !hasEmptyParagraphAfter"
      class="continue-area"
      @click.stop="$emit('continue-after', block.id)"
    >
      <text>继续记录…</text>
    </view>
  </view>
</template>

<script>
import ParagraphBlock from './ParagraphBlock.vue'
import HeadingBlock from './HeadingBlock.vue'
import QuoteBlock from './QuoteBlock.vue'
import ListBlock from './ListBlock.vue'
import ImageBlock from './ImageBlock.vue'
import WebpageBlock from './WebpageBlock.vue'
import FileBlock from './FileBlock.vue'
import AudioBlock from './AudioBlock.vue'

export default {
  name: 'EditorBlock',
  components: {
    ParagraphBlock,
    HeadingBlock,
    QuoteBlock,
    ListBlock,
    ImageBlock,
    WebpageBlock,
    FileBlock,
    AudioBlock
  },
  props: {
    block: {
      type: Object,
      required: true
    },
    selected: {
      type: Boolean,
      default: false
    },
    focused: {
      type: Boolean,
      default: false
    },
    nextBlock: {
      type: Object,
      default: null
    },
    paragraphPlaceholder: {
      type: String,
      default: '继续记录…'
    },
    lineHeightMode: {
      type: String,
      default: 'normal'
    }
  },
  emits: ['select', 'update', 'audio-action', 'delete', 'duplicate', 'move-up', 'move-down', 'continue-after', 'split-paragraph'],
  data() {
    return {
      menuOpen: false
    }
  },
  watch: {
    selected(value) {
      if (!value) this.menuOpen = false
    }
  },
  computed: {
    isEmbedded() {
      return ['image', 'webpage', 'file', 'audio'].includes(this.block?.type)
    },
    hasEmptyParagraphAfter() {
      return this.nextBlock?.type === 'paragraph' && !String(this.nextBlock?.text || '').trim()
    }
  },
  methods: {
    emitAndClose(eventName) {
      this.menuOpen = false
      this.$emit(eventName, this.block.id)
    }
  }
}
</script>

<style scoped>
.editor-block {
  position: relative;
  margin: 18rpx 0;
  padding: 0;
  border-radius: 0;
}

.editor-block.selected {
  background: rgba(214, 168, 79, 0.06);
}

.editor-block.selected:not(.embedded) {
  box-shadow: inset 4rpx 0 0 rgba(214, 168, 79, 0.32);
}

.editor-block.embedded.selected {
  background: transparent;
  outline: 2rpx solid rgba(214, 168, 79, 0.35);
  outline-offset: 4rpx;
}

.more-wrap {
  position: absolute;
  right: -6rpx;
  top: 8rpx;
  z-index: 4;
}

.more-button {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 72rpx;
  height: 46rpx;
  border-radius: 999rpx;
  background: rgba(255, 253, 248, 0.92);
  border: 1rpx solid #e8ded2;
  color: #7a746b;
  font-size: 20rpx;
  font-weight: 800;
  line-height: 1;
  text-align: center;
}

.more-menu {
  position: absolute;
  right: 0;
  top: 54rpx;
  width: 156rpx;
  padding: 8rpx;
  border-radius: 18rpx;
  background: #fffdf8;
  border: 1rpx solid #e8ded2;
  box-shadow: 0 12rpx 30rpx rgba(31, 41, 51, 0.12);
  box-sizing: border-box;
}

.menu-item {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 54rpx;
  color: #374151;
  font-size: 24rpx;
  font-weight: 700;
  line-height: 1.2;
  text-align: center;
}

.menu-item.danger {
  color: #a04c42;
}

.continue-area {
  min-height: 58rpx;
  padding: 8rpx 8rpx 0;
  color: rgba(55, 65, 81, 0.36);
  font-size: 28rpx;
  line-height: 1.6;
}
</style>
