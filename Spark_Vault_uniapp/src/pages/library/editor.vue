<!-- Spark_Vault_uniapp/src/pages/library/editor.vue -->
<template>
  <view class="editor-page">
    <view v-if="isQuickEntry" class="quick-entry-page">
      <view class="quick-dim">
        <view class="quick-list-ghost">
          <view class="ghost-card" />
          <view class="ghost-card short" />
        </view>
      </view>
      <view class="quick-sheet">
        <view class="quick-handle" />
        <textarea
          class="quick-input"
          v-model="quickText"
          placeholder="现在的想法是..."
          :maxlength="2000"
          :auto-height="true"
          focus
        />
        <view v-if="quickAttachments.length" class="quick-attachments">
          <text
            v-for="(item, index) in quickAttachments"
            :key="index"
            class="quick-attachment"
          >{{ item.type === 'audio' ? '录音' : '图片' }}</text>
        </view>
        <view class="quick-tools">
          <text class="quick-tool" @click="quickText += '#'">#</text>
          <text class="quick-tool" @click="pickQuickImage">图片</text>
          <text class="quick-tool" @click="quickText += '**重点**'">B</text>
          <text class="quick-tool" @click="quickText += '\n- '">列表</text>
          <text class="quick-tool more" @click="showPluginHint">...</text>
          <text
            :class="['quick-mic', quickRecording ? 'recording' : '']"
            @click="toggleQuickRecord"
          >{{ quickRecording ? '停止' : '录音' }}</text>
          <button class="quick-send" :disabled="!canSaveQuick()" @click="saveQuickEntry">发送</button>
        </view>
      </view>
    </view>

    <view v-else class="topbar">
      <text class="nav-back" @click="goBack">返回</text>
      <button class="save-button" @click="saveDocument">保存</button>
    </view>
    <scroll-view v-if="!isQuickEntry" scroll-y class="scroll-shell">
      <view class="meta-card">
        <input
          class="title-input"
          v-model="title"
          :placeholder="titlePlaceholder"
          :maxlength="80"
        />
        <view class="category-panel">
          <view class="category-segment">
            <text
              v-for="item in categoryOptions"
              :key="item.value"
              :class="['category-tab', category === item.value ? 'active' : '']"
              @click="setCategory(item.value)"
            >{{ item.label }}</text>
          </view>
          <view
            v-if="subtypePickerOpen"
            class="subtype-picker-wrap"
          >
            <view
              class="subtype-picker"
            >
              <text
                v-for="item in activeSubtypeOptions"
                :key="item.value"
                :class="['subtype-option', subtype === item.value ? 'active' : '']"
                @click="selectSubtype(item.value)"
              >{{ item.label }}</text>
            </view>
          </view>
          <input
            v-if="category === 'reference'"
            class="source-input"
            v-model="source"
            :placeholder="sourcePlaceholder"
            :maxlength="120"
          />
        </view>
        <view class="meta-row">
          <text class="meta-time">最后编辑 {{ updatedLabel }}</text>
        </view>
      </view>

      <view class="writing-paper">
        <view class="paper-head">
          <text class="paper-title">正文</text>
          <view class="paper-actions">
            <text
              v-for="action in formatActions"
              :key="action.type"
              class="format-action"
              @click="handleEditorAction(action.type)"
            >{{ action.label }}</text>
            <text class="format-action" @click="handleEditorAction('line_height')">{{ lineHeightLabel }}</text>
          </view>
        </view>
        <view class="insert-row">
          <text
            :class="['insert-action', isRecording ? 'recording' : '']"
            @click="handleEditorAction('audio')"
          >{{ isRecording ? '停止录音' : '录音' }}</text>
          <text class="insert-action" @click="handleEditorAction('file')">添加文件</text>
        </view>
        <view class="block-flow">
          <EditorBlock
            v-for="(block, index) in blocks"
            :key="block.id"
            :block="block"
            :next-block="blocks[index + 1]"
            :selected="selectedBlockId === block.id"
            :focused="focusedBlockId === block.id"
            :paragraph-placeholder="placeholderForBlock(block, index)"
            :line-height-mode="lineHeightMode"
            @select="selectBlock"
            @update="updateBlock"
            @audio-action="handleAudioAction"
            @delete="deleteBlock"
            @duplicate="duplicateBlock"
            @move-up="moveBlockUp"
            @move-down="moveBlockDown"
            @continue-after="ensureParagraphAfter"
            @split-paragraph="splitParagraph"
          />
        </view>
        <view class="editor-tags">
          <text
            v-for="tag in tags"
            :key="tag"
            class="tag-pill inline"
            @click="removeTag(tag)"
          >#{{ tag }} ×</text>
          <text class="add-tag" @click="openTagInput">+ 标签</text>
        </view>
      </view>

      <view class="bottom-spacer" />
    </scroll-view>

    <view v-if="linkInputVisible" class="dock-panel link-panel">
      <input
        class="dock-input"
        v-model="draftUrl"
        placeholder="粘贴网页链接"
        confirm-type="done"
        :maxlength="300"
        @confirm="confirmWebpage"
      />
      <text class="dock-confirm" @click="confirmWebpage">插入</text>
    </view>

    <view v-if="tagInputVisible" class="tag-panel">
      <input
        class="dock-input"
        v-model="draftTag"
        placeholder="输入标签"
        :maxlength="20"
        @confirm="addTag"
      />
      <text class="dock-confirm" @click="addTag">加入</text>
    </view>

  </view>
</template>

<script>
import EditorBlock from '../../components/editor/EditorBlock.vue'
import { getVaultStore } from '../../store/vaultStore.js'

