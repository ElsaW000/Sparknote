<!-- pages/me/index.vue -->
<template>
  <view class="page">
    <!-- Header -->
    <view class="header">
      <text class="title">Me</text>
    </view>

    <!-- User Card -->
    <view class="card user-card" @click="goProfile">
      <view class="avatar">{{ avatarInitial }}</view>
      <view class="user-info">
        <text class="user-name">{{ userName }}</text>
        <text class="user-plan">{{ userPlan }}</text>
      </view>
      <text class="arrow">›</text>
    </view>

    <!-- Upgrade Banner -->
    <view class="card upgrade-row" @click="goUpgrade">
      <text class="upgrade-icon">⭐</text>
      <text class="upgrade-text">升级套餐</text>
      <text class="arrow">›</text>
    </view>

    <!-- Group 1: Settings -->
    <view class="card menu-group">
      <view class="menu-item" @click="goSkills">
        <text class="menu-icon">🎨</text>
        <text class="menu-label">个性化 / Skills</text>
        <text class="arrow">›</text>
      </view>
      <view class="divider" />
      <view class="menu-item" @click="goProfile">
        <text class="menu-icon">👤</text>
        <text class="menu-label">个人资料</text>
        <text class="arrow">›</text>
      </view>
      <view class="divider" />
      <view class="menu-item" @click="goSettings">
        <text class="menu-icon">⚙️</text>
        <text class="menu-label">设置</text>
        <text class="arrow">›</text>
      </view>
    </view>

    <!-- Group 2: Info -->
    <view class="card menu-group">
      <view class="menu-item" @click="goHelp">
        <text class="menu-icon">❓</text>
        <text class="menu-label">帮助与反馈</text>
        <text class="arrow">›</text>
      </view>
      <view class="divider" />
      <view class="menu-item" @click="goPolicy">
        <text class="menu-icon">📄</text>
        <text class="menu-label">用户协议 / 隐私政策</text>
        <text class="arrow">›</text>
      </view>
      <view class="divider" />
      <view class="menu-item" @click="goAbout">
        <text class="menu-icon">ℹ️</text>
        <text class="menu-label">关于 Spark Vault</text>
        <text class="arrow">›</text>
      </view>
    </view>

    <!-- Logout -->
    <view class="card logout-row" @click="confirmLogout">
      <text class="logout-icon">🚪</text>
      <text class="logout-text">退出登录</text>
    </view>

    <!-- Version -->
    <text class="version">Spark Vault · v0.1.0</text>
  </view>
</template>

<script>
export default {
  name: 'MePage',
  data() {
    return {
      userName: 'Jie Wang',
      userPlan: 'Plus · 有效期至 2026-12'
    }
  },
  computed: {
    avatarInitial() {
      return this.userName ? this.userName.charAt(0).toUpperCase() : 'U'
    }
  },
  methods: {
    goSkills() {
      uni.navigateTo({ url: '/pages/me/skills' })
    },
    goProfile() {
      uni.showToast({ title: '个人资料 (即将开放)', icon: 'none' })
    },
    goSettings() {
      uni.showToast({ title: '设置 (即将开放)', icon: 'none' })
    },
    goUpgrade() {
      uni.showToast({ title: '套餐升级 (即将开放)', icon: 'none' })
    },
    goHelp() {
      uni.showToast({ title: '帮助与反馈 (即将开放)', icon: 'none' })
    },
    goPolicy() {
      uni.showToast({ title: '用户协议 (即将开放)', icon: 'none' })
    },
    goAbout() {
      uni.showToast({ title: 'Spark Vault v0.1.0', icon: 'none' })
    },
    confirmLogout() {
      uni.showModal({
        title: '退出登录',
        content: '确定要退出登录吗？',
        confirmText: '退出',
        confirmColor: '#d9534f',
        success: (res) => {
          if (res.confirm) {
            uni.showToast({ title: '已退出', icon: 'none' })
            // TODO: clear auth state and redirect to login
          }
        }
      })
    }
  }
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  background: #fbf9f6;
  padding: 48rpx 32rpx 120rpx;
  box-sizing: border-box;
}
.header {
  margin-bottom: 32rpx;
  padding-top: 20rpx;
}
.title {
  display: block;
  font-size: 52rpx;
  font-weight: 700;
  color: #1a1a2e;
}
.card {
  background: #fff;
  border-radius: 20rpx;
  padding: 32rpx;
  margin-bottom: 20rpx;
  box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06);
}
.user-card {
  display: flex;
  align-items: center;
  gap: 24rpx;
}
.avatar {
  width: 80rpx;
  height: 80rpx;
  border-radius: 40rpx;
  background: #004a77;
  color: #fff;
  font-size: 36rpx;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.user-info { flex: 1; }
.user-name {
  display: block;
  font-size: 32rpx;
  font-weight: 600;
  color: #1a1a2e;
}
.user-plan {
  display: block;
  font-size: 24rpx;
  color: #888;
  margin-top: 4rpx;
}
.arrow {
  font-size: 32rpx;
  color: #ccc;
}
.upgrade-row {
  display: flex;
  align-items: center;
  gap: 16rpx;
}
.upgrade-icon { font-size: 36rpx; }
.upgrade-text {
  flex: 1;
  font-size: 30rpx;
  font-weight: 500;
  color: #1a1a2e;
}
.menu-group {
  padding: 0;
  overflow: hidden;
}
.menu-item {
  display: flex;
  align-items: center;
  gap: 20rpx;
  padding: 28rpx 32rpx;
}
.menu-icon { font-size: 36rpx; }
.menu-label {
  flex: 1;
  font-size: 30rpx;
  color: #1a1a2e;
}
.divider {
  height: 1rpx;
  background: #f0f0f0;
  margin-left: 80rpx;
}
.logout-row {
  display: flex;
  align-items: center;
  gap: 16rpx;
  background: #fff5f5;
}
.logout-icon { font-size: 36rpx; }
.logout-text {
  font-size: 30rpx;
  color: #d9534f;
  font-weight: 500;
}
.version {
  display: block;
  text-align: center;
  font-size: 22rpx;
  color: #ccc;
  margin-top: 16rpx;
}
</style>
