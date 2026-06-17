<!-- Spark_Vault_uniapp/src/pages/me/index.vue -->
<template>
  <scroll-view scroll-y class="sv-page">
    <view class="sv-header">
      <view>
        <text class="sv-kicker">ACCOUNT & SETTINGS</text>
        <text class="sv-title">我的 <text class="sv-title-mark">. Me</text></text>
      </view>
      <text class="sv-pill">PRO</text>
    </view>

    <view class="sv-navy-card identity-card">
      <view class="avatar-row">
        <view class="avatar">MMe</view>
        <view class="profile-copy">
          <view class="sv-row">
            <text class="profile-name">Spark Explorer</text>
            <text class="pro-badge">PRO</text>
          </view>
          <text class="profile-mail">lorindaW002@gmail.com</text>
        </view>
      </view>

      <view class="profile-stats">
        <view>
          <text class="profile-value">{{ fragmentsCount }}</text>
          <text class="profile-label">全部记录</text>
        </view>
        <view>
          <text class="profile-value">{{ reportsCount }}</text>
          <text class="profile-label">整理结果</text>
        </view>
        <view>
          <text class="profile-value">{{ activeSkillsCount }}</text>
          <text class="profile-label">可用功能</text>
        </view>
      </view>
    </view>

    <view class="sv-cream-card membership-card">
      <view class="sv-row">
        <text class="membership-icon">◆</text>
        <text class="membership-text">
          <text class="membership-strong">MirrorMe PRO：</text>
          已启用深度整理和 AI 对话能力。
        </text>
      </view>
      <text class="membership-arrow">详情</text>
    </view>

    <text class="sv-section">设置与功能</text>
    <view class="sv-card menu-card">
      <view class="menu-row" @click="goSkills">
        <view class="menu-icon">◇</view>
        <text class="menu-label">AI 对话角色管理</text>
        <view class="menu-right">
          <text class="count-badge">{{ activeSkillsCount }} 启用</text>
          <text class="menu-arrow">管理</text>
        </view>
      </view>
      <view class="divider" />
      <view class="menu-row" @click="resetData">
        <view class="menu-icon danger">×</view>
        <text class="menu-label">清除本地数据并恢复示例内容</text>
        <view class="menu-right">
          <text class="reset-badge">RESET</text>
          <text class="menu-arrow">重置</text>
        </view>
      </view>
      <view class="divider" />
      <view class="menu-row disabled">
        <view class="menu-icon muted">?</view>
        <text class="menu-label muted-text">隐私与使用说明</text>
        <text class="menu-arrow muted-text">说明</text>
      </view>
    </view>

    <button class="sv-secondary logout-button" @click="resetData">重置本地数据</button>

    <text class="footer-copy">
      MirrorMe. 一个安静的个人记录空间。
      版权所有 © 2026.
    </text>
  </scroll-view>
</template>

<script>
import { getVaultStore } from '../../store/vaultStore.js'
import { getEnabledMentors } from '../../services/skillsService.js'

export default {
  name: 'MePage',
  data() {
    return {
      fragmentsCount: 0,
      reportsCount: 0,
      activeSkillsCount: 0
    }
  },
  onShow() {
    this.loadData()
  },
  methods: {
    loadData() {
      const store = getVaultStore()
      store.refresh()
      this.fragmentsCount = store.state.fragments.length
      this.reportsCount = store.state.reports.length
      this.activeSkillsCount = getEnabledMentors().length
    },
    goSkills() {
      uni.navigateTo({ url: '/pages/me/skills' })
    },
    resetData() {
      uni.showModal({
        title: '重置本地数据',
        content: '确定要清除本地碎片、报告和会话缓存吗？',
        confirmText: '重置',
        confirmColor: '#b91c1c',
        success: (res) => {
          if (!res.confirm) return
          const store = getVaultStore()
          if (store?.state) {
            store.state.fragments = []
            store.state.reports = []
            store.state.sessions = []
          }
          try {
            uni.removeStorageSync('spark_vault_fragments')
            uni.removeStorageSync('spark_vault_reports')
            uni.removeStorageSync('spark_vault_sessions')
          } catch (error) {
            uni.showToast({ title: error?.message || '清理失败', icon: 'none' })
            return
          }
          this.loadData()
          uni.showToast({ title: '已重置', icon: 'success' })
        }
      })
    }
  }
}
</script>

<style scoped>
.identity-card {
  margin-bottom: 20rpx;
}

.avatar-row {
  display: flex;
  align-items: center;
  gap: 24rpx;
}