function createId(prefix = 'block') {
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 100000)}`
}

function nowIso() {
  return new Date().toISOString()
}

function getDomain(url = '') {
  try {
    return new URL(url).hostname.replace(/^www\./, '')
  } catch (_) {
    return 'web link'
  }
}

export default {
  name: 'LibraryEditor',
  components: {
    EditorBlock
  },
  data() {
    const createdAt = nowIso()
    return {
      title: '',
      category: 'thought',
      subtype: 'idea',
      source: '我自己',
      blocks: [
        {
          id: createId('paragraph'),
          type: 'paragraph',
          text: ''
        }
      ],
      tags: [],
      fragmentId: null,
      saving: false,
      selectedBlockId: null,
      createdAt,
      updatedAt: createdAt,
      tagInputVisible: false,
      draftTag: '',
      linkInputVisible: false,
      draftUrl: '',
      recorder: null,
      isRecording: false,
      recordingBlockId: null,
      focusedBlockId: null,
      subtypePickerOpen: false,
      lineHeightMode: 'normal',
      isQuickEntry: true,
      quickText: '',
      quickAttachments: [],
      quickRecording: false
    }
  },
  computed: {
    formatActions() {
      return [
        { type: 'heading', label: '标题' },
        { type: 'ordered_list', label: '编号' },
        { type: 'bullet_list', label: '列表' },
        { type: 'quote', label: '引用' }
      ]
    },
    categoryOptions() {
      return [
        { value: 'thought', label: '我的内容' },
        { value: 'reference', label: '外部资料' }
      ]
    },
    subtypeOptions() {
      return {
        thought: [
          { value: 'idea', label: '想法' },
          { value: 'diary', label: '日记' },
          { value: 'quick_note', label: '随手记录' },
          { value: 'voice_note', label: '录音自述' }
        ],
        reference: [
          { value: 'book_excerpt', label: '书摘' },
          { value: 'article_excerpt', label: '文章' },
          { value: 'web_clip', label: '网页' },
          { value: 'video_note', label: '视频' },
          { value: 'file_knowledge', label: '文件' }
        ]
      }
    },
    activeSubtypeOptions() {
      return this.subtypeOptions[this.category] || []
    },
    lineHeightLabel() {
      const map = {
        compact: '紧凑行距',
        normal: '标准行距',
        loose: '宽松行距'
      }
      return map[this.lineHeightMode] || map.normal
    },
    titlePlaceholder() {
      const map = {
        idea: '未命名想法',
        diary: '今天的记录',
        quick_note: '随手记录',
        voice_note: '录音自述',
        book_excerpt: '书名或章节',
        article_excerpt: '文章标题',
        web_clip: '网页标题',
        video_note: '视频标题',
        file_knowledge: '文件标题'
      }
      return map[this.subtype] || '未命名记录'
    },
    paragraphPlaceholder() {
      const map = {
        idea: '记录一个刚冒出来的想法…',
        diary: '写下今天发生了什么，以及你真实的感受…',
        quick_note: '先记下来，之后再整理…',
        voice_note: '录音转写后会出现在这里，也可以直接补充文字…',
        book_excerpt: '摘录原文，并写下你的理解…',
        article_excerpt: '粘贴文章片段，或记录你的阅读笔记…',
        web_clip: '粘贴链接后，会生成网页卡片和摘要…',
        video_note: '记录视频中的关键观点和你的想法…',
        file_knowledge: '上传文件后，可以记录摘要、重点和你的理解…'
      }
      return map[this.subtype] || '继续记录…'
    },
    sourcePlaceholder() {
      const map = {
        book_excerpt: '来源：书名、作者、章节',
        article_excerpt: '来源：文章、作者、发布处',
        web_clip: '来源：网页链接或站点',
        video_note: '来源：视频标题、作者、平台',
        file_knowledge: '来源：文件名或文件路径'
      }
      return map[this.subtype] || '来源'
    },
    updatedLabel() {
      const date = new Date(this.updatedAt)
      if (Number.isNaN(date.getTime())) return '刚刚'
      return `${date.getMonth() + 1}/${date.getDate()} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
    }
  },
  onLoad(options = {}) {
    const id = Number(options.id)
    if (Number.isInteger(id)) {
      this.isQuickEntry = false
      this.fragmentId = id
      this.loadDocument(id)
    } else {
      this.isQuickEntry = false
      try {
        uni.setStorageSync('mirrorme_open_quick_composer', '1')
      } catch (_) {}
      uni.switchTab({ url: '/pages/home/index' })
    }
  },
  methods: {
    canSaveQuick() {
      return Boolean(this.quickText.trim() || this.quickAttachments.length)
    },
    saveQuickEntry() {
      const text = this.quickText.trim()
      if (!text && !this.quickAttachments.length) return
      const blocks = []
      if (text) {
        blocks.push({ id: createId('quick'), type: 'paragraph', text })
      }
      this.quickAttachments.forEach((attachment) => {
        blocks.push({ id: createId(attachment.type || 'attachment'), ...attachment })
      })
      const store = getVaultStore()
      const result = store.saveFragment({
        title: text ? text.slice(0, 24) : '未命名碎片',
        content: text,
        originalText: text,
        content_type: 'personal_content',
        subtype: '想法',
        acquisition_method: this.quickAttachments.some((item) => item.type === 'audio') ? 'voice' : 'manual',
        blocks,
        tags: ['随手记录'],
        createdAt: nowIso(),
        updatedAt: nowIso()
      })
      if (!result.ok) {
        uni.showToast({ title: result.error || '保存失败', icon: 'none' })
        return
      }
      this.quickText = ''
      this.quickAttachments = []
      uni.showToast({ title: '已保存', icon: 'success' })
      setTimeout(() => {
        uni.switchTab({ url: '/pages/home/index' })
      }, 250)
    },
    pickQuickImage() {
      if (typeof uni === 'undefined' || typeof uni.chooseImage !== 'function') {
        uni.showToast({ title: '当前环境不支持选择图片', icon: 'none' })
        return
      }
      uni.chooseImage({
        count: 1,
        sourceType: ['album', 'camera'],
        success: (res) => {
          const path = res?.tempFilePaths?.[0]
          if (!path) {
            uni.showToast({ title: '图片路径为空', icon: 'none' })
            return
          }
          this.quickAttachments = [
            ...this.quickAttachments,
            { type: 'image', src: path, caption: '截图或图片', ocrStatus: '待识别' }
          ]
          uni.showToast({ title: '图片已加入', icon: 'success' })
        },
        fail: () => {
          uni.showToast({ title: '未选择图片', icon: 'none' })
        }
      })
    },
    toggleQuickRecord() {
      if (typeof uni === 'undefined' || typeof uni.getRecorderManager !== 'function') {
        uni.showToast({ title: '当前环境不支持录音', icon: 'none' })
        return
      }
      const recorder = uni.getRecorderManager()
      if (!this.quickRecording) {
        recorder.onStop((res) => {
          const src = res?.tempFilePath
          this.quickRecording = false
          if (!src) {
            uni.showToast({ title: '录音文件为空', icon: 'none' })
            return
          }
          this.quickAttachments = [
            ...this.quickAttachments,
            { type: 'audio', src, transcribeStatus: '待转写' }
          ]
          uni.showToast({ title: '录音已加入', icon: 'success' })
        })
        recorder.start({ duration: 60000, format: 'mp3' })
        this.quickRecording = true
        return
      }
      recorder.stop()
    },
    showPluginHint() {
      uni.showToast({ title: '更多采集方式稍后接入', icon: 'none' })
    },
    loadDocument(id) {
      const store = getVaultStore()
      const fragment = store.getFragmentById(id)
      if (!fragment) {
        uni.showToast({ title: '记录不存在', icon: 'none' })
        return
      }
      this.title = fragment.title || fragment.sourceTitle || ''
      this.category = fragment.content_type === 'reference_content' ? 'reference' : 'thought'
      this.subtype = this.toEditorSubtype(fragment.subtype || fragment.form_kind, this.category)
      this.source = fragment.source || fragment.sourceTitle || (this.category === 'thought' ? '我自己' : '')
      this.tags = Array.isArray(fragment.tags) ? [...fragment.tags] : []
      this.createdAt = new Date(fragment.created_at || fragment.createdAt || Date.now()).toISOString()
      this.updatedAt = new Date(fragment.updated_at || fragment.updatedAt || Date.now()).toISOString()
      this.lineHeightMode = ['compact', 'normal', 'loose'].includes(fragment.lineHeightMode)
        ? fragment.lineHeightMode
        : 'normal'
      this.blocks = Array.isArray(fragment.blocks) && fragment.blocks.length
        ? fragment.blocks
        : [{ id: createId('paragraph'), type: 'paragraph', text: fragment.content || fragment.originalText || '' }]
      this.selectedBlockId = this.blocks[0]?.id || null
    },
    toEditorSubtype(subtype, category) {
      const thoughtMap = {
        '想法': 'idea',
        '日记': 'diary',
        '观察': 'quick_note'
      }
      const referenceMap = {
        '书摘': 'book_excerpt',
        '网页': 'web_clip',
        '文件': 'file_knowledge'
      }
      return category === 'reference'
        ? (referenceMap[subtype] || 'book_excerpt')
        : (thoughtMap[subtype] || 'idea')
    },
    toVaultSubtype() {
      const map = {
        idea: '想法',
        diary: '日记',
        quick_note: '观察',
        voice_note: '想法',
        book_excerpt: '书摘',
        article_excerpt: '网页',
        web_clip: '网页',
        video_note: '网页',
        file_knowledge: '文件'
      }
      return map[this.subtype] || '想法'
    },
    documentText() {
      return this.blocks
        .map((block) => {
          if (!block) return ''
          if (['paragraph', 'quote', 'heading'].includes(block.type)) return block.text || ''
          if (['ordered_list', 'bullet_list'].includes(block.type)) {
            return (block.items || []).map((item, index) => {
              const text = String(item || '').trim()
              if (!text) return ''
              return block.type === 'ordered_list' ? `${index + 1}. ${text}` : `- ${text}`
            }).filter(Boolean).join('\n')
          }
          if (block.type === 'webpage') return [block.title, block.summary, block.url].filter(Boolean).join('\n')
          if (block.type === 'file') return [block.name, block.path].filter(Boolean).join('\n')
          if (block.type === 'image') return [block.caption, block.src].filter(Boolean).join('\n')
          if (block.type === 'audio') return [block.transcribeStatus, block.src].filter(Boolean).join('\n')
          return ''
        })
        .filter((text) => String(text || '').trim())
        .join('\n\n')
        .trim()
    },
    setCategory(nextCategory) {
      if (!['thought', 'reference'].includes(nextCategory)) return
      if (this.category === nextCategory) {
        this.subtypePickerOpen = !this.subtypePickerOpen
        return
      }
      this.category = nextCategory
      this.subtype = nextCategory === 'thought' ? 'idea' : 'book_excerpt'
      this.source = nextCategory === 'thought' ? '我自己' : ''
      this.subtypePickerOpen = true
      this.touchUpdated()
    },
    setSubtype(nextSubtype) {
      const allowed = (this.subtypeOptions[this.category] || []).map((item) => item.value)
      if (!allowed.includes(nextSubtype)) return
      this.subtype = nextSubtype
      this.touchUpdated()
    },
    selectSubtype(nextSubtype) {
      this.setSubtype(nextSubtype)
      this.subtypePickerOpen = false
    },
    goBack() {
      uni.navigateBack()
    },
    touchUpdated() {
      this.updatedAt = nowIso()
    },
    selectBlock(id) {
      if (!id) return
      this.selectedBlockId = id
    },
    placeholderForBlock(block, index) {
      if (!block || block.type !== 'paragraph') return '继续记录…'
      const text = String(block.text || '').trim()
      if (text) return '继续记录…'
      const firstParagraphIndex = this.blocks.findIndex((item) => item.type === 'paragraph')
      return index === firstParagraphIndex ? this.paragraphPlaceholder : '继续记录…'
    },
    selectedIndex() {
      const index = this.blocks.findIndex((block) => block.id === this.selectedBlockId)
      return index >= 0 ? index : this.blocks.length - 1
    },
    insertBlock(block) {
      if (!block || !block.type) return
      const index = this.selectedIndex()
      const nextBlocks = [...this.blocks]
      nextBlocks.splice(index + 1, 0, block)
      this.blocks = nextBlocks
      this.selectedBlockId = block.id
      this.touchUpdated()
    },
    createTextBlock(type) {
      if (type === 'heading') {
        return { id: createId('heading'), type: 'heading', text: '' }
      }
      if (type === 'ordered_list') {
        return { id: createId('ordered_list'), type: 'ordered_list', items: [''] }
      }
      if (type === 'bullet_list') {
        return { id: createId('bullet_list'), type: 'bullet_list', items: [''] }
      }
      return { id: createId('paragraph'), type: 'paragraph', text: '' }
    },
    insertEmbeddedBlock(block) {
      if (!block || !block.type) return
      const index = this.selectedIndex()
      const paragraph = {
        id: createId('paragraph'),
        type: 'paragraph',
        text: ''
      }
      const nextBlocks = [...this.blocks]
      nextBlocks.splice(index + 1, 0, block, paragraph)
      this.blocks = nextBlocks
      this.selectedBlockId = paragraph.id
      this.focusBlock(paragraph.id)
      this.touchUpdated()
    },
    focusBlock(id) {
      if (!id) return
      this.focusedBlockId = null
      this.$nextTick(() => {
        this.selectedBlockId = id
        this.focusedBlockId = id
      })
    },
    ensureParagraphAfter(id) {
      const index = this.blocks.findIndex((block) => block.id === id)
      if (index < 0) return null
      const nextBlock = this.blocks[index + 1]
      if (nextBlock?.type === 'paragraph' && !String(nextBlock.text || '').trim()) {
        this.focusBlock(nextBlock.id)
        return nextBlock.id
      }
      const paragraph = {
        id: createId('paragraph'),
        type: 'paragraph',
        text: ''
      }
      const nextBlocks = [...this.blocks]
      nextBlocks.splice(index + 1, 0, paragraph)
      this.blocks = nextBlocks
      this.focusBlock(paragraph.id)
      this.touchUpdated()
      return paragraph.id
    },
    splitParagraph(id) {
      const index = this.blocks.findIndex((block) => block.id === id)
      if (index < 0) return
      const nextBlock = this.blocks[index + 1]
      if (nextBlock?.type === 'paragraph' && !String(nextBlock.text || '').trim()) {
        this.focusBlock(nextBlock.id)
        return
      }
      const paragraph = {
        id: createId('paragraph'),
        type: 'paragraph',
        text: ''
      }
      const nextBlocks = [...this.blocks]
      nextBlocks.splice(index + 1, 0, paragraph)
      this.blocks = nextBlocks
      this.focusBlock(paragraph.id)
      this.touchUpdated()
    },
    updateBlock(nextBlock) {
      if (!nextBlock || !nextBlock.id) return
      this.blocks = this.blocks.map((block) => block.id === nextBlock.id ? { ...block, ...nextBlock } : block)
      this.touchUpdated()
    },
    deleteBlock(id) {
      if (!id) return
      const index = this.blocks.findIndex((block) => block.id === id)
      const deleted = this.blocks[index]
      const nextBlocks = this.blocks.filter((block) => block.id !== id)
      const embeddedTypes = ['image', 'webpage', 'file', 'audio']
      let fallbackFocusId = null
      if (embeddedTypes.includes(deleted?.type) && nextBlocks[index]?.type !== 'paragraph') {
        const paragraph = { id: createId('paragraph'), type: 'paragraph', text: '' }
        nextBlocks.splice(index, 0, paragraph)
        fallbackFocusId = paragraph.id
      }
      this.blocks = nextBlocks.length ? nextBlocks : [{ id: createId('paragraph'), type: 'paragraph', text: '' }]
      if (this.selectedBlockId === id) {
        this.selectedBlockId = fallbackFocusId || this.blocks[Math.min(index, this.blocks.length - 1)]?.id || null
      }
      if (fallbackFocusId) this.focusBlock(fallbackFocusId)
      this.touchUpdated()
    },
    duplicateBlock(id) {
      const index = this.blocks.findIndex((block) => block.id === id)
      if (index < 0) return
      const copied = { ...this.blocks[index], id: createId(this.blocks[index].type || 'block') }
      const nextBlocks = [...this.blocks]
      nextBlocks.splice(index + 1, 0, copied)
      this.blocks = nextBlocks
      this.selectedBlockId = copied.id
      this.touchUpdated()
    },
    moveBlockUp(id) {
      const index = this.blocks.findIndex((block) => block.id === id)
      if (index <= 0) return
      const nextBlocks = [...this.blocks]
      const item = nextBlocks.splice(index, 1)[0]
      nextBlocks.splice(index - 1, 0, item)
      this.blocks = nextBlocks
      this.touchUpdated()
    },
    moveBlockDown(id) {
      const index = this.blocks.findIndex((block) => block.id === id)
      if (index < 0 || index >= this.blocks.length - 1) return
      const nextBlocks = [...this.blocks]
      const item = nextBlocks.splice(index, 1)[0]
      nextBlocks.splice(index + 1, 0, item)
      this.blocks = nextBlocks
      this.touchUpdated()
    },
    handleEditorAction(type) {
      if (['heading', 'ordered_list', 'bullet_list'].includes(type)) {
        this.insertBlock(this.createTextBlock(type))
        return
      }
      if (type === 'line_height') {
        this.toggleLineHeight()
        return
      }
      if (type === 'image') {
        this.insertImage()
        return
      }
      if (type === 'audio') {
        this.insertAudio()
        return
      }
      if (type === 'webpage') {
        this.openLinkInput()
        return
      }
      if (type === 'file') {
        this.insertFile()
        return
      }
      if (type === 'quote') {
        this.insertBlock({
          id: createId('quote'),
          type: 'quote',
          text: ''
        })
        return
      }
      if (type === 'tag') {
        this.openTagInput()
      }
    },
    openTagInput() {
      this.linkInputVisible = false
      this.tagInputVisible = true
    },
    toggleLineHeight() {
      const modes = ['compact', 'normal', 'loose']
      const index = modes.indexOf(this.lineHeightMode)
      this.lineHeightMode = modes[(index + 1) % modes.length]
      uni.showToast({ title: this.lineHeightLabel, icon: 'none' })
      this.touchUpdated()
    },
    insertImage() {
      if (typeof uni === 'undefined' || typeof uni.chooseImage !== 'function') {
        uni.showToast({ title: '当前环境不支持选择图片', icon: 'none' })
        return
      }
      uni.chooseImage({
        count: 1,
        sourceType: ['album', 'camera'],
        success: (res) => {
          const path = res?.tempFilePaths?.[0]
          if (!path) {
            uni.showToast({ title: '图片路径为空', icon: 'none' })
            return
          }
          this.insertEmbeddedBlock({
            id: createId('image'),
            type: 'image',
            src: path,
            caption: '',
            ocrStatus: '等待识别'
          })
        },
        fail: () => {
          uni.showToast({ title: '未选择图片', icon: 'none' })
        }
      })
    },
    openLinkInput() {
      this.tagInputVisible = false
      this.linkInputVisible = true
      this.draftUrl = ''
    },
    confirmWebpage() {
      const url = this.draftUrl.trim()
      if (!url) {
        uni.showToast({ title: '请输入链接', icon: 'none' })
        return
      }
      const normalizedUrl = /^https?:\/\//i.test(url) ? url : `https://${url}`
      this.insertWebpage(normalizedUrl)
      this.draftUrl = ''
      this.linkInputVisible = false
    },
    insertWebpage(url) {
      const mockUrl = url || 'https://mirrorme.local/library/web-note'
      this.insertEmbeddedBlock({
        id: createId('webpage'),
        type: 'webpage',
        url: mockUrl,
        title: getDomain(mockUrl),
        domain: getDomain(mockUrl),
        summary: '已插入网页链接。当前为前端预览卡片，可以继续补充摘要。'
      })
    },
    async insertFile() {
      const file = await this.chooseFileSafe()
      const name = file?.name || 'MirrorMe-Reference.pdf'
      const path = file?.path || file?.tempFilePath || 'mock://mirrorme/reference.pdf'
      const size = Number(file?.size || 246000)
      this.insertEmbeddedBlock({
        id: createId('file'),
        type: 'file',
        name,
        fileType: name.includes('.') ? name.split('.').pop().toUpperCase() : 'FILE',
        size,
        path,
        parseStatus: '等待解析'
      })
    },
    chooseFileSafe() {
      if (typeof uni !== 'undefined' && typeof uni.chooseFile === 'function') {
        return new Promise((resolve) => {
          uni.chooseFile({
            count: 1,
            success: (res) => resolve(res?.tempFiles?.[0] || null),
            fail: () => resolve(null)
          })
        })
      }
      if (typeof uni !== 'undefined' && typeof uni.chooseMessageFile === 'function') {
        return new Promise((resolve) => {
          uni.chooseMessageFile({
            count: 1,
            type: 'file',
            success: (res) => resolve(res?.tempFiles?.[0] || null),
            fail: () => resolve(null)
          })
        })
      }
      return Promise.resolve(null)
    },
    insertAudio() {
      if (this.isRecording) {
        this.stopRecording()
        return
      }
      if (typeof uni === 'undefined' || typeof uni.getRecorderManager !== 'function') {
        this.insertMockAudio()
        return
      }
      const recorder = this.recorder || uni.getRecorderManager()
      this.recorder = recorder
      recorder.onStop((res) => {
        this.isRecording = false
        this.insertEmbeddedBlock({
          id: createId('audio'),
          type: 'audio',
          src: res?.tempFilePath || 'mock://mirrorme/audio-note.mp3',
          duration: '00:12',
          transcribeStatus: '等待转录'
        })
      })
      recorder.onError(() => {
        this.isRecording = false
        this.insertMockAudio()
      })
      try {
        recorder.start({
          duration: 60000,
          sampleRate: 16000,
          numberOfChannels: 1,
          encodeBitRate: 48000,
          format: 'mp3'
        })
        this.isRecording = true
        uni.showToast({ title: '录音中，再点一次停止', icon: 'none' })
      } catch (_) {
        this.isRecording = false
        this.insertMockAudio()
      }
    },
    stopRecording() {
      try {
        this.recorder?.stop()
      } catch (_) {
        this.isRecording = false
        this.insertMockAudio()
      }
    },
    insertMockAudio() {
      this.insertEmbeddedBlock({
        id: createId('audio'),
        type: 'audio',
        src: 'mock://mirrorme/audio-note.mp3',
        duration: '00:12',
        transcribeStatus: '前端 mock，等待转录'
      })
    },
    insertAudio() {
      if (this.isRecording) {
        this.stopRecording()
        return
      }
      const audioBlock = {
        id: createId('audio'),
        type: 'audio',
        src: '',
        duration: '00:00',
        transcribeStatus: '准备录音',
        recording: false
      }
      this.insertEmbeddedBlock(audioBlock)
      this.startRecordingForBlock(audioBlock.id)
    },
    handleAudioAction(payload) {
      const blockId = payload?.id
      const action = payload?.action
      if (!blockId || !action) return
      if (action === 'stop') {
        this.stopRecording()
        return
      }
      if (action === 'start') {
        this.startRecordingForBlock(blockId)
      }
    },
    startRecordingForBlock(blockId) {
      if (!blockId) return
      if (this.isRecording && this.recordingBlockId && this.recordingBlockId !== blockId) {
        uni.showToast({ title: '请先停止当前录音', icon: 'none' })
        return
      }
      this.recordingBlockId = blockId
      this.isRecording = true
      this.updateAudioBlock(blockId, {
        recording: true,
        transcribeStatus: '录音中'
      })
      if (typeof uni === 'undefined' || typeof uni.getRecorderManager !== 'function') {
        this.finishMockAudio(blockId)
        return
      }
      const recorder = this.recorder || uni.getRecorderManager()
      this.recorder = recorder
      recorder.onStop((res) => {
        const targetId = this.recordingBlockId || blockId
        this.isRecording = false
        this.recordingBlockId = null
        this.updateAudioBlock(targetId, {
          src: res?.tempFilePath || 'mock://mirrorme/audio-note.mp3',
          duration: '00:12',
          recording: false,
          transcribeStatus: '等待转录'
        })
      })
      recorder.onError(() => {
        this.finishMockAudio(this.recordingBlockId || blockId)
      })
      try {
        recorder.start({
          duration: 60000,
          sampleRate: 16000,
          numberOfChannels: 1,
          encodeBitRate: 48000,
          format: 'mp3'
        })
        uni.showToast({ title: '录音中，点录音块停止', icon: 'none' })
      } catch (_) {
        this.finishMockAudio(blockId)
      }
    },
    stopRecording() {
      if (!this.recordingBlockId) {
        this.isRecording = false
        return
      }
      try {
        this.recorder?.stop()
      } catch (_) {
        this.finishMockAudio(this.recordingBlockId)
      }
    },
    finishMockAudio(blockId) {
      if (!blockId) return
      this.isRecording = false
      this.recordingBlockId = null
      this.updateAudioBlock(blockId, {
        src: 'mock://mirrorme/audio-note.mp3',
        duration: '00:12',
        recording: false,
        transcribeStatus: '前端 mock，等待转录'
      })
    },
    updateAudioBlock(blockId, patch) {
      if (!blockId || !patch) return
      this.blocks = this.blocks.map((block) => block.id === blockId ? { ...block, ...patch } : block)
      this.touchUpdated()
    },
    addTag() {
      const tag = this.draftTag.trim()
      if (tag && !this.tags.includes(tag)) {
        this.tags = [...this.tags, tag]
      }
      this.draftTag = ''
      this.tagInputVisible = false
      this.touchUpdated()
    },
    removeTag(tag) {
      this.tags = this.tags.filter((item) => item !== tag)
      this.touchUpdated()
    },
    saveDocument() {
      if (this.saving) return
      const content = this.documentText()
      if (!content) {
        uni.showToast({ title: '请先输入内容', icon: 'none' })
        return
      }
      this.saving = true
      const now = nowIso()
      const vaultSubtype = this.toVaultSubtype()
      const payload = {
        title: this.title.trim() || '未命名记录',
        category: this.category,
        subtype: vaultSubtype,
        form_kind: vaultSubtype,
        content,
        originalText: content,
        content_type: this.category === 'reference' ? 'reference_content' : 'personal_content',
        acquisition_method: this.subtype === 'voice_note' ? 'voice' : 'manual',
        blocks: this.blocks,
        lineHeightMode: this.lineHeightMode,
        tags: this.tags,
        source: this.category === 'thought' ? '我自己' : this.source.trim(),
        sourceTitle: this.category === 'thought' ? this.title.trim() : this.source.trim(),
        createdAt: this.createdAt,
        updatedAt: now
      }
      this.updatedAt = payload.updatedAt
      const store = getVaultStore()
      const result = this.fragmentId
        ? store.updateFragment(this.fragmentId, payload)
        : store.saveFragment(payload)
      this.saving = false
      if (!result.ok) {
        uni.showToast({ title: result.error || '保存失败', icon: 'none' })
        return
      }
      this.fragmentId = result.fragment.id
      uni.showToast({ title: '已保存', icon: 'success' })
      setTimeout(() => {
        uni.switchTab({ url: '/pages/home/index' })
      }, 400)
    }
  }
}
</script>

