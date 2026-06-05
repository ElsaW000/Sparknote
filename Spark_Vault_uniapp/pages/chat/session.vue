<!-- pages/chat/session.vue — S1/S1b 全屏对话页 -->
<template>
  <view class="session-page">
    <!-- Nav bar -->
    <view class="nav-bar">
      <text class="nav-back" @click="handleBack">←</text>
      <view class="nav-center">
        <text class="nav-title">{{ navTitle }}</text>
        <text class="nav-sub" v-if="navSub">{{ navSub }}</text>
      </view>
      <text class="nav-more" @click="showMenu = !showMenu">⋯</text>
    </view>

    <!-- Menu overlay -->
    <view v-if="showMenu" class="menu-overlay" @click="showMenu = false">
      <view class="menu-box" @click.stop>
        <text class="menu-item" @click="newSession">＋ 新建会话</text>
        <text class="menu-item danger" @click="deleteSession">删除此会话</text>
      </view>
    </view>

    <!-- Messages area -->
    <scroll-view
      class="messages-area"
      scroll-y
      :scroll-top="scrollTop"
      @scrolltolower="scrollAtBottom = true"
    >
      <!-- Mentor selection (mentor mode, first open) -->
      <view v-if="isMentorMode && !selectedMentor" class="mentor-select-bubble">
        <view class="ai-bubble">
          <text class="bubble-text">请选择今天的对话导师：</text>
          <view class="mentor-grid">
            <view
              class="mentor-card"
              v-for="m in availableMentors"
              :key="m.id"
              @click="selectMentor(m)"
            >
              <text class="mentor-emoji">{{ m.emoji }}</text>
              <text class="mentor-name">{{ m.name }}</text>
              <text class="mentor-desc">{{ m.desc }}</text>
            </view>
          </view>
        </view>
      </view>

      <!-- Chat messages -->
      <view v-for="(msg, idx) in messages" :key="idx" :class="['msg-row', msg.role]">
        <view v-if="msg.role === 'assistant'" class="ai-bubble">
          <text class="bubble-text">{{ msg.content }}</text>
          <!-- Citation block -->
          <view v-if="msg.citations && msg.citations.length" class="citations-block">
            <view
              class="citations-header"
              @click="toggleCitations(idx)"
            >
              <text class="citations-icon">📎</text>
              <text class="citations-label">基于 {{ msg.citations.length }} 条你的记录</text>
              <text class="citations-toggle">{{ expandedCitations[idx] ? '收起' : '展开' }}</text>
            </view>
            <view v-if="expandedCitations[idx]" class="citations-list">
              <view
                class="citation-item"
                v-for="(c, ci) in msg.citations"
                :key="ci"
                @click="openFragment(c.id)"
              >
                <text class="citation-dot">·</text>
                <text class="citation-snippet">{{ c.snippet }}</text>
              </view>
            </view>
          </view>
        </view>
        <view v-else class="user-bubble">
          <text class="bubble-text">{{ msg.content }}</text>
        </view>
      </view>

      <!-- Save-as-report button (report mode only) -->
      <view v-if="mode === 'report' && pendingReport" class="save-report-bar">
        <view class="save-report-btn" @click="saveReport">
          <text class="save-report-text">📋 保存为报告</text>
        </view>
        <text class="save-report-hint">将 AI 生成的内容存入报告历史</text>
      </view>

      <!-- AI thinking indicator -->
      <view v-if="thinking" class="msg-row assistant">
        <view class="ai-bubble thinking">
          <text class="thinking-dots">···</text>
        </view>
      </view>

      <!-- Scroll anchor -->
      <view style="height: 20rpx;" />
    </scroll-view>

    <!-- Input area -->
    <view class="input-area">
      <textarea
        class="input-box"
        v-model="inputText"
        :placeholder="inputPlaceholder"
        :disabled="thinking || (isMentorMode && !selectedMentor)"
        :maxlength="1000"
        auto-height
        @focus="onFocus"
      />
      <view
        class="send-btn"
        :class="{ active: inputText.trim() && !thinking }"
        @click="sendMessage"
      >
        <text class="send-icon">↑</text>
      </view>
    </view>
  </view>
</template>

