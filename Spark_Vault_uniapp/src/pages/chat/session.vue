<!-- pages/chat/session.vue -->
<template>
  <view class="page">
    <!-- Nav Bar -->
    <view class="nav-bar">
      <text class="nav-back" @click="goBack">返回</text>
      <view class="nav-center">
        <text class="nav-title">{{ session.title }}</text>
        <text class="nav-sub">{{ modeName }} · 基于 {{ fragmentCount }} 条个人记录</text>
      </view>
      <text class="nav-more">更多</text>
    </view>

    <!-- Messages -->
    <scroll-view scroll-y class="messages" :scroll-top="scrollTop" scroll-with-animation>
      <view v-for="(msg, idx) in messages" :key="idx" :class="['msg-row', msg.role]">
        <view v-if="msg.role === 'assistant'" class="msg-avatar">{{ modeIcon }}</view>
        <view class="bubble">
          <text class="bubble-text">{{ msg.content }}</text>
          <text v-if="msg.citation" class="citation">引用你的记录：「{{ msg.citation }}」</text>
        </view>
      </view>

      <!-- Loading indicator -->
      <view v-if="isLoading" class="msg-row assistant">
        <view class="msg-avatar">{{ modeIcon }}</view>
        <view class="bubble loading-bubble">
          <text class="loading-dots">···</text>
        </view>
      </view>

      <view style="height: 160rpx;" />
    </scroll-view>

    <!-- Input Bar -->
    <view class="input-bar">
      <textarea
        class="input-text"
        v-model="inputText"
        :placeholder="inputPlaceholder"
        :maxlength="2000"
        :auto-height="true"
        :disabled="isLoading"
      />
      <button
        class="send-btn"
        :disabled="!inputText.trim() || isLoading"
        @click="sendMessage"
      >发送</button>
    </view>
  </view>
</template>

<script>
import { getVaultStore } from '../../store/vaultStore.js'
import { CHAT_MODES } from '../../services/vaultLogic.js'
import { selectRelevantFragments } from '../../services/aiService.js'