<style scoped>
.editor-page {
  min-height: 100vh;
  background: #f6f2ec;
  color: #1f2933;
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
}

.editor-page text,
.editor-page input,
.editor-page textarea,
.editor-page button {
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
}

.quick-entry-page {
  position: relative;
  min-height: 100vh;
  overflow: hidden;
  background: #f2f0e9;
}

.quick-dim {
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  padding: 92rpx 42rpx 0;
  box-sizing: border-box;
  opacity: 0.72;
}

.quick-list-ghost {
  display: flex;
  flex-direction: column;
  gap: 24rpx;
}

.ghost-card {
  height: 178rpx;
  border-radius: 24rpx;
  background: #fffdf8;
  border: 1rpx solid #dedacf;
}

.ghost-card.short {
  height: 140rpx;
}

.quick-sheet {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 12;
  min-height: 360rpx;
  padding: 18rpx 28rpx 30rpx;
  border-radius: 30rpx 30rpx 0 0;
  border: 1rpx solid #dedacf;
  background: #fffdf8;
  box-shadow: 0 -18rpx 44rpx rgba(31, 41, 51, 0.14);
  box-sizing: border-box;
}

.quick-handle {
  width: 58rpx;
  height: 8rpx;
  margin: 0 auto 28rpx;
  border-radius: 999rpx;
  background: #dedacf;
}