<script>
import { getVaultStore } from '@/store/vaultStore.js'
import { CHAT_MODES } from '@/services/vaultLogic.js'
import { agentChat, chatCompletion, buildSystemPrompt } from '@/services/aiService.js'
import { getEnabledMentors } from '@/services/skillsService.js'

const store = getVaultStore()

export default {
  data() {
    return {
      mode: 'memory',
      sessionId: null,
      selectedMentor: null,
      availableMentors: [],
      messages: [],
      inputText: '',
      thinking: false,
      scrollTop: 0,
      scrollAtBottom: true,
      showMenu: false,
      expandedCitations: {},
      pendingReport: null
    }
  },
  computed: {
    isMentorMode() {
      return this.mode === 'mentor'
    },
    modeInfo() {
      return CHAT_MODES.find((m) => m.id === this.mode) || CHAT_MODES[0]
    },
    navTitle() {
      if (this.selectedMentor) return this.selectedMentor.name
      return this.modeInfo.name
    },
    navSub() {
      if (this.selectedMentor) return `${this.modeInfo.name}模式`
      return null
    },
    inputPlaceholder() {
      if (this.isMentorMode && !this.selectedMentor) return '请先选择导师…'
      if (this.selectedMentor) return `回复${this.selectedMentor.name}…`
      return '输入你的想法…'
    }
  },
  onLoad(options) {
    this.availableMentors = getEnabledMentors()
    store.refresh()

    if (options.sessionId) {
      // Resume existing session
      const session = store.getSessionById(Number(options.sessionId))
      if (session) {
        this.sessionId = session.id
        this.mode = session.mode
        this.messages = session.messages || []
        // Restore mentor if stored in session
        if (session.mentorId) {
          this.selectedMentor = this.availableMentors.find((m) => m.id === session.mentorId) || null
        }
      }
    } else {
      // New session
      this.mode = options.mode || 'memory'
      this.createSession()
      // Auto-send greeting for non-mentor modes
      if (!this.isMentorMode) {
        this.$nextTick(() => this.sendGreeting())
      }
    }
  },
  methods: {
    createSession() {
      const result = store.saveSession({ mode: this.mode })
      if (result.ok) {
        this.sessionId = result.session.id
      }
    },
    selectMentor(mentor) {
      this.selectedMentor = mentor
      // Update session with mentor info
      if (this.sessionId) {
        store.updateSession(this.sessionId, {
          title: `${mentor.name} · 新会话`,
          mentorId: mentor.id
        })
      }
      // AI greeting from the selected mentor
      this.sendGreeting()
    },
    sendGreeting() {
      const greetings = {
        memory: '你好！我会帮你检视记录中可能存在的记忆偏差或认知误区。你有什么想聊的吗？',
        writing: '你好！我来帮你激发创意和整理思路。告诉我你正在思考的主题？',
        report: '好的，我将基于你的碎片和对话，为你生成一份成长报告。请告诉我你希望覆盖的时间范围和主题。'
      }

      let greeting = ''
      if (this.isMentorMode && this.selectedMentor) {
        greeting = `今天我们用「${this.selectedMentor.name}」视角来思考。${this.selectedMentor.desc}。你想探讨什么？`
      } else {
        greeting = greetings[this.mode] || '你好！有什么我可以帮到你的？'
      }

      this.messages.push({ role: 'assistant', content: greeting })
      this.saveMessages()
      this.scrollToBottom()
    },
    async sendMessage() {
      const text = this.inputText.trim()
      if (!text || this.thinking) return
      if (this.isMentorMode && !this.selectedMentor) return

      this.inputText = ''
      this.messages.push({ role: 'user', content: text })
      this.thinking = true
      this.scrollToBottom()

      try {
        // Build context: filter fragments by relevance to current message
        const allFragments = (store.state.fragments || []).filter(
          (f) => f.content_type === 'personal_content'
        )

        // Only send last 10 messages to stay within token limits
        const historyForAPI = this.messages
          .slice(-10)
          .filter((m) => m.role === 'user' || m.role === 'assistant')
          .map((m) => ({ role: m.role, content: m.content }))

        let reply
        if (this.mode === 'mentor' || this.mode === 'memory') {
          // Agent mode: backend does semantic retrieval via search_memory skill
          const mentorPrompt = buildSystemPrompt(this.mode, this.selectedMentor, [])
          reply = await agentChat(historyForAPI, mentorPrompt, allFragments)
        } else {
          // Simple mode for report/writing: put context in system prompt
          const systemPrompt = buildSystemPrompt(this.mode, this.selectedMentor, allFragments.slice(0, 10))
          reply = await chatCompletion(historyForAPI, systemPrompt)
        }

        // Find cited fragments: heuristic keyword overlap
        const citations = []
        const replyLower = reply.toLowerCase()
        for (const f of allFragments.slice(0, 30)) {
          const words = (f.content || '')
            .slice(0, 100)
            .split(/[，。！？\s、]+/)
            .filter((w) => w.length >= 3)
          const matched = words.some((w) => replyLower.includes(w.toLowerCase()))
          if (matched) {
            citations.push({
              id: f.id,
              snippet: (f.content || '').slice(0, 60) + ((f.content || '').length > 60 ? '…' : '')
            })
            if (citations.length >= 3) break
          }
        }

        this.messages.push({ role: 'assistant', content: reply, citations })

        // In report mode: cache the latest AI reply as pending report
        if (this.mode === 'report') {
          this.pendingReport = { content: reply, fragmentIds: citations.map((c) => c.id) }
        }
      } catch (err) {
        const errMsg = err.message || '请求失败，请检查网络连接或后端服务。'
        this.messages.push({
          role: 'assistant',
          content: `⚠️ ${errMsg}`
        })
      } finally {
        this.thinking = false
        this.saveMessages()
        this.scrollToBottom()
      }
    },
    saveMessages() {
      if (!this.sessionId) return
      const title = this.buildTitle()
      store.updateSession(this.sessionId, {
        messages: this.messages,
        title,
        mentorId: this.selectedMentor?.id || null
      })
    },
    buildTitle() {
      const firstUser = this.messages.find((m) => m.role === 'user')
      if (firstUser) {
        return `${this.navTitle} · ${firstUser.content.slice(0, 20)}`
      }
      return `${this.navTitle} · 新会话`
    },
    scrollToBottom() {
      this.$nextTick(() => {
        this.scrollTop = this.scrollTop + 99999
      })
    },
    onFocus() {
      setTimeout(() => this.scrollToBottom(), 300)
    },
    handleBack() {
      uni.navigateBack()
    },
    newSession() {
      this.showMenu = false
      uni.redirectTo({ url: `/pages/chat/session?mode=${this.mode}` })
    },
    toggleCitations(idx) {
      this.$set(this.expandedCitations, idx, !this.expandedCitations[idx])
    },
    openFragment(id) {
      uni.navigateTo({ url: `/pages/library/editor?id=${id}` })
    },
    saveReport() {
      if (!this.pendingReport) return
      const firstUserMsg = this.messages.find((m) => m.role === 'user')
      const title = firstUserMsg
        ? firstUserMsg.content.slice(0, 30)
        : `成长报告 ${new Date().toLocaleDateString('zh-CN')}`
      const result = store.saveReport({
        title,
        generatedContent: this.pendingReport.content,
        relatedFragmentIds: this.pendingReport.fragmentIds
      })
      if (result.ok) {
        this.pendingReport = null
        uni.showToast({ title: '报告已保存', icon: 'success', duration: 1500 })
        setTimeout(() => {
          uni.navigateTo({ url: '/pages/report/detail?id=' + result.report.id })
        }, 1600)
      } else {
        uni.showToast({ title: '保存失败', icon: 'none' })
      }
    },
    deleteSession() {
      this.showMenu = false
      uni.showModal({
        title: '删除会话',
        content: '此会话记录将被删除',
        confirmText: '删除',
        confirmColor: '#ba1a1a',
        success: (res) => {
          if (res.confirm && this.sessionId) {
            store.deleteSession(this.sessionId)
            uni.navigateBack()
          }
        }
      })
    }
  }
}
</script>

