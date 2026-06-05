<!-- pages/me/index.vue — Me Tab：个人设置 -->
<template>
  <scroll-view class="page" scroll-y>
    <!-- User card -->
    <view class="user-card">
      <view class="avatar">J</view>
      <view class="user-info">
        <text class="user-name">Spark Vault 用户</text>
        <text class="user-plan">免费版</text>
      </view>
      <text class="user-arrow">›</text>
    </view>

    <!-- Upgrade banner -->
    <view class="upgrade-banner">
      <text class="upgrade-icon">⭐</text>
      <view class="upgrade-text">
        <text class="upgrade-title">升级到 Pro</text>
        <text class="upgrade-sub">无限 AI 对话 · 全部报告类型 · 自定义 Skills</text>
      </view>
      <text class="upgrade-price">¥29/月</text>
    </view>

    <!-- Settings group 1 -->
    <view class="group">
      <view class="group-row" @click="navigate('/pages/me/skills')">
        <text class="row-icon">🎨</text>
        <text class="row-label">个性化 / Skills</text>
        <text class="row-arrow">›</text>
      </view>
      <view class="group-row" @click="showToast('个人资料')">
        <text class="row-icon">👤</text>
        <text class="row-label">个人资料</text>
        <text class="row-arrow">›</text>
      </view>
      <view class="group-row" @click="showToast('通知设置')">
        <text class="row-icon">⚙️</text>
        <text class="row-label">设置</text>
        <text class="row-arrow">›</text>
      </view>
    </view>

    <!-- Settings group 2 -->
    <view class="group">
      <view class="group-row" @click="showToast('帮助与反馈')">
        <text class="row-icon">❓</text>
        <text class="row-label">帮助与反馈</text>
        <text class="row-arrow">›</text>
      </view>
      <view class="group-row" @click="showToast('用户协议 / 隐私政策')">
        <text class="row-icon">📄</text>
        <text class="row-label">用户协议 / 隐私政策</text>
        <text class="row-arrow">›</text>
      </view>
      <view class="group-row" @click="showAbout">
        <text class="row-icon">ℹ️</text>
        <text class="row-label">关于 Spark Vault</text>
        <text class="row-arrow">›</text>
      </view>
    </view>

    <!-- Storage stats -->
    <view class="stats-card">
      <text class="stats-title">本地数据</text>
      <view class="stats-row">
        <text class="stats-label">碎片总数</text>
        <text class="stats-val">{{ metrics.totalFragments }}</text>
      </view>
      <view class="stats-row">
        <text class="stats-label">会话记录</text>
        <text class="stats-val">{{ metrics.chatCount }}</text>
      </view>
      <view class="stats-row">
        <text class="stats-label">报告数</text>
        <text class="stats-val">{{ metrics.reportCount }}</text>
      </view>
      <text class="stats-hint">数据保存在本机，清除缓存将丢失所有内容</text>
    </view>

    <!-- Logout (placeholder) -->
    <view class="logout-row" @click="handleLogout">
      <text class="logout-text">🚪 退出登录</text>
    </view>

    <view style="height: 60rpx;" />
  </scroll-view>
</template>

<script>
import { getVaultStore } from '@/store/vaultStore.js'

const store = getVaultStore()

export default {
  data() {
    return {
      metrics: { totalFragments: 0, chatCount: 0, reportCount: 0 }
    }
  },
  onShow() {
    store.refresh()
    this.metrics = { ...store.state.metrics }
  },
  methods: {
    navigate(url) {
      uni.navigateTo({ url })
    },
    showToast(label) {
      uni.showToast({ title: `${label}（开发中）`, icon: 'none', duration: 1500 })
    },
    showAbout() {
      uni.showModal({
        title: 'Spark Vault',
        content: '版本 1.0 MVP\n个人成长反思工具\n\n记录 → 沉淀 → 洞见 → 成长',
        showCancel: false,
        confirmText: '好的'
      })
    },
    handleLogout() {
      uni.showModal({
        title: '退出登录',
        content: '当前为本地模式，退出不会清除数据',
        confirmText: '退出',
        cancelText: '取消',
        success(res) {
          if (res.confirm) {
            uni.showToast({ title: '云端账号功能开发中', icon: 'none' })
          }
        }
      })
    }
  }
}
</script>

<style scoped>
.page { background: #fbf9f6; padding: 24rpx; }

/* User card */
.user-card { display: flex; align-items: center; gap: 20rpx; background: #ffffff; border-radius: 24rpx; padding: 24rpx 28rpx; margin-bottom: 20rpx; }
.avatar { width: 80rpx; height: 80rpx; border-radius: 40rpx; background: #004a77; color: #ffffff; font-size: 36rpx; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.user-info { flex: 1; }
.user-name { display: block; font-size: 32rpx; font-weight: 700; color: #1c1b1f; }
.user-plan { display: block; font-size: 24rpx; color: #49454f; margin-top: 4rpx; }
.user-arrow { font-size: 30rpx; color: #a39e97; }

/* Upgrade banner */
.upgrade-banner { display: flex; align-items: center; gap: 16rpx; background: linear-gradient(135deg, #004a77, #0066a8); border-radius: 24rpx; padding: 24rpx 28rpx; margin-bottom: 24rpx; }
.upgrade-icon { font-size: 40rpx; }
.upgrade-text { flex: 1; }
.upgrade-title { display: block; font-size: 30rpx; font-weight: 700; color: #ffffff; }
.upgrade-sub { display: block; font-size: 22rpx; color: rgba(255,255,255,0.8); margin-top: 4rpx; }
.upgrade-price { font-size: 28rpx; font-weight: 700; color: #ffffff; white-space: nowrap; }

/* Groups */
.group { background: #ffffff; border-radius: 24rpx; margin-bottom: 20rpx; overflow: hidden; }
.group-row { display: flex; align-items: center; gap: 20rpx; padding: 24rpx 28rpx; border-bottom: 2rpx solid #f5f2ee; }
.group-row:last-child { border-bottom: none; }
.row-icon { font-size: 32rpx; width: 40rpx; }
.row-label { flex: 1; font-size: 28rpx; color: #1c1b1f; }
.row-arrow { font-size: 28rpx; color: #a39e97; }

/* Stats */
.stats-card { background: #ffffff; border-radius: 24rpx; padding: 24rpx 28rpx; margin-bottom: 20rpx; }
.stats-title { display: block; font-size: 26rpx; font-weight: 700; color: #49454f; margin-bottom: 16rpx; }
.stats-row { display: flex; justify-content: space-between; margin-bottom: 12rpx; }
.stats-label { font-size: 26rpx; color: #49454f; }
.stats-val { font-size: 26rpx; font-weight: 700; color: #1c1b1f; }
.stats-hint { display: block; font-size: 22rpx; color: #a39e97; margin-top: 12rpx; }

/* Logout */
.logout-row { text-align: center; padding: 24rpx; }
.logout-text { font-size: 28rpx; color: #ba1a1a; }
</style>