.quick-input {
  width: 100%;
  min-height: 196rpx;
  max-height: 430rpx;
  padding: 0 8rpx;
  color: #1a2b48;
  font-size: 32rpx;
  line-height: 1.58;
  background: transparent;
  border: none;
  box-sizing: border-box;
}

.quick-attachments {
  display: flex;
  flex-wrap: wrap;
  gap: 10rpx;
  margin: 8rpx 0 4rpx;
}

.quick-attachment {
  height: 42rpx;
  padding: 0 16rpx;
  border-radius: 999rpx;
  background: #f8f7f2;
  border: 1rpx solid #dedacf;
  color: #1a2b48;
  font-size: 20rpx;
  line-height: 42rpx;
}

.quick-tools {
  display: flex;
  align-items: center;
  gap: 18rpx;
  margin-top: 20rpx;
  padding-top: 16rpx;
  border-top: none;
  overflow-x: auto;
}

.quick-tool,
.quick-mic,
.quick-send {
  flex-shrink: 0;
  min-width: 64rpx;
  height: 64rpx;
  padding: 0 16rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 999rpx;
  background: transparent;
  color: #1a2b48;
  font-size: 30rpx;
  font-weight: 850;
  box-sizing: border-box;
}

.quick-tool.more {
  min-width: 64rpx;
}

