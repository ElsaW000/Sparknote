<!-- Spark_Vault_uniapp/src/components/editor/AudioBlock.vue -->
<template>
  <view class="audio-card" @click="$emit('select')">
    <view class="play-dot">{{ block.recording ? '●' : '▶' }}</view>
    <view class="audio-main">
      <view class="audio-head">
        <text class="audio-title">{{ block.recording ? '正在录音' : '录音' }}</text>
        <text
          class="record-control"
          @click.stop="$emit('audio-action', { id: block.id, action: block.recording ? 'stop' : 'start' })"
        >
          {{ block.recording ? '停止' : '开始录音' }}
        </text>
      </view>
      <view class="track">
        <view :class="['track-fill', block.recording ? 'active' : '']" />
      </view>
      <view class="audio-meta">
        <text class="duration">{{ block.duration || '00:00' }}</text>
        <text class="status">{{ block.transcribeStatus || '等待转录' }}</text>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  name: 'AudioBlock',
  props: {
    block: {
      type: Object,
      required: true
    }
  },
  emits: ['select', 'update', 'audio-action']
}
</script>

<style scoped>
.audio-card {
  display: flex;
  align-items: center;
  gap: 18rpx;
  margin: 0;
  padding: 18rpx;
  border-radius: 24rpx;
  background: #faf7f1;
  border: 1rpx solid #e8ded2;
  box-shadow: 0 8rpx 24rpx rgba(31, 41, 51, 0.06);
  box-sizing: border-box;
  transition: all 300ms ease-in-out;
  transform-origin: center;
  will-change: transform, box-shadow;
}

.audio-card:hover,
.audio-card:active {
  transform: scale(1.05);
  box-shadow: 0 24rpx 56rpx rgba(31, 41, 51, 0.16);
}

.play-dot {
  width: 58rpx;
  height: 58rpx;
  border-radius: 50%;
  background: #f6f2ec;
  border: 1rpx solid #e8ded2;
  color: #9a7b37;
  font-size: 22rpx;
  line-height: 58rpx;
  text-align: center;
  flex-shrink: 0;
}

.audio-main {
  flex: 1;
  min-width: 0;
}

.audio-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16rpx;
  margin-bottom: 12rpx;
}

.audio-title {
  color: #1f2933;
  font-size: 28rpx;
  font-weight: 700;
}

.record-control {
  flex-shrink: 0;
  min-height: 44rpx;
  padding: 0 16rpx;
  border-radius: 999rpx;
  background: rgba(214, 168, 79, 0.10);
  border: 1rpx solid rgba(214, 168, 79, 0.32);
  color: #8a5e13;
  font-size: 22rpx;
  font-weight: 700;
  line-height: 44rpx;
}

.track {
  height: 8rpx;
  overflow: hidden;
  border-radius: 999rpx;
  background: #e8ded2;
}

.track-fill {
  width: 38%;
  height: 100%;
  border-radius: 999rpx;
  background: #9a7b37;
  transition: width 300ms ease-in-out;
}

.track-fill.active {
  width: 68%;
}

.audio-meta {
  display: flex;
  justify-content: space-between;
  gap: 16rpx;
  margin-top: 10rpx;
}

.duration,
.status {
  color: #6b7280;
  font-size: 22rpx;
  font-weight: 600;
  white-space: nowrap;
}
</style>
