<!-- pages/me/skills.vue -->
<template>
  <view class="page">
    <view class="nav-bar">
      <text class="nav-back" @click="goBack">←</text>
      <text class="nav-title">个性化 / Skills</text>
    </view>

    <scroll-view scroll-y class="body">
      <text class="section-title">对话模式技能</text>
      <view class="card">
        <view
          v-for="skill in skills"
          :key="skill.id"
          class="skill-item"
        >
          <text class="skill-icon">{{ skill.icon }}</text>
          <view class="skill-info">
            <text class="skill-name">{{ skill.name }}</text>
            <text class="skill-desc">{{ skill.desc }}</text>
          </view>
          <view
            :class="['toggle', skill.enabled ? 'on' : 'off']"
            @click="toggleSkill(skill.id)"
          >
            <view class="toggle-knob" />
          </view>
        </view>
      </view>

      <text class="section-title">说明</text>
      <view class="card">
        <text class="help-text">
技能决定 Chat 页面显示哪些对话模式。关闭的技能不会出现在会话选择列表中。
        </text>
      </view>
    </scroll-view>
  </view>
</template>

<script>
export default {
  name: 'SkillsPage',
  data() {
    return {
      skills: [
        { id: 'memory', icon: '🧠', name: '记忆纠偏', desc: '发现误解与惯性记忆', enabled: true },
        { id: 'mentor', icon: '👤', name: '大师导师', desc: '苏格拉底式提问引导', enabled: false },
        { id: 'writing', icon: '✍', name: '创作辅助', desc: '基于碎片辅助写作输出', enabled: true },
        { id: 'report', icon: '📋', name: '生成报告', desc: '整理对话与碎片生成报告', enabled: true }
      ]
    }
  },
  methods: {
    toggleSkill(id) {
      const skill = this.skills.find((s) => s.id === id)
      if (skill) skill.enabled = !skill.enabled
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
}
.nav-bar {
  display: flex;
  align-items: center;
  gap: 16rpx;
  padding: 60rpx 32rpx 24rpx;
  background: #fff;
  border-bottom: 1rpx solid #f0f0f0;
}
.nav-back { font-size: 40rpx; color: #333; padding: 8rpx; }
.nav-title { font-size: 30rpx; font-weight: 600; color: #1a1a2e; }
.body { padding: 32rpx; }
.section-title {
  display: block;
  font-size: 26rpx;
  color: #888;
  margin-bottom: 12rpx;
  margin-top: 8rpx;
}
.card {
  background: #fff;
  border-radius: 20rpx;
  padding: 0;
  margin-bottom: 28rpx;
  box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06);
  overflow: hidden;
}
.skill-item {
  display: flex;
  align-items: center;
  gap: 20rpx;
  padding: 28rpx 32rpx;
  border-bottom: 1rpx solid #f0f0f0;
}
.skill-item:last-child { border-bottom: none; }
.skill-icon { font-size: 36rpx; }
.skill-info { flex: 1; }
.skill-name {
  display: block;
  font-size: 30rpx;
  font-weight: 500;
  color: #1a1a2e;
}
.skill-desc {
  display: block;
  font-size: 24rpx;
  color: #888;
  margin-top: 4rpx;
}
.toggle {
  width: 88rpx;
  height: 48rpx;
  border-radius: 24rpx;
  padding: 4rpx;
  transition: background 0.2s;
  box-sizing: border-box;
  display: flex;
  align-items: center;
}
.toggle.on { background: #004a77; justify-content: flex-end; }
.toggle.off { background: #ccc; justify-content: flex-start; }
.toggle-knob {
  width: 40rpx;
  height: 40rpx;
  border-radius: 20rpx;
  background: #fff;
}
.help-text {
  display: block;
  font-size: 26rpx;
  color: #666;
  line-height: 1.7;
  padding: 28rpx 32rpx;
}
</style>