.quick-mic {
  margin-left: auto;
  color: #047857;
  border: 1rpx solid rgba(4, 120, 87, 0.22);
  background: #f0fdf4;
}

.quick-mic.recording {
  color: #b91c1c;
  border-color: rgba(185, 28, 28, 0.28);
  background: #fff1f2;
}

.quick-send {
  min-width: 102rpx;
  margin: 0;
  border: none;
  background: #1a2b48;
  color: #c4a052;
  line-height: 64rpx;
}

.quick-send[disabled] {
  opacity: 0.38;
}

.topbar {
  position: sticky;
  top: 0;
  z-index: 8;
  display: flex;
  align-items: center;
  justify-content: flex-start;
  height: 92rpx;
  min-height: 92rpx;
  padding: 0 32rpx;
  box-sizing: border-box;
  background: rgba(246, 242, 236, 0.96);
  border-bottom: 1rpx solid rgba(232, 222, 210, 0.82);
}

.nav-back {
  min-width: 92rpx;
  height: 56rpx;
  border-radius: 999rpx;
  border: 1rpx solid #e8ded2;
  background: #fffdf8;
  color: #374151;
  font-size: 26rpx;
  font-weight: 700;
  line-height: 56rpx;
  text-align: center;
}

.save-button {
  position: fixed;
  top: 18rpx;
  right: 32rpx;
  z-index: 20;
  min-width: 104rpx;
  height: 56rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 999rpx;
  background: #fffdf8;
  border: 1rpx solid #e8ded2;
  color: #374151;
  font-size: 26rpx;
  font-weight: 700;
  line-height: 1;
}