export default {
  name: 'ChatSession',
  data() {
    return {
      sessionId: null,
      session: { title: '新会话', mode: 'memory', messages: [] },
      inputText: '',
      isLoading: false,
      scrollTop: 0
    }
  },
  computed: {
    messages() { return this.session.messages || [] },
    modeInfo() { return CHAT_MODES.find((m) => m.id === this.session.mode) || CHAT_MODES[0] },
    modeName() { return this.modeInfo.name },
    modeIcon() { return this.modeInfo.icon },
    fragmentCount() {
      const store = getVaultStore()
      return store.state.fragments.filter((f) => f.content_type === 'personal_content').length
    },
    inputPlaceholder() {
      return `回复 ${this.modeName}…`
    }
  },
  onLoad(options) {
    if (options.id) {
      this.sessionId = Number(options.id)
      this.loadSession()
    }
  },
  methods: {
    loadSession() {
      const store = getVaultStore()
      const s = store.getSessionById(this.sessionId)
      if (s) {
        this.session = { ...s }
        // If new session with no messages, add initial greeting
        if (!s.messages || s.messages.length === 0) {
          this.addInitialMessage()
        }
      }
    },
    addInitialMessage() {
      const greetings = {
        memory: '你好！我会帮助你发现记录中的惯性思维。先告诉我，最近有什么想法让你反复思考？',
        mentor: '你好！请告诉我你想探讨什么问题？我会从不同视角和你深入讨论。',
        writing: '你好！我会基于你的 Library 碎片帮助你写作。你想创作什么内容？',
        report: '你好！我会帮你整理对话和碎片，生成结构化报告。告诉我这份报告的主题？'
      }
      const msg = {
        role: 'assistant',
        content: greetings[this.session.mode] || '你好！我在这里，请开始吧。'
      }
      this.session.messages = [msg]
      this.persistSession()
    },
    async sendMessage() {
      const text = this.inputText.trim()
      if (!text || this.isLoading) return

      this.inputText = ''
      this.isLoading = true

      // Add user message
      this.session.messages.push({ role: 'user', content: text })
      this.scrollToBottom()

      await this.generateLocalResponse(text)

      this.isLoading = false
      this.persistSession()
      this.scrollToBottom()
    },
    async generateLocalResponse(userText) {
      await new Promise((r) => setTimeout(r, 300))
      const store = getVaultStore()
      store.refresh()
      const fragments = store.state.fragments.filter((f) => f.content_type === 'personal_content')
      const relevant = selectRelevantFragments(fragments, userText, 3)
      const contextLine = relevant.length
        ? `我找到 ${relevant.length} 条相关记录：${relevant.map((f) => `「${(f.title || f.content || f.originalText || '').slice(0, 18)}」`).join('、')}。`
        : '我还没有找到直接相关的本地记录，所以先基于你刚才的话回应。'
      const prompt = userText.slice(0, 36)
      const responses = {
        memory: `${contextLine}\n\n你提到「${prompt}」。先检查一个可能的盲点：这是一个事实判断、情绪反应，还是长期形成的默认解释？建议你补一条记录：这件事第一次让你产生类似感受是在什么时候。`,
        mentor: `${contextLine}\n\n如果用更严格的思考框架看「${prompt}」，可以先拆成三个问题：你真正想解决什么、你默认了哪些前提、最小的验证动作是什么。`,
        writing: `${contextLine}\n\n这段内容可以先写成一个小提纲：核心观点、触发场景、一个例子、一个反问。先不要追求完整文章，把最有力量的一句话写清楚。`,
        report: `${contextLine}\n\n这可以进入一份复盘报告：主题是「${prompt || '近期思考'}」，可记录为现象、重复模式、可能原因、下一步行动四段。`
      }
      this.session.messages.push({
        role: 'assistant',
        content: responses[this.session.mode] || `${contextLine}\n\n我理解你的意思。我们可以继续把这个问题拆细。`,
        citation: relevant[0]?.content || relevant[0]?.originalText || ''
      })
    },
    persistSession() {
      const store = getVaultStore()
      store.updateSession(this.sessionId, {
        messages: this.session.messages,
        title: this.session.title,
        updated_at: Date.now()
      })
    },
    scrollToBottom() {
      this.$nextTick(() => {
        this.scrollTop = 99999
      })
    },
    goBack() {
      uni.navigateBack()
    }
  }
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  background: #fbf9f6;
  display: flex;
  flex-direction: column;
}
.nav-bar {
  display: flex;
  align-items: center;
  gap: 16rpx;
  padding: 60rpx 32rpx 20rpx;
  background: #fff;
  border-bottom: 1rpx solid #f0f0f0;
}
.nav-back {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 84rpx;
  height: 52rpx;
  padding: 0 18rpx;
  border: 1rpx solid #dedacf;
  border-radius: 999rpx;
  background: #f8f7f2;
  color: #1a2b48;
  font-size: 24rpx;
  font-weight: 800;
  box-sizing: border-box;
}
.nav-center { flex: 1; }
.nav-title {
  display: block;
  font-size: 34rpx;
  font-weight: 800;
  color: #1a1a2e;
}
.nav-sub {
  display: block;
  font-size: 22rpx;
  color: #aaa;
  margin-top: 2rpx;
}
.nav-more {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 84rpx;
  height: 52rpx;
  padding: 0 18rpx;
  border: 1rpx solid #dedacf;
  border-radius: 999rpx;
  background: #fff;
  color: #1a2b48;
  font-size: 24rpx;
  font-weight: 800;
  box-sizing: border-box;
}
.messages {
  flex: 1;
  padding: 24rpx 24rpx 0;
}
.msg-row {
  display: flex;
  align-items: flex-start;
  gap: 16rpx;
  margin-bottom: 24rpx;
}
.msg-row.user {
  flex-direction: row-reverse;
}
.msg-avatar {
  width: 64rpx;
  height: 64rpx;
  border-radius: 32rpx;
  background: #eaf4ff;
  font-size: 32rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.bubble {
  max-width: 72%;
  background: #fff;
  border-radius: 20rpx;
  padding: 24rpx;
  box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.06);
}
.msg-row.user .bubble {
  background: #004a77;
}
.bubble-text {
  display: block;
  font-size: 28rpx;
  color: #1a1a2e;
  line-height: 1.7;
}
.msg-row.user .bubble-text { color: #fff; }
.citation {
  display: block;
  font-size: 22rpx;
  color: #888;
  margin-top: 12rpx;
  border-left: 3rpx solid #ccc;
  padding-left: 12rpx;
}
.loading-bubble { background: #f0f0f0; }
.loading-dots {
  font-size: 32rpx;
  color: #888;
  letter-spacing: 4rpx;
}
.input-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  align-items: flex-end;
  gap: 16rpx;
  padding: 16rpx 24rpx 40rpx;
  background: #fff;
  border-top: 1rpx solid #f0f0f0;
  box-sizing: border-box;
}
.input-text {
  flex: 1;
  background: #f5f5f5;
  border-radius: 20rpx;
  padding: 16rpx 24rpx;
  font-size: 28rpx;
  min-height: 72rpx;
  max-height: 200rpx;
  border: none;
  box-sizing: border-box;
}
.send-btn {
  min-width: 96rpx;
  height: 72rpx;
  border-radius: 999rpx;
  background: #004a77;
  color: #fff;
  font-size: 26rpx;
  font-weight: 800;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  padding: 0;
}
.send-btn[disabled] { opacity: 0.4; }
</style>