<style scoped>
.session-page { display: flex; flex-direction: column; height: 100vh; background: #f5f2ee; }

/* Nav */
.nav-bar { display: flex; align-items: center; justify-content: space-between; padding: 20rpx 28rpx; background: #ffffff; border-bottom: 2rpx solid #f0ece6; z-index: 10; }
.nav-back { font-size: 36rpx; color: #1c1b1f; padding: 8rpx 8rpx 8rpx 0; }
.nav-center { flex: 1; text-align: center; }
.nav-title { display: block; font-size: 30rpx; font-weight: 700; color: #1c1b1f; }
.nav-sub { display: block; font-size: 22rpx; color: #49454f; }
.nav-more { font-size: 32rpx; color: #49454f; padding: 8rpx; }

/* Menu */
.menu-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; z-index: 100; }
.menu-box { position: absolute; top: 110rpx; right: 28rpx; background: #ffffff; border-radius: 20rpx; padding: 8rpx 0; box-shadow: 0 8rpx 40rpx rgba(0,0,0,0.15); min-width: 240rpx; }
.menu-item { display: block; padding: 22rpx 28rpx; font-size: 28rpx; color: #1c1b1f; }
.menu-item.danger { color: #ba1a1a; }

/* Messages */
.messages-area { flex: 1; padding: 20rpx 24rpx; }
.msg-row { margin-bottom: 24rpx; }
.msg-row.user { display: flex; justify-content: flex-end; }
.msg-row.assistant { display: flex; justify-content: flex-start; }

.ai-bubble { background: #ffffff; border-radius: 24rpx 24rpx 24rpx 8rpx; padding: 20rpx 24rpx; max-width: 86%; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06); }
.user-bubble { background: #004a77; border-radius: 24rpx 24rpx 8rpx 24rpx; padding: 20rpx 24rpx; max-width: 86%; }
.user-bubble .bubble-text { color: #ffffff; }
.bubble-text { font-size: 28rpx; line-height: 1.7; color: #1c1b1f; display: block; white-space: pre-wrap; }
/* Save-report bar */
.save-report-bar { display: flex; align-items: center; gap: 16rpx; padding: 16rpx 24rpx; background: #e8f0f8; border-top: 2rpx solid #c0d8ef; flex-shrink: 0; }
.save-report-btn { background: #004a77; border-radius: 20rpx; padding: 12rpx 28rpx; flex-shrink: 0; }
.save-report-text { font-size: 26rpx; color: #fff; font-weight: 600; }
.save-report-hint { font-size: 22rpx; color: #49454f; flex: 1; }

/* Citations */
.citations-block { margin-top: 14rpx; border-top: 1rpx solid #f0ece6; padding-top: 12rpx; }
.citations-header { display: flex; align-items: center; gap: 8rpx; }
.citations-icon { font-size: 22rpx; }
.citations-label { flex: 1; font-size: 22rpx; color: #49454f; }
.citations-toggle { font-size: 20rpx; color: #004a77; }
.citations-list { margin-top: 10rpx; display: flex; flex-direction: column; gap: 8rpx; }
.citation-item { display: flex; align-items: flex-start; gap: 8rpx; background: #f5f2ee; border-radius: 10rpx; padding: 10rpx 12rpx; }
.citation-dot { font-size: 24rpx; color: #004a77; flex-shrink: 0; line-height: 1.5; }
.citation-snippet { font-size: 22rpx; color: #49454f; line-height: 1.55; }

/* Mentor selection */
.mentor-select-bubble { margin-bottom: 24rpx; }
.mentor-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14rpx; margin-top: 16rpx; }
.mentor-card { background: #f5f2ee; border-radius: 20rpx; padding: 20rpx 16rpx; text-align: center; }
.mentor-emoji { display: block; font-size: 44rpx; margin-bottom: 8rpx; }
.mentor-name { display: block; font-size: 26rpx; font-weight: 700; color: #1c1b1f; }
.mentor-desc { display: block; font-size: 20rpx; color: #49454f; margin-top: 4rpx; }

/* Thinking */
.thinking .thinking-dots { font-size: 36rpx; color: #49454f; letter-spacing: 4rpx; }

/* Input */
.input-area { display: flex; align-items: flex-end; gap: 14rpx; padding: 14rpx 24rpx 28rpx; background: #ffffff; border-top: 2rpx solid #f0ece6; }
.input-box { flex: 1; font-size: 28rpx; color: #1c1b1f; background: #f5f2ee; border-radius: 20rpx; padding: 14rpx 20rpx; min-height: 72rpx; max-height: 240rpx; line-height: 1.55; }
.send-btn { width: 72rpx; height: 72rpx; border-radius: 36rpx; background: #e8e4de; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.send-btn.active { background: #004a77; }
.send-icon { font-size: 30rpx; color: #ffffff; }
</style>