.scroll-shell {
  height: calc(100vh - 92rpx);
}

.meta-card {
  margin: 28rpx 28rpx 18rpx;
  padding: 34rpx 34rpx 24rpx;
  border: 1rpx solid rgba(232, 222, 210, 0.9);
  border-radius: 28rpx;
  background: #fffdf8;
  box-shadow: 0 10rpx 26rpx rgba(31, 41, 51, 0.05);
  box-sizing: border-box;
}

.writing-paper {
  min-height: 520rpx;
  margin: 0 28rpx 28rpx;
  padding: 30rpx 36rpx 46rpx;
  border: 1rpx solid rgba(232, 222, 210, 0.95);
  border-radius: 18rpx;
  background-color: #fffdf8;
  background-image: linear-gradient(to bottom, transparent 0, transparent 71rpx, rgba(232, 222, 210, 0.58) 72rpx);
  background-size: 100% 72rpx;
  box-shadow: 0 14rpx 34rpx rgba(31, 41, 51, 0.07);
  box-sizing: border-box;
}

.paper-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16rpx;
  margin-bottom: 14rpx;
  padding-bottom: 18rpx;
  border-bottom: 1rpx solid rgba(232, 222, 210, 0.72);
}

.paper-title {
  color: #1f2933;
  font-size: 28rpx;
  font-weight: 800;
}

