<!-- pages/chat/session.vue -->
<template>
  <view class="page">
    <!-- Nav Bar -->
    <view class="nav-bar">
      <text class="nav-back" @click="goBack">←</text>
      <view class="nav-center">
        <text class="nav-title">{{ session.title }}</text>
        <text class="nav-sub">{{ modeName }} · 基于 {{ fragmentCount }} 条个人记录</text>
      </view>
      <text class="nav-more">⋯</text>
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
      >↑</button>
    </view>
  </view>
</template>

<script>
import { getVaultStore } from '../../store/vaultStore.js'
import { CHAT_MODES } from '../../services/vaultLogic.js'

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

      // Simulate AI response (TODO: replace with actual API call)
      await this.simulateAIResponse(text)

      this.isLoading = false
      this.persistSession()
      this.scrollToBottom()
    },
    async simulateAIResponse(userText) {
      await new Promise((r) => setTimeout(r, 800))
      const responses = {
        memory: `这是一个有趣的想法。你提到"${userText.slice(0, 20)}"——我想问，这个观点是什么时候形成的？它是否曾经被事实验证过？`,
        mentor: `从第一性原理出发，你的这个观点值得深入探讨。你是否考虑过，如果把最基本的假设去掉，这个结论还成立吗？`,
        writing: `基于你的记录，我帮你整理了相关素材。你提到的核心论点可以展开为：首先...`,
        report: `我注意到你的记录中有几个反复出现的主题：首先是关于"${userText.slice(0, 15)}"的思考...`
      }
      const content = responses[this.session.mode] || '我理解你的意思。让我们继续深入探讨这个问题。'
      this.session.messages.push({ role: 'assistant', content })
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
  font-size: 40rpx;
  color: #333;
  padding: 8rpx;
}
.nav-center { flex: 1; }
.nav-title {
  display: block;
  font-size: 30rpx;
  font-weight: 600;
  color: #1a1a2e;
}
.nav-sub {
  display: block;
  font-size: 22rpx;
  color: #aaa;
  margin-top: 2rpx;
}
.nav-more {
  font-size: 32rpx;
  color: #888;
  padding: 8rpx;
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
  width: 72rpx;
  height: 72rpx;
  border-radius: 36rpx;
  background: #004a77;
  color: #fff;
  font-size: 32rpx;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  padding: 0;
}
.send-btn[disabled] { opacity: 0.4; }
</style>