.avatar {
  width: 92rpx;
  height: 92rpx;
  border-radius: 999rpx;
  background: #c4a052;
  color: #1a2b48;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22rpx;
  font-weight: 900;
  font-style: italic;
}

.profile-copy {
  flex: 1;
  min-width: 0;
}

.profile-name {
  color: #f8f7f2;
  font-size: 28rpx;
  font-weight: 900;
}

.pro-badge {
  padding: 3rpx 12rpx;
  border-radius: 999rpx;
  background: rgba(196, 160, 82, 0.18);
  border: 1rpx solid rgba(196, 160, 82, 0.32);
  color: #c4a052;
  font-family: "Courier New", monospace;
  font-size: 15rpx;
  font-weight: 900;
}

.profile-mail {
  display: block;
  margin-top: 6rpx;
  color: rgba(248, 247, 242, 0.62);
  font-family: "Courier New", monospace;
  font-size: 18rpx;
  font-weight: 800;
}

.profile-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12rpx;
  margin-top: 28rpx;
  padding-top: 22rpx;
  border-top: 1rpx solid rgba(255, 255, 255, 0.08);
  text-align: center;
}

.profile-value {
  display: block;
  color: #c4a052;
  font-family: "Courier New", monospace;
  font-size: 28rpx;
  font-weight: 900;
}

.profile-label {
  display: block;
  margin-top: 5rpx;
  color: rgba(248, 247, 242, 0.52);
  font-family: "Courier New", monospace;
  font-size: 16rpx;
  font-weight: 900;
  letter-spacing: 1rpx;
}

.membership-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16rpx;
}

.membership-icon {
  color: #c4a052;
  font-size: 26rpx;
}

.membership-text {
  flex: 1;
  color: #1a2b48;
  font-size: 22rpx;
  line-height: 1.42;
}

.membership-strong {
  font-weight: 900;
}

.membership-arrow {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 72rpx;
  height: 44rpx;
  padding: 0 16rpx;
  border: 1rpx solid rgba(196, 160, 82, 0.34);
  border-radius: 999rpx;
  color: #1a2b48;
  background: #fffdf8;
  font-size: 21rpx;
  font-weight: 900;
  box-sizing: border-box;
}

.menu-card {
  padding: 0;
  overflow: hidden;
}

.menu-row {
  min-height: 92rpx;
  padding: 0 24rpx;
  display: flex;
  align-items: center;
  gap: 18rpx;
}

.menu-icon {
  width: 52rpx;
  height: 52rpx;
  border-radius: 15rpx;
  border: 1rpx solid #dedacf;
  background: #f8f7f2;
  color: #c4a052;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24rpx;
  font-weight: 900;
}

.menu-icon.danger {
  background: #fff1f2;
  border-color: #fecdd3;
  color: #b91c1c;
}

.menu-icon.muted {
  color: rgba(26, 26, 26, 0.35);
}

.menu-label {
  flex: 1;
  min-width: 0;
  color: #1a2b48;
  font-size: 23rpx;
  font-weight: 900;
}

.menu-right {
  display: flex;
  align-items: center;
  gap: 8rpx;
}

.count-badge,
.reset-badge {
  padding: 4rpx 12rpx;
  border-radius: 999rpx;
  font-family: "Courier New", monospace;
  font-size: 15rpx;
  font-weight: 900;
}

.count-badge {
  background: #f8f7f2;
  border: 1rpx solid #dedacf;
  color: #1a2b48;
}

.reset-badge {
  background: #fff1f2;
  border: 1rpx solid #fecdd3;
  color: #b91c1c;
}

.menu-arrow {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 72rpx;
  height: 44rpx;
  padding: 0 14rpx;
  border: 1rpx solid #dedacf;
  border-radius: 999rpx;
  color: #1a2b48;
  background: #f8f7f2;
  font-size: 20rpx;
  font-weight: 900;
  box-sizing: border-box;
}

.muted-text {
  color: rgba(26, 26, 26, 0.38);
}

.disabled {
  opacity: 0.8;
}

.divider {
  height: 1rpx;
  background: rgba(222, 218, 207, 0.6);
  margin-left: 94rpx;
}

.logout-button {
  margin-top: 28rpx;
}

.footer-copy {
  display: block;
  margin-top: 26rpx;
  color: rgba(26, 26, 26, 0.42);
  font-family: "Courier New", monospace;
  font-size: 17rpx;
  line-height: 1.45;
  text-align: center;
  font-weight: 800;
  letter-spacing: 1rpx;
}
</style>