.paper-actions {
  display: flex;
  align-items: center;
  gap: 8rpx;
  overflow-x: auto;
}

.format-action,
.insert-action,
.add-tag {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 70rpx;
  height: 44rpx;
  padding: 0 14rpx;
  border: 1rpx solid #e8ded2;
  border-radius: 999rpx;
  background: rgba(250, 247, 241, 0.9);
  color: #374151;
  font-size: 21rpx;
  font-weight: 800;
  box-sizing: border-box;
  white-space: nowrap;
}

.insert-row {
  display: flex;
  align-items: center;
  gap: 12rpx;
  margin: 0 0 18rpx;
}

.insert-action {
  min-width: 112rpx;
  background: #fffdf8;
}

.insert-action.recording {
  border-color: rgba(160, 76, 66, 0.4);
  background: #fff1f2;
  color: #a04c42;
}

.title-input {
  width: 100%;
  min-height: 68rpx;
  color: #1f2933;
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
  font-size: 46rpx;
  font-weight: 700;
  line-height: 1.25;
  background: transparent;
}

.category-panel {
  margin: 12rpx 0 22rpx;
}

.category-segment {
  display: flex;
  width: 360rpx;
  padding: 4rpx;
  border: 1rpx solid #e8ded2;
  border-radius: 18rpx;
  background: #faf7f1;
  box-sizing: border-box;
}

.category-tab {
  flex: 1;
  height: 64rpx;
  border-radius: 14rpx;
  color: #7a746b;
  font-size: 28rpx;
  font-weight: 600;
  line-height: 64rpx;
  text-align: center;
}

.category-tab.active {
  background: #fffdf8;
  color: #1f2933;
  box-shadow: 0 4rpx 12rpx rgba(31, 41, 51, 0.06);
}

.subtype-picker-wrap {
  margin-top: 12rpx;
  overflow: hidden;
  animation: picker-slide 180ms ease-out both;
}

.subtype-picker {
  display: flex;
  flex-wrap: wrap;
  gap: 12rpx;
  padding: 12rpx;
  border-radius: 20rpx;
  border: 1rpx solid #e8ded2;
  background: rgba(250, 247, 241, 0.72);
  box-sizing: border-box;
}

.subtype-option {
  min-width: 92rpx;
  height: 52rpx;
  padding: 0 20rpx;
  border-radius: 999rpx;
  border: 1rpx solid transparent;
  color: #7a746b;
  background: #fffdf8;
  font-size: 25rpx;
  font-weight: 700;
  line-height: 52rpx;
  text-align: center;
  box-sizing: border-box;
}

.subtype-option.active {
  border-color: rgba(154, 123, 55, 0.55);
  background: rgba(214, 168, 79, 0.16);
  color: #1f2933;
}

@keyframes picker-slide {
  from {
    opacity: 0;
    max-height: 0;
    transform: translateY(-8rpx);
  }
  to {
    opacity: 1;
    max-height: 160rpx;
    transform: translateY(0);
  }
}

.source-input {
  width: 100%;
  min-height: 54rpx;
  margin-top: 12rpx;
  padding: 0 4rpx;
  color: #4b5563;
  font-size: 28rpx;
  background: transparent;
  border-bottom: 1rpx solid #e8ded2;
  box-sizing: border-box;
}

.meta-row {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 16rpx;
  margin: 8rpx 0 0;
}

.meta-time {
  color: #9a948c;
  font-size: 22rpx;
  font-weight: 600;
}

.block-flow {
  display: flex;
  flex-direction: column;
  gap: 10rpx;
}

.bottom-spacer {
  height: 80rpx;
}

.dock-panel,
.tag-panel {
  position: fixed;
  left: 24rpx;
  right: 24rpx;
  bottom: 34rpx;
  z-index: 11;
  display: flex;
  align-items: center;
  gap: 14rpx;
  padding: 14rpx;
  border: 1rpx solid rgba(54, 48, 39, 0.12);
  border-radius: 22rpx;
  background: #fffdfa;
  box-shadow: 0 16rpx 34rpx rgba(55, 47, 35, 0.12);
  box-sizing: border-box;
}

.dock-input {
  flex: 1;
  height: 58rpx;
  padding: 0 18rpx;
  border-radius: 16rpx;
  border: 1rpx solid #dedacf;
  background: #f8f7f2;
  color: #1a2b48;
  font-size: 24rpx;
  box-sizing: border-box;
}

.dock-confirm {
  min-width: 76rpx;
  height: 58rpx;
  border-radius: 16rpx;
  background: #1a2b48;
  color: #c4a052;
  font-size: 22rpx;
  font-weight: 900;
  line-height: 58rpx;
  text-align: center;
}

.editor-tags {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10rpx;
  margin-top: 26rpx;
  padding-top: 20rpx;
  border-top: 1rpx solid rgba(232, 222, 210, 0.72);
}

.tag-pill {
  flex-shrink: 0;
  height: 42rpx;
  padding: 0 16rpx;
  border-radius: 14rpx;
  background: rgba(255, 248, 232, 0.98);
  border: 1rpx solid rgba(196, 160, 82, 0.42);
  color: #1a2b48;
  font-size: 19rpx;
  font-weight: 900;
  line-height: 42rpx;
}

.add-tag {
  height: 42rpx;
  color: #9a7b37;
}
</style>
